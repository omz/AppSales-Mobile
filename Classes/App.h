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


@interface App : NSObject <NSCoding> {

	NSString *appID;
	NSString *appName;
	NSMutableDictionary *reviewsByUser;
	int newReviewsCount;
}

@property (nonatomic, retain) NSString *appID;
@property (nonatomic, retain) NSString *appName;
@property (nonatomic, retain) NSMutableDictionary *reviewsByUser;
@property (assign) int newReviewsCount;

- (float)averageStars;

@end
