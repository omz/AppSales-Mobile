//
//  Review.h
//  AppSalesMobile
//
//  Created by Ole Zorn on 11.09.09.
//  Copyright 2009 omz:software. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Review : NSObject {

	NSString *user;
	NSString *title;
	int stars;
	NSDate *reviewDate;
	NSDate *downloadDate;
	NSString *text;
	NSString *version;
	NSString *countryCode;
}

@property (nonatomic, retain) NSString *user;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSDate *reviewDate;
@property (nonatomic, retain) NSDate *downloadDate;
@property (nonatomic, retain) NSString *text;
@property (nonatomic, assign) int stars;
@property (nonatomic, retain) NSString *version;
@property (nonatomic, retain) NSString *countryCode;

@end
