//
//  LKGoogleTranslator.h
//  GoogleTranslator
//
// originally found here: http://code.google.com/p/objc-google-translate-api/
//

#import <Foundation/Foundation.h>
#import "LKConstants.h"

@interface LKGoogleTranslator : NSObject {
	@private
	BOOL markTranslationsWithDetectedOriginalLanguage;
}

@property (assign) BOOL markTranslationsWithDetectedOriginalLanguage;

- (NSString*)translateText:(NSString*)sourceText toLanguage:(NSString*)targetLanguage;
- (NSString*)translateText:(NSString*)sourceText fromLanguage:(NSString*)sourceLanguage toLanguage:(NSString*)targetLanguage;

@end
