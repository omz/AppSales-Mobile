//
//  Review.m
//  AppSalesMobile
//
//  Created by Ole Zorn on 11.09.09.
//  Copyright 2009 omz:software. All rights reserved.
//

#import "AppManager.h"
#import "Review.h"
#import "LKGoogleTranslator.h"
#import "AppSalesUtils.h"


@implementation Review

#define TRANSLATE_REVIEWS_SETTINGS_KEY @"translateReviews"
static BOOL showTranslations;
+ (BOOL) showTranslatedReviews {
	return showTranslations;
}
+ (void) setShowTranslatedReviews:(BOOL)showTranslatedReviews {
	showTranslations = showTranslatedReviews;
	[[NSUserDefaults standardUserDefaults] setBool:showTranslations forKey:TRANSLATE_REVIEWS_SETTINGS_KEY];
}

static NSString *presentationLanguage, *defaultCountryCode;

+ (void) initialize  {
	if (self == [Review class]) {
		NSLocale *defaultLocale = [NSLocale currentLocale];
		presentationLanguage = [defaultLocale objectForKey:NSLocaleLanguageCode];
		defaultCountryCode = [defaultLocale objectForKey:NSLocaleCountryCode];
		
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		showTranslations = [defaults boolForKey:TRANSLATE_REVIEWS_SETTINGS_KEY];
	}
}

@synthesize user, stars, reviewDate, downloadDate, version, countryCode, newOrUpdatedReview;

- (id) initWithUser:(NSString*)userName reviewDate:(NSDate*)rDate downloadDate:(NSDate*)dDate
			version:(NSString*)reviewVersion countryCode:(NSString*)reviewCountryCode title:(NSString*)reviewTitle 
			   text:(NSString*)reviewText stars:(NSUInteger)numStars {
	self = [super init];
	if (self) {
		user = [ASSERT_NOT_NULL(userName) retain];
		reviewDate = [ASSERT_NOT_NULL(rDate) retain];
		downloadDate = [ASSERT_NOT_NULL(dDate) retain];
		version = [ASSERT_NOT_NULL(reviewVersion) retain];
		countryCode = [ASSERT_NOT_NULL(reviewCountryCode) retain];
		title = [ASSERT_NOT_NULL(reviewTitle) retain];
		text = [ASSERT_NOT_NULL(reviewText) retain];
		stars = numStars;
		newOrUpdatedReview = true;
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)coder {
	[super init];
	user = [[coder decodeObjectForKey:@"user"] retain];
	title = [[coder decodeObjectForKey:@"title"] retain];
	translatedTitle = [[coder decodeObjectForKey:@"translatedTitle"] retain];
	reviewDate = [[coder decodeObjectForKey:@"reviewDate"] retain];
	downloadDate = [[coder decodeObjectForKey:@"downloadDate"] retain];
	text = [[coder decodeObjectForKey:@"text"] retain];
	translatedText = [[coder decodeObjectForKey:@"translatedText"] retain];
	version = [[coder decodeObjectForKey:@"version"] retain];
	countryCode = [[coder decodeObjectForKey:@"countryCode"] retain];
	stars = [coder decodeIntForKey:@"stars"];
	// newOrUpdatedReview field is not set, as it's only used to indicate a review was newly added 
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:user forKey:@"user"];
	[coder encodeObject:title forKey:@"title"];
	[coder encodeObject:translatedTitle forKey:@"translatedTitle"];
	[coder encodeObject:reviewDate forKey:@"reviewDate"];
	[coder encodeObject:downloadDate forKey:@"downloadDate"];
	[coder encodeObject:text forKey:@"text"];
	[coder encodeObject:translatedText forKey:@"translatedText"];
	[coder encodeObject:version forKey:@"version"];
	[coder encodeObject:countryCode forKey:@"countryCode"];
	[coder encodeInt:stars forKey:@"stars"];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"%@ (%@ %@): %@ (%i stars)", self.user, self.countryCode, self.reviewDate, self.title, self.stars];
}

- (NSString*) translateToCurrentCountry:(NSString*)string {
    ASSERT_NOT_MAIN_THREAD();
	LKGoogleTranslator *translator = [[LKGoogleTranslator alloc] init];
	NSString *translated = [translator translateText:string toLanguage:presentationLanguage];
	[translator release];
	return translated;
}

- (NSString*) title {
	return title;
}
- (NSString*) translatedTitle {
	return translatedTitle;
}

- (NSString*) text {
	return text;
}
- (NSString*) translatedText {
	return translatedText;
}

- (NSString*) presentationTitle {
	return showTranslations ? translatedTitle : title;
}
- (NSString*) presentationText {
	return showTranslations ? translatedText : text;
}

- (void) privateSetTranslatedTitle:(NSString*)t1 text:(NSString*)t2 {
    [translatedTitle release];
    translatedTitle = [t1 retain];
    [translatedText release];
    translatedText = [t2 retain];
}

+ (void) updateTranslations:(NSArray*)reviews {
    ASSERT_NOT_MAIN_THREAD();
    
    NSMutableArray *unTranslated = [NSMutableArray arrayWithCapacity:2*reviews.count];
    for (Review *review in reviews) {
        [unTranslated addObject:review.title];
        [unTranslated addObject:review.text];
    }
    
    LKGoogleTranslator *translator = [[LKGoogleTranslator new] autorelease];
	NSArray *translated = [translator translateMultipleText:unTranslated toLanguage:presentationLanguage];
    
    for (NSUInteger i=0; i < reviews.count; i++) {
        Review *review = [reviews objectAtIndex:i];
        NSString *translatedTitle = [translated objectAtIndex:2*i];
        NSString *translatedText = [translated objectAtIndex:2*i+1];
        [review privateSetTranslatedTitle:translatedTitle text:translatedText];
    }
}
         
- (void) updateTranslations {
    ASSERT_NOT_MAIN_THREAD();
	if (translatedText == nil && text != nil) {
		translatedText = [[self translateToCurrentCountry:text] retain];
	}
	if (translatedTitle == nil && title != nil) {
		translatedTitle = [[self translateToCurrentCountry:title] retain];
	}
}

- (void)dealloc {
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
