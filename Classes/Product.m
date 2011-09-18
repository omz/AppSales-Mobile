//
//  Product.m
//  AppSales
//
//  Created by Ole Zorn on 19.07.11.
//  Copyright (c) 2011 omz:software. All rights reserved.
//

#import "Product.h"
#import "ASAccount.h"
#import "UIColor+Extensions.h"

@implementation Product

@synthesize isDownloadingPromoCodes;

@dynamic name;
@dynamic platform;
@dynamic productID;
@dynamic reviewSummary;
@dynamic color;
@dynamic account;
@dynamic reviews;
@dynamic transactions;
@dynamic hidden;
@dynamic customName;
@dynamic SKU;
@dynamic parentSKU;
@dynamic currentVersion;
@dynamic lastModified;
@dynamic promoCodes;

- (void)awakeFromInsert
{
	[super awakeFromInsert];
	self.color = [UIColor randomColor];
}

- (NSString *)displayName
{
	if (self.customName && ![self.customName isEqualToString:@""]) {
		return self.customName;
	}
	return [NSString stringWithFormat:@"%@ (%@)", self.name, self.platform];
}

- (NSString *)defaultDisplayName
{
	return [NSString stringWithFormat:@"%@ (%@)", self.name, self.platform];
}

@end
