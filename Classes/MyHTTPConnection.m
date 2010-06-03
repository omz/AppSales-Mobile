//
//  This class was created by Nonnus,
//  who graciously decided to share it with the CocoaHTTPServer community.
//

#import "MyHTTPConnection.h"
#import "HTTPServer.h"
#import "HTTPResponse.h"
#import "AsyncSocket.h"
#import "SFHFKeychainUtils.h"

@implementation MyHTTPConnection


- (BOOL)isBrowseable:(NSString *)path
{
	return YES;
}


- (NSString *)createBrowseableIndex:(NSString *)path
{
	//TODO: Localize the import/export html
	NSMutableString *page = [NSMutableString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ImportTemplate" ofType:@"html"] usedEncoding:NULL error:NULL];
	NSMutableString *reportsList = [NSMutableString string];
	NSArray *files = [[NSFileManager defaultManager] directoryContentsAtPath:path];
    if ([files count] == 0) {
		[reportsList appendString:NSLocalizedString(@"<i>No reports downloaded yet</i>",nil)];
	} else {
		for (NSString *file in files) {
			[reportsList appendFormat:@"<a href=\"%@\">%@</a><br/>", file, file];
		}
	}
	
	[page replaceOccurrencesOfString:@"[[[REPORTFILES]]]" withString:reportsList options:0 range:NSMakeRange(0,[page length])];
    return [NSString stringWithString:page];
}


- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)relativePath
{
	if ([method isEqual:@"POST"])
		return [self supportsPOST:relativePath withSize:0];
	return [super supportsMethod:method atPath:relativePath];
}


- (BOOL)supportsPOST:(NSString *)path withSize:(UInt64)contentLength
{
	dataStartIndex = 0;
	multipartData = [[NSMutableArray alloc] init];
	postHeaderOK = FALSE;
	
	return YES;
}


- (BOOL)isPasswordProtected:(NSString *)path
{
	return YES;
}


- (NSString *)passwordForUser:(NSString *)username
{
	// Security Note:
	// A nil password means no access at all. (Such as for user doesn't exist)
	// An empty string password is allowed, and will be treated as any other password. (To support anonymous access)
	NSString *iTunesConnectUsername = [[NSUserDefaults standardUserDefaults] stringForKey:@"iTunesConnectUsername"];
	NSString *password = nil;
	if (iTunesConnectUsername) {
		password = [SFHFKeychainUtils getPasswordForUsername:username andServiceName:@"omz:software AppSales Mobile Service" error:NULL];
		return password;
	}
	return nil;
}


- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
	if (requestContentLength > 0) {  // Process POST data
		if ([multipartData count] < 2) return nil;
		
		NSString *postInfo = [[[NSString alloc] initWithData:[multipartData objectAtIndex:1] encoding:NSUTF8StringEncoding] autorelease];
		if (!postInfo) postInfo = [[[NSString alloc] initWithData:[multipartData objectAtIndex:1] encoding:NSASCIIStringEncoding] autorelease];
		
		NSArray* postInfoComponents = [postInfo componentsSeparatedByString:@"; filename="];
		
		postInfoComponents = [[postInfoComponents lastObject] componentsSeparatedByString:@"\""];
		postInfoComponents = [[postInfoComponents objectAtIndex:1] componentsSeparatedByString:@"\\"];
			
		NSString* filename = [postInfoComponents lastObject];
		
		if (![filename isEqualToString:@""]) //this makes sure we did not submitted upload form without selecting file
		{
			UInt16 separatorBytes = 0x0A0D;
			NSMutableData* separatorData = [NSMutableData dataWithBytes:&separatorBytes length:2];
			[separatorData appendData:[multipartData objectAtIndex:0]];
			int l = [separatorData length];
			int count = 2;	//number of times the separator shows up at the end of file data
			
			NSFileHandle* dataToTrim = [multipartData lastObject];
						
			for (unsigned long long i = [dataToTrim offsetInFile] - l; i > 0; i--) {
				[dataToTrim seekToFileOffset:i];
				if ([[dataToTrim readDataOfLength:l] isEqualToData:separatorData])
				{
					[dataToTrim truncateFileAtOffset:i];
					i -= l;
					if (--count == 0) break;
				}
			}
			
			[[NSNotificationCenter defaultCenter] postNotificationName:NewFileUploadedNotification object:filename];
		}
		
		[multipartData release];
		requestContentLength = 0;
	}
	
	NSString *filePath = [self filePathForURI:path];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
		return [[[HTTPFileResponse alloc] initWithFilePath:filePath] autorelease];
	}
	else {
		NSString *folder = [path isEqualToString:@"/"] ? [[server documentRoot] path] : [NSString stringWithFormat: @"%@%@", [[server documentRoot] path], path];
		if ([self isBrowseable:folder]) {
			NSData *browseData = [[self createBrowseableIndex:folder] dataUsingEncoding:NSUTF8StringEncoding];
			return [[[HTTPDataResponse alloc] initWithData:browseData] autorelease];
		}
	}
	return nil;
}


- (void)processDataChunk:(NSData *)postDataChunk
{
	if (!postHeaderOK) {
		UInt16 separatorBytes = 0x0A0D;
		NSData* separatorData = [NSData dataWithBytes:&separatorBytes length:2];
		
		int l = [separatorData length];

		for (int i = 0; i < [postDataChunk length] - l; i++) {
			NSRange searchRange = {i, l};

			if ([[postDataChunk subdataWithRange:searchRange] isEqualToData:separatorData]) {
				NSRange newDataRange = {dataStartIndex, i - dataStartIndex};
				dataStartIndex = i + l;
				i += l - 1;
				NSData *newData = [postDataChunk subdataWithRange:newDataRange];

				if ([newData length]) {
					[multipartData addObject:newData];
				}
				else {
					postHeaderOK = TRUE;
					NSString* postInfo = [[[NSString alloc] initWithBytes:[[multipartData objectAtIndex:1] bytes] length:[[multipartData objectAtIndex:1] length] encoding:NSUTF8StringEncoding] autorelease];
					if (!postInfo) {
						postInfo = [[[NSString alloc] initWithData:[multipartData objectAtIndex:1] encoding:NSUTF8StringEncoding] autorelease];
						postInfo = [[[NSString alloc] initWithBytes:[[multipartData objectAtIndex:1] bytes] length:[[multipartData objectAtIndex:1] length] encoding:NSASCIIStringEncoding] autorelease];
					}
					NSArray* postInfoComponents = [postInfo componentsSeparatedByString:@"; filename="];
					
					postInfoComponents = [[postInfoComponents lastObject] componentsSeparatedByString:@"\""];
					postInfoComponents = [[postInfoComponents objectAtIndex:1] componentsSeparatedByString:@"\\"];
					
					NSString* filename = [server.uploadPath stringByAppendingPathComponent:[postInfoComponents lastObject]];
					
					NSRange fileDataRange = {dataStartIndex, [postDataChunk length] - dataStartIndex};
					
					[[NSFileManager defaultManager] createFileAtPath:filename contents:[postDataChunk subdataWithRange:fileDataRange] attributes:nil];
					NSFileHandle *file = [[NSFileHandle fileHandleForUpdatingAtPath:filename] retain];

					if (file) {
						[file seekToEndOfFile];
						[multipartData addObject:file];
					}
					break;
				}
			}
		}
	}
	else {
		[(NSFileHandle*)[multipartData lastObject] writeData:postDataChunk];
	}
}

@end