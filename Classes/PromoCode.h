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

@property (nonatomic, strong) NSString *code;
@property (nonatomic, strong) NSDate *requestDate;
@property (nonatomic, strong) NSNumber *used;
@property (nonatomic, strong) Product *product;

@end
