//
//  LKGoogleTranslator.m
//  GoogleTranslator
//
// originally found here: http://code.google.com/p/objc-google-translate-api/
//

#import "LKGoogleTranslator.h"
#import "JSON.h"
#import "NSString+UnescapeHtml.h"

#define MAX_INPUT_TEXT_LENGTH 2200 // size after url encoding, and arbitrarily set by Google 
#define URL_STRING @"http://ajax.googleapis.com/ajax/services/language/translate?v=1.0&langpair="
#define TEXT_VAR @"&q="

@implementation LKGoogleTranslator

@synthesize markTranslationsWithDetectedOriginalLanguage;

- (NSString*)translateText:(NSString*)sourceText toLanguage:(NSString*)targetLanguage {
	return [self translateText:@"" toLanguage:targetLanguage];
}

- (NSString*)translateText:(NSString*)sourceText fromLanguage:(NSString*)sourceLanguage toLanguage:(NSString*)targetLanguage {
#if APPSALES_DEBUG
	NSLog(@"translating into %@: %@", targetLanguage, sourceText);
#endif
	NSString *urlEncodedSource = [sourceText correctlyEncodeToURL];
	if (urlEncodedSource.length > MAX_INPUT_TEXT_LENGTH) {
		return sourceText;
	}
	
	NSMutableString* urlString = [NSMutableString string];
	[urlString appendString: URL_STRING];
	[urlString appendString: sourceLanguage];
	[urlString appendString: @"%7C"];
	[urlString appendString: targetLanguage];
	[urlString appendString: TEXT_VAR];
	[urlString appendString: urlEncodedSource];
	NSURL *url = [NSURL URLWithString: urlString];
	NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30];
	NSURLResponse *response = nil; NSError* error = nil;
	NSData* data = [NSURLConnection sendSynchronousRequest: request returningResponse: &response error: &error];
	if (error) {
		NSLog(@"Could not connect to the server: %@ %@", urlString, [error description]);
		return sourceText;
	}
	NSString* contents = [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] autorelease];
	id responseData = [[contents JSONValue] objectForKey: @"responseData"];
	if (responseData == [NSNull null]) {
		return sourceText;
	}
	NSString *translatedText = [[responseData objectForKey: @"translatedText"] removeHtmlEscaping];
	if (markTranslationsWithDetectedOriginalLanguage) {
		// marks which language the original was in
		NSString *detectedLanguage = [responseData objectForKey:@"detectedSourceLanguage"];
		if ([detectedLanguage isEqualToString:targetLanguage] || [translatedText isEqualToString:sourceText]) {
			return sourceText; // was already in requested language, or Google couldn't translate
		}
		// indicate what the original language was
		return [translatedText stringByAppendingFormat:@" (%@)", detectedLanguage];
	}
	return translatedText;		
}

@end
