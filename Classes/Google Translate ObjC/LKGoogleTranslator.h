//
//  LKGoogleTranslator.h
//  GoogleTranslator
//
// originally found here: http://code.google.com/p/objc-google-translate-api/
//

#import <Foundation/Foundation.h>
#import "LKConstants.h"

@interface LKGoogleTranslator : NSObject {
}

- (NSString*)translateText:(NSString*)sourceText toLanguage:(NSString*)targetLanguage;
- (NSString*)translateText:(NSString*)sourceText fromLanguage:(NSString*)sourceLanguage toLanguage:(NSString*)targetLanguage;

// more efficient as only one request is made to translate all strings
- (NSArray*)translateMultipleText:(NSArray*)stringArray toLanguage:(NSString*)targetLanguage;
- (NSArray*)translateMultipleText:(NSArray*)stringArray fromLanguage:(NSString*)sourceLanguage toLanguage:(NSString*)targetLanguage;

@end
