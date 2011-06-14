//
//  App.h
//  AppSalesMobile
//
//  Created by Ole Zorn on 11.09.09.
//  Copyright 2009 omz:software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Review;

@interface App : NSObject <NSCoding> {
	NSMutableArray *allAppNames;
	NSString *appID;
	NSString *appName;
	NSMutableDictionary *reviewsByUser;
    NSMutableDictionary *lastTimeRegionDownloaded; // mapping of app store to NSDate of last time reviews fetched
	float averageStars;
	float currentStars;
	NSString *currentVersion;
}

@property (readonly) NSString *appID;
@property (readonly) NSString *appName;
@property (readonly) NSString *currentVersion; // the current app version
@property (readonly) NSDictionary *reviewsByUser;
@property (readonly) NSUInteger totalReviewsCount; // all reviews downloaded, for any version (current or old) 
@property (readonly) NSUInteger newReviewsCount;
@property (readonly) NSUInteger currentReviewsCount; // reviews for the current app version  
@property (readonly) NSUInteger newCurrentReviewsCount; // freshly downloaded reviews for the current app version
@property (readonly) NSArray *allAppNames; // current app name, and any previous app names (if different from current)
@property (readonly) float averageStars;
@property (readonly) float currentStars; // average stars for the current app version

- (id) initWithID:(NSString*)identifier name:(NSString*)name;
- (void) addOrReplaceReview:(Review*)review;

- (NSDate*) lastTimeReviewsForStoreWasDownloaded:(NSString*)storeCountryCode;
- (void) setLastTimeReviewsDownloaded:(NSString*)storeCountryCode time:(NSDate*)timeLastDownloaded;

- (void) resetNewReviewCount;

- (void) updateApplicationName:(NSString*)newAppName; // application names can change with new updates

@end
