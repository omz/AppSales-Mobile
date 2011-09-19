//
//  LKGoogleTranslator.h
//  GoogleTranslator
//
//  originally found here: http://code.google.com/p/objc-google-translate-api/
//

#import <Foundation/Foundation.h>

@interface LKGoogleTranslator : NSObject {
}

- (NSString*)translateText:(NSString*)sourceText toLanguage:(NSString*)targetLanguage;
- (NSString*)translateText:(NSString*)sourceText fromLanguage:(NSString*)sourceLanguage toLanguage:(NSString*)targetLanguage;

// more efficient as only one request is made to translate all strings
- (NSArray*)translateMultipleText:(NSArray*)stringArray toLanguage:(NSString*)targetLanguage;
- (NSArray*)translateMultipleText:(NSArray*)stringArray fromLanguage:(NSString*)sourceLanguage toLanguage:(NSString*)targetLanguage;

@end

#define LKLanguageArabic @"ar"
#define LKLanguageBulgarian @"bg"
#define LKLanguageCatalan @"ca"
#define LKLanguageChinese @"zh"
#define LKLanguageChineseSimplified @"zh-CN"
#define LKLanguageChineseTraditional @"zh-TW"
#define LKLanguageCroation @"cr"
#define LKLanguageCzech @"cs"
#define LKLanguageDanish @"da"
#define LKLanguageDutch @"nl"
#define LKLanguageEnglish @"en"
#define LKLanguageFilipino @"tl"
#define LKLanguageFinnish @"fi"
#define LKLanguageFrench @"fr"
#define LKLanguageGerman @"de"
#define LKLanguageGreek @"el"
#define LKLanguageHebrew @"iw"
#define LKLanguageHindi @"hi"
#define LKLanguageIndonesian @"id"
#define LKLanguageItalian @"it"
#define LKLanguageJapanese @"ja"
#define LKLanguageKorean @"ko"
#define LKLanguageLatvian @"lv"
#define LKLanguageLithuanian @"lt"
#define LKLanguageNorwegian @"no"
#define LKLanguagePolish @"pl"
#define LKLanguagePortuguese @"pt"
#define LKLanguageRomanian @"ro"
#define LKLanguageRussian @"ru"
#define LKLanguageSerbian @"sr"
#define LKLanguageSlovak @"sk"
#define LKLanguageSlovenian @"sl"
#define LKLanguageSpanish @"es"
#define LKLanguageSwedish @"sv"
#define LKLanguageUkrainian @"uk"
#define LKLanguageVietnamese @"vi"
