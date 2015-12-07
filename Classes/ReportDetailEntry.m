//
//  ReportDetailEntry.m
//  AppSales
//
//  Created by Ole Zorn on 26.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "ReportDetailEntry.h"
#import "Product.h"

@implementation ReportDetailEntry

+ (instancetype)entryWithRevenue:(CGFloat)revenue sales:(NSInteger)sales percentage:(CGFloat)percentage subtitle:(NSString *)subtitle countryCode:(NSString *)countryCode countryName:(NSString *)countryName product:(Product *)product {
	ReportDetailEntry *entry = [[self alloc] init];
	entry.revenue = revenue;
	entry.sales = sales;
	entry.percentage = percentage;
	entry.subtitle = subtitle;
	entry.countryCode = countryCode;
	entry.countryName = countryName;
	entry.product = product;
	return entry;
}

@end
