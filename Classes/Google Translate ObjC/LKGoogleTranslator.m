//
//  LKGoogleTranslator.m
//  GoogleTranslator
//
// originally found here: http://code.google.com/p/objc-google-translate-api/
//

#import "LKGoogleTranslator.h"
#import "JSON.h"
#import "NSString+UnescapeHtml.h"

#define MAX_INPUT_TEXT_LENGTH 1900 // size after url encoding, and arbitrarily set by Google 
#define URL_STRING @"http://ajax.googleapis.com/ajax/services/language/translate?v=1.0&langpair="
#define TEXT_VAR @"&q="
// api key is not required, but seems to prevent excessive translation requests while doing development work
#define APPSALES_GOOGLE_API_KEY @"ABQIAAAAOsoivIE0DZ2IaaWJfN6eaxTOf_JKXOhUlrp88MCNXGV04gvo5BRA7GwYN8vlPOWdV7SjmUT8cAqSqQ"

@implementation LKGoogleTranslator

@synthesize markTranslationsWithDetectedOriginalLanguage;

- (NSString*)translateText:(NSString*)sourceText toLanguage:(NSString*)targetLanguage {
	return [self translateText:sourceText fromLanguage:@"" toLanguage:targetLanguage];
}

- (NSString*)translateText:(NSString*)sourceText fromLanguage:(NSString*)sourceLanguage toLanguage:(NSString*)targetLanguage {
	NSString *urlEncodedSource = [sourceText correctlyEncodeToURL];
	if (urlEncodedSource.length > MAX_INPUT_TEXT_LENGTH) {
		#if APPSALES_DEBUG
			NSLog(@"string too long, skipping translation: %@", sourceText);
		#endif
		return sourceText;
	}
	#if APPSALES_DEBUG
		NSLog(@"translating into %@: %@", targetLanguage, sourceText);
	#endif
	
	
	NSMutableString* urlString = [NSMutableString string];
	[urlString appendString: URL_STRING];
	[urlString appendString: sourceLanguage];
	[urlString appendString: @"%7C"];
	[urlString appendString: targetLanguage];
	[urlString appendString: @"&key="];
	[urlString appendString: APPSALES_GOOGLE_API_KEY];
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
	NSString* contents = [[[NSString alloc] initWithData:data encoding: NSUTF8StringEncoding] autorelease];
	id responseData = [[contents JSONValue] objectForKey:@"responseData"];
	if (responseData == [NSNull null]) {
		#if APPSALES_DEBUG
			NSLog(@"translation error:%@", contents);
		#endif
		return sourceText;
	}
	NSString *translatedText = [responseData objectForKey: @"translatedText"];
	if (translatedText == nil) {
		return sourceText;
	}
	translatedText = [translatedText removeHtmlEscaping];
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
