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
	float recentStars;
	NSString *recentVersion;
}

@property (readonly) NSString *appID;
@property (readonly) NSString *appName;
@property (readonly) NSString *recentVersion; // the current app version
@property (readonly) NSDictionary *reviewsByUser;
@property (readonly) NSUInteger totalReviewsCount; // all reviews downloaded, for any version (current or old) 
@property (readonly) NSUInteger newReviewsCount;
@property (readonly) NSUInteger recentReviewsCount; // reviews for the current app version  
@property (readonly) NSUInteger newRecentReviewsCount; // freshly downloaded reviews for the current app version
@property (readonly) NSArray *allAppNames;
@property (readonly) float averageStars;
@property (readonly) float recentStars; // average stars for the current app version

- (id) initWithID:(NSString*)identifier name:(NSString*)name;
- (void) addOrReplaceReview:(Review*)review;

- (NSDate*) lastTimeReviewsForStoreWasDownloaded:(NSString*)storeCountryCode;
- (void) setLastTimeReviewsDownloaded:(NSString*)storeCountryCode time:(NSDate*)timeLastDownloaded;

- (void) resetNewReviewCount;

- (void) updateApplicationName:(NSString*)newAppName; // application names can change with new updates

@end
