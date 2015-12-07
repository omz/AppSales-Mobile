//
//  ReportDetailEntry.h
//  AppSales
//
//  Created by Ole Zorn on 26.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Product;

@interface ReportDetailEntry : NSObject

@property (nonatomic, assign) CGFloat revenue;
@property (nonatomic, assign) NSInteger sales;
@property (nonatomic, assign) CGFloat percentage;
@property (nonatomic, strong) NSString *subtitle;
@property (nonatomic, strong) NSString *countryCode;
@property (nonatomic, strong) NSString *countryName;
@property (nonatomic, strong) Product *product;

+ (instancetype)entryWithRevenue:(CGFloat)revenue sales:(NSInteger)sales percentage:(CGFloat)percentage subtitle:(NSString *)subtitle countryCode:(NSString *)countryCode countryName:(NSString *)countryName product:(Product *)product;

@end
