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

@synthesize revenue, percentage, subtitle, country, product;

+ (id)entryWithRevenue:(float)r percentage:(float)p subtitle:(NSString *)aSubtitle country:(NSString *)countryCode product:(Product *)aProduct
{
	ReportDetailEntry *entry = [[[self alloc] init] autorelease];
	entry.revenue = r;
	entry.percentage = p;
	entry.subtitle = aSubtitle;
	entry.country = countryCode;
	entry.product = aProduct;
	return entry;
}

- (void)dealloc
{
	[subtitle release];
	[country release];
	[product release];
	[super dealloc];
}

@end