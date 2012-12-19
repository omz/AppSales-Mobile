//
//  Review.h
//  AppSales
//
//  Created by Ole Zorn on 27.07.11.
//  Copyright (c) 2011 omz:software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Product;

@interface Review : NSManagedObject {
@private
}
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSString * countryCode;
@property (nonatomic, retain) NSNumber * rating;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * user;
@property (nonatomic, retain) NSDate * downloadDate;
@property (nonatomic, retain) NSDate * reviewDate;
@property (nonatomic, retain) NSNumber * unread;
@property (nonatomic, retain) Product *product;
@property (nonatomic, retain) NSString *productVersion;

@end
