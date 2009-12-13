//
//  Review.m
//  AppSalesMobile
//
//  Created by Ole Zorn on 11.09.09.
//  Copyright 2009 omz:software. All rights reserved.
//

#import "Review.h"
#import "LKGoogleTranslator.h"


@implementation Review

static BOOL showTranslations;
+ (BOOL) showTranslatedReviews {
	return showTranslations;
}
+ (void) setShowTranslatedReviews:(BOOL)showTranslatedReviews {
	showTranslations = showTranslatedReviews;
	[[NSUserDefaults standardUserDefaults] setBool:showTranslations forKey:@"translateReviews"];
}

static NSString *presentationLanguage, *defaultCountryCode;

+ (void) initialize 
{
	if (self == [Review class]) {
		NSLocale *defaultLocale = [NSLocale currentLocale];
		presentationLanguage = [defaultLocale objectForKey:NSLocaleLanguageCode];
		defaultCountryCode = [defaultLocale objectForKey:NSLocaleCountryCode];
		
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		showTranslations = [defaults boolForKey:@"translateReviews"];
	}
}

@synthesize user, stars, reviewDate, downloadDate, version, countryCode, newOrUpdatedReview;

- (id)initWithCoder:(NSCoder *)coder
{
	[super init];
	self.user = [coder decodeObjectForKey:@"user"];
	self.title = [coder decodeObjectForKey:@"title"];
	translatedTitle = [[coder decodeObjectForKey:@"translatedTitle"] retain];
	self.stars = [coder decodeIntForKey:@"stars"];
	self.reviewDate = [coder decodeObjectForKey:@"reviewDate"];
	self.downloadDate = [coder decodeObjectForKey:@"downloadDate"];
	self.text = [coder decodeObjectForKey:@"text"];
	translatedText = [[coder decodeObjectForKey:@"translatedText"] retain];
	self.version = [coder decodeObjectForKey:@"version"];
	self.countryCode = [coder decodeObjectForKey:@"countryCode"];
	// newOrUpdatedReview field is not set, as it's only used to indicate a review was newly added 
	return self;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ (%@ %@): %@ (%i stars)", self.user, self.countryCode, self.reviewDate, self.title, self.stars];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:self.user forKey:@"user"];
	[coder encodeObject:self.title forKey:@"title"];
	[coder encodeObject:self.translatedTitle forKey:@"translatedTitle"];
	[coder encodeInt:self.stars forKey:@"stars"];
	[coder encodeObject:self.reviewDate forKey:@"reviewDate"];
	[coder encodeObject:self.downloadDate forKey:@"downloadDate"];
	[coder encodeObject:self.text forKey:@"text"];
	[coder encodeObject:self.translatedText forKey:@"translatedText"];
	[coder encodeObject:self.version forKey:@"version"];
	[coder encodeObject:self.countryCode forKey:@"countryCode"];
}

- (NSString*) translateToCurrentCountry:(NSString*)string {
	NSAssert(! [NSThread isMainThread], nil);
	if ([countryCode caseInsensitiveCompare:defaultCountryCode] == NSOrderedSame) {
		return string; // already in native country language
	}
	LKGoogleTranslator *translator = [[LKGoogleTranslator alloc] init];
	NSString *translated = [translator translateText:string fromLanguage:@"" toLanguage:presentationLanguage];
	[translator release];
	return translated;
}

- (void) setTitle:(NSString*)titleToSet {
	[titleToSet retain]; // must retain before releasing old
	[title release];
	title = titleToSet;
	[translatedTitle release];
	translatedTitle = nil;
}
- (NSString*) title {
	return title;
}
- (NSString*) translatedTitle {
	return translatedTitle;
}


- (void) setText:(NSString*)textToSet {
	[textToSet retain];
	[text release];
	text = textToSet;
	[translatedText release];
	translatedText = nil;
}
- (NSString*) text {
	return text;
}
- (NSString*) translatedText {
	return translatedText;
}

- (NSString*) presentedTitle {
	return showTranslations ? translatedTitle : title;
}
- (NSString*) presentedText {
	return showTranslations ? translatedText : text;
}

- (void) updateTranslations {
	if (translatedText == nil && text != nil) {
		translatedText = [[self translateToCurrentCountry:text] retain];
	}
	if (translatedTitle == nil && title != nil) {
		translatedTitle = [[self translateToCurrentCountry:title] retain];
	}
}

- (void)dealloc
{
	[user release];
	[title release];
	[translatedTitle release];
	[reviewDate release];
	[downloadDate release];
	[text release];
	[translatedText release];
	[version release];
	[countryCode release];
	[super dealloc];
}

@end
