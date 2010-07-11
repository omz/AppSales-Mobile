//Adds compression and decompression messages to NSData. 
//Methods extracted from source given at http://www.cocoadev.com/index.pl?NSDataCategory

#import <Foundation/Foundation.h>


@interface NSData (Compression)

// ZLIB
- (NSData *) zlibInflate;
- (NSData *) zlibDeflate;

// GZIP
- (NSData *) gzipInflate;
- (NSData *) gzipDeflate;

@end