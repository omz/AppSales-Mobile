//Adds compression and decompression messages to NSData. 
//Methods extracted from source given at http://www.cocoadev.com/index.pl?NSDataCategory

#import "NSData+Compression.h"
#include <zlib.h>


@implementation NSData (Compression)

- (NSData *)zlibInflate {
	if ([self length] == 0) return self;
	
	unsigned full_length = (unsigned)[self length];
	unsigned half_length = (unsigned)[self length] / 2;
	
	NSMutableData *decompressed = [NSMutableData dataWithLength: full_length + half_length];
	BOOL done = NO;
	int status;
	
	z_stream strm;
	strm.next_in = (Bytef *)[self bytes];
	strm.avail_in = (unsigned)[self length];
	strm.total_out = 0;
	strm.zalloc = Z_NULL;
	strm.zfree = Z_NULL;
	
	if (inflateInit (&strm) != Z_OK) return nil;
	
	while (!done) {
		// Make sure we have enough room and reset the lengths.
		if (strm.total_out >= [decompressed length])
			[decompressed increaseLengthBy: half_length];
		strm.next_out = [decompressed mutableBytes] + strm.total_out;
		strm.avail_out = (unsigned)([decompressed length] - strm.total_out);
		
		// Inflate another chunk.
		status = inflate (&strm, Z_SYNC_FLUSH);
		if (status == Z_STREAM_END) done = YES;
		else if (status != Z_OK) break;
	}
	if (inflateEnd (&strm) != Z_OK) return nil;
	
	// Set real length.
	if (done) {
		[decompressed setLength: strm.total_out];
		return [NSData dataWithData: decompressed];
	}
	else return nil;
}

- (NSData *)zlibDeflate {
	if ([self length] == 0) return self;
	
	z_stream strm;
	
	strm.zalloc = Z_NULL;
	strm.zfree = Z_NULL;
	strm.opaque = Z_NULL;
	strm.total_out = 0;
	strm.next_in=(Bytef *)[self bytes];
	strm.avail_in = (unsigned)[self length];
	
	// Compresssion Levels:
	//   Z_NO_COMPRESSION
	//   Z_BEST_SPEED
	//   Z_BEST_COMPRESSION
	//   Z_DEFAULT_COMPRESSION
	
	if (deflateInit(&strm, Z_BEST_COMPRESSION) != Z_OK) return nil;
	
	NSMutableData *compressed = [NSMutableData dataWithLength:16384];  // 16K chuncks for expansion
	
	do {
		
		if (strm.total_out >= [compressed length])
			[compressed increaseLengthBy: 16384];
		
		strm.next_out = [compressed mutableBytes] + strm.total_out;
		strm.avail_out = (unsigned)([compressed length] - strm.total_out);
		
		deflate(&strm, Z_FINISH);  
		
	} while (strm.avail_out == 0);
	
	deflateEnd(&strm);
	
	[compressed setLength: strm.total_out];
	return [NSData dataWithData: compressed];
}

/*
 Code for `gzipInflate` method by Mark Adler.
 https://stackoverflow.com/a/17822217
 */
- (NSData *)gzipInflate {
	z_stream strm;
	
	// Initialize input
	strm.next_in = (Bytef *)[self bytes];
	NSUInteger left = [self length];        // input left to decompress
	if (left == 0) {
		return nil;                         // incomplete gzip stream
	}
	
	// Create starting space for output (guess double the input size, will grow
	// if needed -- in an extreme case, could end up needing more than 1000
	// times the input size)
	NSUInteger space = left << 1;
	if (space < left) {
		space = NSUIntegerMax;
	}
	NSMutableData *decompressed = [NSMutableData dataWithLength:space];
	space = [decompressed length];
	
	// Initialize output
	strm.next_out = (Bytef *)[decompressed mutableBytes];
	NSUInteger have = 0;                    // output generated so far
	
	// Set up for gzip decoding
	strm.avail_in = 0;
	strm.zalloc = Z_NULL;
	strm.zfree = Z_NULL;
	strm.opaque = Z_NULL;
	int status = inflateInit2(&strm, (15+16));
	if (status != Z_OK) {
		return nil;                         // out of memory
	}
	
	// Decompress all of self
	do {
		// Allow for concatenated gzip streams (per RFC 1952)
		if (status == Z_STREAM_END) {
			(void)inflateReset(&strm);
		}
		
		// Provide input for inflate
		if (strm.avail_in == 0) {
			strm.avail_in = left > UINT_MAX ? UINT_MAX : (unsigned)left;
			left -= strm.avail_in;
		}
		
		// Decompress the available input
		do {
			// Allocate more output space if none left
			if (space == have) {
				// Double space, handle overflow
				space <<= 1;
				if (space < have) {
					space = NSUIntegerMax;
					if (space == have) {
						// space was already maxed out!
						(void)inflateEnd(&strm);
						return nil;         // output exceeds integer size
					}
				}
				
				// Increase space
				[decompressed setLength:space];
				space = [decompressed length];
				
				// Update output pointer (might have moved)
				strm.next_out = (Bytef *)[decompressed mutableBytes] + have;
			}
			
			// Provide output space for inflate
			strm.avail_out = space - have > UINT_MAX ? UINT_MAX :
			(unsigned)(space - have);
			have += strm.avail_out;
			
			// Inflate and update the decompressed size
			status = inflate (&strm, Z_SYNC_FLUSH);
			have -= strm.avail_out;
			
			// Bail out if any errors
			if (status != Z_OK && status != Z_BUF_ERROR &&
				status != Z_STREAM_END) {
				(void)inflateEnd(&strm);
				return nil;                 // invalid gzip stream
			}
			
			// Repeat until all output is generated from provided input (note
			// that even if strm.avail_in is zero, there may still be pending
			// output -- we're not done until the output buffer isn't filled)
		} while (strm.avail_out == 0);
		
		// Continue until all input consumed
	} while (left || strm.avail_in);
	
	// Free the memory allocated by inflateInit2()
	(void)inflateEnd(&strm);
	
	// Verify that the input is a valid gzip stream
	if (status != Z_STREAM_END) {
		return nil;                         // incomplete gzip stream
	}
	
	// Set the actual length and return the decompressed data
	[decompressed setLength:have];
	return decompressed;
}

- (NSData *)gzipDeflate {
	if ([self length] == 0) return self;
	
	z_stream strm;
	
	strm.zalloc = Z_NULL;
	strm.zfree = Z_NULL;
	strm.opaque = Z_NULL;
	strm.total_out = 0;
	strm.next_in=(Bytef *)[self bytes];
	strm.avail_in = (unsigned)[self length];
	
	// Compresssion Levels:
	//   Z_NO_COMPRESSION
	//   Z_BEST_SPEED
	//   Z_BEST_COMPRESSION
	//   Z_DEFAULT_COMPRESSION
	
	if (deflateInit2(&strm, Z_DEFAULT_COMPRESSION, Z_DEFLATED, (15+16), 8, Z_DEFAULT_STRATEGY) != Z_OK) return nil;
	
	NSMutableData *compressed = [NSMutableData dataWithLength:16384];  // 16K chunks for expansion
	
	do {
		
		if (strm.total_out >= [compressed length])
			[compressed increaseLengthBy: 16384];
		
		strm.next_out = [compressed mutableBytes] + strm.total_out;
		strm.avail_out = (unsigned)([compressed length] - strm.total_out);
		
		deflate(&strm, Z_FINISH);  
		
	} while (strm.avail_out == 0);
	
	deflateEnd(&strm);
	
	[compressed setLength: strm.total_out];
	return [NSData dataWithData:compressed];
}

@end
