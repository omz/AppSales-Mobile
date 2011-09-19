//
//  Review.m
//  AppSales
//
//  Created by Ole Zorn on 27.07.11.
//  Copyright (c) 2011 omz:software. All rights reserved.
//

#import "Review.h"
#import "Product.h"


@implementation Review

#define TRANSLATE_REVIEWS_SETTINGS_KEY @"translateReviews"
static BOOL showTranslations = NO;
+ (BOOL) showTranslatedReviews {
	return showTranslations;
}
+ (void) setShowTranslatedReviews:(BOOL)showTranslatedReviews {
	showTranslations = showTranslatedReviews;
	[[NSUserDefaults standardUserDefaults] setBool:showTranslations forKey:TRANSLATE_REVIEWS_SETTINGS_KEY];
}

+ (void) initialize  {
	if (self == [Review class]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		showTranslations = [defaults boolForKey:TRANSLATE_REVIEWS_SETTINGS_KEY];
	}
}

@dynamic text;
@dynamic translatedText;
@dynamic countryCode;
@dynamic rating;
@dynamic title;
@dynamic translatedTitle;
@dynamic user;
@dynamic downloadDate;
@dynamic reviewDate;
@dynamic unread;
@dynamic product;
@dynamic productVersion;

- (NSString*) presentationTitle {
    if (showTranslations) {
        NSString *translated = self.translatedTitle;
        if (translated) { // check for old versions of data
            return translated;
        }
    }
    return self.title;
}
- (NSString*) presentationText {
    if (showTranslations) {
        NSString *translated = self.translatedText;
        if (translated) {
            return translated;
        }
    }
    return self.text;

}

@end
