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

@interface Review : NSManagedObject

@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSString *countryCode;
@property (nonatomic, strong) NSNumber *rating;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *user;
@property (nonatomic, strong) NSDate *downloadDate;
@property (nonatomic, strong) NSDate *reviewDate;
@property (nonatomic, strong) NSNumber *unread;
@property (nonatomic, strong) Product *product;
@property (nonatomic, strong) NSString *productVersion;

@end
