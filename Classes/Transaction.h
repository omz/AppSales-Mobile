//
//  Transaction.h
//  AppSales
//
//  Created by Ole Zorn on 26.07.11.
//  Copyright (c) 2011 omz:software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Product, Report;

@interface Transaction : NSManagedObject {
@private
}
@property (nonatomic, retain) NSString * countryCode;
@property (nonatomic, retain) NSString * currency;
@property (nonatomic, retain) NSString * promoType;
@property (nonatomic, retain) NSNumber * revenue;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSNumber * units;
@property (nonatomic, retain) Product *product;
@property (nonatomic, retain) Report *report;

@end
