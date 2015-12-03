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
@property (nonatomic, strong) NSString *countryCode;
@property (nonatomic, strong) NSString *currency;
@property (nonatomic, strong) NSString *promoType;
@property (nonatomic, strong) NSNumber *revenue;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSNumber *units;
@property (nonatomic, strong) Product *product;
@property (nonatomic, strong) Report *report;

@end
