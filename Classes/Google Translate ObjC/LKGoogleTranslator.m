//
//  LKGoogleTranslator.m
//  GoogleTranslator
//
// originally found here: http://code.google.com/p/objc-google-translate-api/
//

#import "LKGoogleTranslator.h"
#import "JSON.h"

#define URL_STRING @"http://ajax.googleapis.com/ajax/services/language/translate?v=1.0&langpair="
#define TEXT_VAR @"&q="

@implementation LKGoogleTranslator

@synthesize markTranslationsWithDetectedOriginalLanguage;

- (NSString*)translateText:(NSString*)sourceText fromLanguage:(NSString*)sourceLanguage toLanguage:(NSString*)targetLanguage {
#if APPSALES_DEBUG
	NSLog(@"translating into %@: %@", targetLanguage, sourceText);
#endif
	NSMutableString* urlString = [NSMutableString string];
	[urlString appendString: URL_STRING];
	[urlString appendString: sourceLanguage];
	[urlString appendString: @"%7C"];
	[urlString appendString: targetLanguage];
	[urlString appendString: TEXT_VAR];
	[urlString appendString: [sourceText stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	NSURL* url = [NSURL URLWithString: urlString];
	NSURLRequest* request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60];
	NSURLResponse* response = nil; NSError* error = nil;
	NSData* data = [NSURLConnection sendSynchronousRequest: request returningResponse: &response error: &error];
	if (error) {
		NSLog(@"Could not connect to the server: %@ %@", urlString, [error description]);
		return sourceText;
	}
	NSString* contents = [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] autorelease];
	if ([contents rangeOfString:@"Request-URI Too Large"].location != NSNotFound) {
		return sourceText;
	}
	id responseData = [[contents JSONValue] objectForKey: @"responseData"];
	if (responseData == [NSNull null]) {
		return sourceText;
	}
	NSString *translatedText = [responseData objectForKey: @"translatedText"];
	if (markTranslationsWithDetectedOriginalLanguage) {
		// marks which language the original was in
		NSString *detectedLanguage = [responseData objectForKey:@"detectedSourceLanguage"];
		if ([detectedLanguage isEqualToString:targetLanguage] || [translatedText isEqualToString:sourceText]) {
			return sourceText; // was already in requested language, or Google couldn't translate
		}
		// indicate what the original language was
		return [NSString stringWithFormat:@"%@ (%@)", [self translateCharacters:translatedText], detectedLanguage];
	}
	return translatedText;		
}

- (NSString*)translateCharacters:(NSString*)text {
	NSMutableString* translatedText = [NSMutableString string];
	NSRange range = [text rangeOfString: @"&#"];
	int processedSoFar = 0;
	while (range.location != NSNotFound) {
		int pos = range.location;
		[translatedText appendString: [text substringWithRange: NSMakeRange(processedSoFar, pos - processedSoFar)]];
		range = [text rangeOfString: @";" options: 0 range: NSMakeRange(pos + 2, [text length] - pos - 2)];
		int code = [[text substringWithRange: NSMakeRange(pos + 2, range.location - pos - 2)] intValue];
		[translatedText appendFormat: @"%C", (unichar) code];
		processedSoFar = range.location + 1;
		range = [text rangeOfString: @"&#" options: 0 range: NSMakeRange(processedSoFar, [text length] - processedSoFar)];
	}
	[translatedText appendString: [text substringFromIndex: processedSoFar]];
	return translatedText;
}

@end
