//
//  App.h
//  AppSalesMobile
//
//  Created by Ole Zorn on 11.09.09.
//  Copyright 2009 omz:software. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface App : NSObject <NSCoding> {
	NSMutableArray *allAppNames;
	NSString *appID;
	NSString *appName;
	NSMutableDictionary *reviewsByUser;
}

@property (nonatomic, retain) NSString *appID;
@property (nonatomic, retain) NSString *appName;
@property (nonatomic, retain) NSMutableArray *allAppNames;
@property (nonatomic, retain) NSMutableDictionary *reviewsByUser;
@property (readonly) int newReviewsCount;

- (float)averageStars;

@end
