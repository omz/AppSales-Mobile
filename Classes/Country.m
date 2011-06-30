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

@synthesize countryName;
@synthesize day;

- (id)initWithName:(NSString *)aCountryName day:(Day *)aDay
{
	if( !(self = [super init]) )
    {
        return nil;
    }

	day             = [aDay retain];
	countryName     = [aCountryName retain];
	entriesArray    = [NSMutableArray new];

	return self;
}

- (NSArray*) entriesArray {
	return entriesArray;
}

- (NSString *)description
{
	NSMutableDictionary *idToName = [NSMutableDictionary dictionary];
	NSMutableDictionary *salesByID = [NSMutableDictionary dictionary];
	for (Entry *e in self.entriesArray) {
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


#pragma mark Archiving / Unarchiving


#define kS_Archiving_VersionKey			@"v"
#define	kS_Archiving_VersionValue		@"1"
#define	kS_Archiving_DayKey				@"d"
#define	kS_Archiving_NameKey			@"n"
#define	kS_Archiving_EntriesKey			@"e"

- (id)initWithCoder:(NSCoder *)coder
{
	if( !(self = [super init]))
    {
        return nil;
    }
	if(! [[coder decodeObjectForKey:kS_Archiving_VersionKey] isEqualToString:kS_Archiving_VersionValue] )
	{
        JLog(@"Coded values on disk seems to be a old version - should be regenerated");
        [self release];
		return nil;
	}
    
	day          = [[coder decodeObjectForKey:kS_Archiving_DayKey] retain];
	countryName  = [[coder decodeObjectForKey:kS_Archiving_NameKey] retain];
	entriesArray = [[coder decodeObjectForKey:kS_Archiving_EntriesKey] retain];
        
    if( !day || !countryName || !entriesArray || (entriesArray.count < 1) )
    {
        [self release];
        return nil;
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:kS_Archiving_VersionValue	forKey:kS_Archiving_VersionKey];
	[coder encodeObject:day							forKey:kS_Archiving_DayKey];
	[coder encodeObject:countryName					forKey:kS_Archiving_NameKey];
	[coder encodeObject:entriesArray				forKey:kS_Archiving_EntriesKey];
}

- (void) addEntry:(Entry*)entry {
	[entriesArray addObject:entry];
}

- (float)totalRevenueInBaseCurrency
{
	float sum = 0.0;
	for (Entry *e in self.entriesArray) {
		sum += [e totalRevenueInBaseCurrency];
	}
	return sum;
}

- (float)totalRevenueInBaseCurrencyForAppWithID:(NSString *)appID {
	if (appID == nil)
		return [self totalRevenueInBaseCurrency];
	float sum = 0.0;
	for (Entry *e in self.entriesArray) {
		if ([e.productIdentifier isEqual:appID])
			sum += [e totalRevenueInBaseCurrency];
	}
	return sum;
}

- (int)totalUnitsForAppWithID:(NSString *)appID {
	if (appID == nil)
		return [self totalUnits];
	int sum = 0;
	for (Entry *e in self.entriesArray) {
		if ((e.isPurchase) && ([e.productIdentifier isEqual:appID]))
			sum += [e units];
	}
	return sum;
}


- (int)totalUnits
{
	int sum = 0;
	for (Entry *e in self.entriesArray) {
		if (e.isPurchase)
			sum += [e units];
	}
	return sum;
}

- (float)customerPriceForAppWithID:(NSString *)appID {
	if (appID == nil)
		return -1.0;


	for(Entry *e in self.entriesArray) 
	{
		if( [e.productIdentifier isEqualToString:appID] &&  e.isPurchase && !e.promoCode.length )
		{
			return e.customerprice;
		}
	}
	return -1.0;
}


- (NSArray *)allProductIDs
{
	NSMutableSet *names = [NSMutableSet set];
	for (Entry *e in self.entriesArray) {
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
	NSArray *sortedChildren = [self.entriesArray sortedArrayUsingDescriptors:[NSArray arrayWithObject:sorter]];
	return sortedChildren;
}

- (NSString *)appIDForApp:(NSString *)appName {
	for (Entry *e in self.entriesArray) {
		if([e.productName isEqualToString:appName])
			return e.productIdentifier;
	}
	return nil;
}

- (void)dealloc
{
	[day release];
	[entriesArray release];
	[countryName release];
	
	[super dealloc];
}

@end
