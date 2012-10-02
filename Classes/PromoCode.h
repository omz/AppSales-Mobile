//
//  PromoCode.h
//  AppSales
//
//  Created by Ole Zorn on 14.08.11.
//  Copyright (c) 2011 omz:software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Product;

@interface PromoCode : NSManagedObject {

}

@property (nonatomic, retain) NSString * code;
@property (nonatomic, retain) NSDate * requestDate;
@property (nonatomic, retain) NSNumber * used;
@property (nonatomic, retain) Product *product;

@end
