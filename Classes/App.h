//
//  App.h
//  AppSalesMobile
//
//  Created by Ole Zorn on 11.09.09.
//  Copyright 2009 omz:software. All rights reserved.
//

#import <Foundation/Foundation.h>

NSString* getDocPath(); // utility methods that belong in some other file
NSString* getPrefetchedPath(); 

@class Review;

@interface App : NSObject <NSCoding> {
	NSMutableArray *allAppNames;
	NSString *appID;
	NSString *appName;
	NSMutableDictionary *reviewsByUser;
	float averageStars;
}

@property (readonly) NSString *appID;
@property (readonly) NSString *appName;
@property (readonly) NSDictionary *reviewsByUser;
@property (readonly) NSUInteger newReviewsCount;
@property (readonly) NSArray *allAppNames;
@property (readonly) float averageStars;

- (id) initWithID:(NSString*)identifier name:(NSString*)name;
- (void) addOrReplaceReview:(Review*)review;

- (void) resetNewReviewCount;

- (void) updateApplicationName:(NSString*)newAppName; // application names can change with new updates

@end
