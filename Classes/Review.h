//
//  Review.h
//  AppSalesMobile
//
//  Created by Ole Zorn on 11.09.09.
//  Copyright 2009 omz:software. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Review : NSObject {
	@private
	NSString *user;
	NSString *title, *translatedTitle;
	NSUInteger stars;
	NSDate *reviewDate;
	NSDate *downloadDate;
	NSString *text, *translatedText;
	NSString *version;
	NSString *countryCode;
	
	BOOL newOrUpdatedReview; // only used for presentation
}

+ (BOOL) showTranslatedReviews;
+ (void) setShowTranslatedReviews:(BOOL)showTranslatedReviews;

+ (void) updateTranslations:(NSArray*)reviews; // identical to the individual instance method, but much faster when translating multiple reviews

@property (retain, readonly) NSString *user;
@property (retain, readonly) NSDate *reviewDate;
@property (retain, readonly) NSDate *downloadDate;
@property (retain, readonly) NSString *version; // may be empty string, as some iTunes review don't include the app version
@property (retain, readonly) NSString *countryCode;
@property (retain, readonly) NSString *title;
@property (retain, readonly) NSString *text;
@property (assign, readonly) NSUInteger stars;
@property (readonly) NSString *translatedTitle;
@property (readonly) NSString *translatedText;
@property (readonly) NSString *presentationTitle; // either translated, or non translated text (depending on user preference) 
@property (readonly) NSString *presentationText;

@property (assign, readwrite) BOOL newOrUpdatedReview; // only mutable field

- (id) initWithUser:(NSString*)userName reviewDate:(NSDate*)rDate downloadDate:(NSDate*)dDate version:(NSString*)reviewVersion 
		countryCode:(NSString*)reviewCountryCode title:(NSString*)reviewTitle text:(NSString*)reviewText stars:(NSUInteger)numStars;

- (void) updateTranslations; // must be called off main thread

@end
