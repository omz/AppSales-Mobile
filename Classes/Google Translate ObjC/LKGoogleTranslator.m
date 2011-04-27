//
//  LKGoogleTranslator.m
//  GoogleTranslator
//
//  originally found here: http://code.google.com/p/objc-google-translate-api/
//

#import "LKGoogleTranslator.h"
#import "JSON.h"
#import "NSString+UnescapeHtml.h"
#import "AppSalesUtils.h" 

#define APPSALES_GOOGLE_API_KEY @"ABQIAAAAOsoivIE0DZ2IaaWJfN6eaxTOf_JKXOhUlrp88MCNXGV04gvo5BRA7GwYN8vlPOWdV7SjmUT8cAqSqQ"
#define URL_STRING @"http://ajax.googleapis.com/ajax/services/language/translate"
#define LANGUAGE_VAR @"v=1.0&langpair="
#define TEXT_VAR @"&q="

@implementation LKGoogleTranslator

- (NSString*)translateText:(NSString*)sourceText toLanguage:(NSString*)targetLanguage {
    return [self translateText:sourceText fromLanguage:@"" toLanguage:targetLanguage];
}
- (NSString*)translateText:(NSString*)sourceText fromLanguage:(NSString*)sourceLanguage toLanguage:(NSString*)targetLanguage {
    return [[self translateMultipleText:[NSArray arrayWithObject:sourceText] toLanguage:targetLanguage] lastObject];
}
- (NSArray*)translateMultipleText:(NSArray*)stringArray toLanguage:(NSString*)targetLanguage {
    return [self translateMultipleText:stringArray fromLanguage:@"" toLanguage:targetLanguage];
}
- (NSArray*)translateMultipleText:(NSArray*)sourceArray fromLanguage:(NSString*)sourceLanguage toLanguage:(NSString*)targetLanguage {
    NSMutableString *body = [NSMutableString stringWithCapacity:LANGUAGE_VAR.length + APPSALES_GOOGLE_API_KEY.length 
                             + sourceArray.count * 150];
    [body appendString:LANGUAGE_VAR];
    [body appendString:sourceLanguage];
    [body appendString:@"%7C"];
    [body appendString:targetLanguage];
    [body appendString:@"&key="];
    [body appendString:APPSALES_GOOGLE_API_KEY];
    for (NSString *sourceText in sourceArray) {
        NSString *urlEncodedSource = [sourceText correctlyEncodeToURL];
        APPSALESLOG(@"translating into %@: %@", targetLanguage, sourceText);
        
        [body appendString:TEXT_VAR];
        [body appendString:urlEncodedSource];
    }
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:URL_STRING]
                                                                cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                            timeoutInterval:20];
    [request setHTTPMethod:@"POST"];
    [request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField: @"Content-Type"];
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSHTTPURLResponse *response = nil; 
    NSError *error = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    [request release];
    if (error) {
        NSLog(@"Could not translate text: %@", error.description);
        return sourceArray;
    }
    
    NSString *contents = [[NSString alloc] initWithData:data encoding: NSUTF8StringEncoding];
    id contentsJSON = [contents JSONValue];
    [contents release];
    
    // sample response for multiple translation
    //    {"responseData": [ {"responseData":{"translatedText":"ciao a tutti"},"responseDetails":null,"responseStatus":200},
    //                       {"responseData":{"translatedText":"addio"},"responseDetails":null,"responseStatus":200} ],
    //    "responseDetails": null,
    //    "responseStatus": 200}
        
    NSInteger responseStatus = [[contentsJSON objectForKey:@"responseStatus"] integerValue];
    id responseData = [contentsJSON objectForKey:@"responseData"];
    
    switch (responseStatus) {
        case 206: // some translations contain errors.  fall through
        case 200: // translated ok
            if ([responseData isKindOfClass:[NSArray class]]) {
                // multiple translations.  would be nice to use recursion here,
                // but the code gets messy since Google doesn't return the original string if translation fails
                NSMutableArray *results = [NSMutableArray arrayWithCapacity:sourceArray.count];
                for (NSUInteger i=0; i < [responseData count]; i++) {
                    id element = [responseData objectAtIndex:i];
                    NSInteger subResponseStatus = [[element objectForKey:@"responseStatus"] integerValue];
                    id subResponseData = [element objectForKey:@"responseData"];
                    if (subResponseStatus == 200) {
                        NSString *translated = [[subResponseData objectForKey: @"translatedText"] removeHtmlEscaping];
                        [results addObject:translated];
                    } else {
                        NSString *original = [sourceArray objectAtIndex:i];
                        [results addObject:original];
                        NSLog(@"could not translate - %@ - %@", [element objectForKey: @"responseDetails"], original);
                    }
                }
                return results;
            } // else, single string translation
            NSString *translated = [[responseData objectForKey: @"translatedText"] removeHtmlEscaping];
            return [NSArray arrayWithObject:translated];
        case 400: // could not reliably translate text
            NSLog(@"could not reliably translate text: %@", sourceArray);
            return sourceArray;
        case 403: // throttled by Google
            NSLog(@"reached translation api rate limit, cannot translate text");
            return sourceArray; // stop here
    }
    // default
    NSLog(@"unexpected response: %@", contentsJSON);
    return sourceArray;
}

@end
