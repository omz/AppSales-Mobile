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

- (id)initWithName:(NSString *)countryName day:(Day *)aDay
{
	self = [super init];
	if (self) {
		day = [aDay retain];
		name = [countryName retain];
		entries = [NSMutableArray new];
	}
	return self;
}

- (NSArray*) entries {
	return entries;
}

- (NSString *)description
{
	NSMutableDictionary *idToName = [NSMutableDictionary dictionary];
	NSMutableDictionary *salesByID = [NSMutableDictionary dictionary];
	for (Entry *e in self.entries) {
		if (e.isPurchase) {
			NSNumber *unitsOfProduct = [salesByID objectForKey:e.productIdentifier];
			int u = (unitsOfProduct != nil) ? unitsOfProduct.intValue : 0;
			u += e.units;
			[salesByID setObject:[NSNumber numberWithInt:u] forKey:e.productIdentifier];
		}
		[idToName setObject:e.productName forKey:e.productIdentifier];
	}
	NSMutableString *productSummary = [NSMutableString string];
	NSEnumerator *reverseEnum = [[salesByID keysSortedByValueUsingSelector:@selector(compare:)] reverseObjectEnumerator];
    for (NSString *productIdentifier in reverseEnum) {
		NSNumber *productSales = [salesByID objectForKey:productIdentifier];
		[productSummary appendFormat:@"%@ × %@, ", productSales, [idToName objectForKey:productIdentifier]];
	}
	
	const NSUInteger summaryLength = [productSummary length];
	if (summaryLength == 0) {
		return NSLocalizedString(@"no sales",nil);	
	} else if (summaryLength >= 2) {
		[productSummary deleteCharactersInRange:NSMakeRange(summaryLength - 2, 2)];
	}
	
	return productSummary;
}

- (id)initWithCoder:(NSCoder *)coder
{
	self = [super init];
	if (self) {
		day = [[coder decodeObjectForKey:@"day"] retain];
		name = [[coder decodeObjectForKey:@"name"] retain];
		entries = [[coder decodeObjectForKey:@"entries"] retain];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:day forKey:@"day"];
	[coder encodeObject:name forKey:@"name"];
	[coder encodeObject:entries forKey:@"entries"];
}

- (void) addEntry:(Entry*)entry {
	[entries addObject:entry];
}

- (float)totalRevenueInBaseCurrency
{
	float sum = 0.0;
	for (Entry *e in self.entries) {
		sum += [e totalRevenueInBaseCurrency];
	}
	return sum;
}

- (float)totalRevenueInBaseCurrencyForAppWithID:(NSString *)appID {
	if (appID == nil)
		return [self totalRevenueInBaseCurrency];
	float sum = 0.0;
	for (Entry *e in self.entries) {
		if ([e.productIdentifier isEqual:appID])
			sum += [e totalRevenueInBaseCurrency];
	}
	return sum;
}

- (int)totalUnitsForAppWithID:(NSString *)appID {
	if (appID == nil)
		return [self totalUnits];
	int sum = 0;
	for (Entry *e in self.entries) {
		if ((e.isPurchase) && ([e.productIdentifier isEqual:appID]))
			sum += [e units];
	}
	return sum;
}

- (int)totalUnits
{
	int sum = 0;
	for (Entry *e in self.entries) {
		if (e.isPurchase)
			sum += [e units];
	}
	return sum;
}

- (NSArray *)allProductIDs
{
	NSMutableSet *names = [NSMutableSet set];
	for (Entry *e in self.entries) {
		[names addObject:e.productIdentifier];
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

- (NSString *)appIDForApp:(NSString *)appName {
	for (Entry *e in self.entries) {
		if([e.productName isEqualToString:appName])
			return e.productIdentifier;
	}
	return nil;
}

- (void)dealloc
{
	[day release];
	[entries release];
	[name release];
	
	[super dealloc];
}

@end
