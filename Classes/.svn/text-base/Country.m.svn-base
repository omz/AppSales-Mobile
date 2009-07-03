/*
 Country.m
 AppSalesMobile
 
 * Copyright (c) 2008, omz:software
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the <organization> nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY omz:software ''AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL <copyright holder> BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "Country.h"
#import "CurrencyManager.h"
#import "Entry.h"

@implementation Country

@synthesize name;
@synthesize day;
@synthesize entries;

- (id)initWithName:(NSString *)countryName day:(Day *)aDay
{
	[super init];
	self.day = aDay;
	self.name = countryName;
	self.entries = [NSMutableArray array];
	return self;
}

- (NSString *)description
{
	NSMutableDictionary *salesByProduct = [NSMutableDictionary dictionary];
	for (Entry *e in self.entries) {
		if ([e transactionType] == 1) {
			NSNumber *unitsOfProduct = [salesByProduct objectForKey:[e productName]];
			int u = (unitsOfProduct != nil) ? ([unitsOfProduct intValue]) : 0;
			u += [e units];
			[salesByProduct setObject:[NSNumber numberWithInt:u] forKey:[e productName]];
		}
	}
	NSMutableString *productSummary = [NSMutableString stringWithString:@"("];
	NSEnumerator *reverseEnum = [[salesByProduct keysSortedByValueUsingSelector:@selector(compare:)] reverseObjectEnumerator];
	NSString *productName;
	while (productName = [reverseEnum nextObject]) {
		NSNumber *productSales = [salesByProduct objectForKey:productName];
		[productSummary appendFormat:@"%@ × %@, ", productSales, productName];
	}
	if ([productSummary length] >= 2)
		[productSummary deleteCharactersInRange:NSMakeRange([productSummary length] - 2, 2)];
	[productSummary appendString:@")"];
	
	if ([productSummary isEqual:@"()"])
		return NSLocalizedString(@"No sales",nil);
	
	return productSummary;
}

- (id)initWithCoder:(NSCoder *)coder
{
	[super init];
	self.day = [coder decodeObjectForKey:@"day"];
	self.name = [coder decodeObjectForKey:@"name"];
	self.entries = [coder decodeObjectForKey:@"entries"];
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:self.day forKey:@"day"];
	[coder encodeObject:self.name forKey:@"name"];
	[coder encodeObject:self.entries forKey:@"entries"];
}

- (float)totalRevenueInBaseCurrency
{
	float sum = 0.0;
	for (Entry *e in self.entries) {
		sum += [e totalRevenueInBaseCurrency];
	}
	return sum;
}

- (float)totalRevenueInBaseCurrencyForApp:(NSString *)app
{
	if (app == nil)
		return [self totalRevenueInBaseCurrency];
	float sum = 0.0;
	for (Entry *e in self.entries) {
		if ([e.productName isEqual:app])
			sum += [e totalRevenueInBaseCurrency];
	}
	return sum;
}

- (NSArray *)allProductNames
{
	NSMutableSet *names = [NSMutableSet set];
	for (Entry *e in self.entries) {
		[names addObject:e.productName];
	}
	return [names allObjects];
}

- (NSString *)totalRevenueString
{
	return [[CurrencyManager sharedManager] baseCurrencyDescriptionForAmount:[NSNumber numberWithFloat:[self totalRevenueInBaseCurrency]] withFraction:YES];
}

- (NSArray *)children
{
	NSSortDescriptor *sorter = [[[NSSortDescriptor alloc] initWithKey:@"totalRevenueInBaseCurrency" ascending:NO] autorelease];
	NSArray *sortedChildren = [self.entries sortedArrayUsingDescriptors:[NSArray arrayWithObject:sorter]];
	return sortedChildren;
}

- (void)dealloc
{
	self.day = nil;
	self.entries = nil;
	self.name = nil;
	
	[super dealloc];
}

@end
