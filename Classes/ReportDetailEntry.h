//
//  ReportDetailEntry.h
//  AppSales
//
//  Created by Ole Zorn on 26.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Product;

@interface ReportDetailEntry : NSObject {
	
	float revenue;
	float percentage;
	NSString *subtitle;
	NSString *country;
	Product *product;
}

@property (nonatomic, assign) float revenue;
@property (nonatomic, assign) float percentage;
@property (nonatomic, strong) NSString *subtitle;
@property (nonatomic, strong) NSString *country;
@property (nonatomic, strong) Product *product;

+ (instancetype)entryWithRevenue:(float)r percentage:(float)p subtitle:(NSString *)aSubtitle country:(NSString *)countryCode product:(Product *)aProduct;

@end