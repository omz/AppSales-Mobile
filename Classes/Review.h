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
	int stars;
	NSDate *reviewDate;
	NSDate *downloadDate;
	NSString *text, *translatedText;
	NSString *version;
	NSString *countryCode;
	
	BOOL newOrUpdatedReview; // only used for presentation
}

+ (BOOL) showTranslatedReviews;
+ (void) setShowTranslatedReviews:(BOOL)showTranslatedReviews;

@property (nonatomic, retain) NSString *user;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, readonly) NSString *translatedTitle;
@property (nonatomic, retain) NSDate *reviewDate;
@property (nonatomic, retain) NSDate *downloadDate;
@property (nonatomic, retain) NSString *text;
@property (nonatomic, readonly) NSString *translatedText;
@property (nonatomic, assign) int stars;
@property (nonatomic, retain) NSString *version;
@property (nonatomic, retain) NSString *countryCode;
@property (nonatomic, assign) BOOL newOrUpdatedReview;

@property (readonly) NSString *presentationTitle; // either translated, or non translated text (depending on user preference) 
@property (readonly) NSString *presentationText;

- (void) updateTranslations;

@end
