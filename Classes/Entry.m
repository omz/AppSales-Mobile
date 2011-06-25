/*
 Entry.m
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

#import "Day.h"
#import "Entry.h"
#import "Country.h"
#import "CurrencyManager.h"
#import "ReportManager.h"
#import "AppManager.h"

@implementation Entry
@synthesize theCountry;


#define	kS_RowDictionaryCodingKey	@"rowDictionaryCodingKey"
#define	kS_countryCodingKey			@"country"


- (id)initWithRowDictionary:(NSDictionary *)aRowDictionary country:(Country *)aCountry
{
	if( !(self=[super init]) )
	{
		return nil;
	}
	
	rowDictionary	= [aRowDictionary retain];
	theCountry		= [aCountry retain];
	[theCountry addEntry:self]; // self escaping
	return self;
}

- (id)initWithCoder:(NSCoder *)coder 
{
	if( !(self=[super init]) )
	{
		return nil;
	}
	if(     ![coder containsValueForKey:kS_RowDictionaryCodingKey]
        ||  ![coder containsValueForKey:kS_countryCodingKey] )
	{
        JLog(@"Coded values on disk seems to be a old version - should be regenerated");
		return nil;
	}

	rowDictionary	= [[coder decodeObjectForKey:kS_RowDictionaryCodingKey] retain];
	theCountry		= [[coder decodeObjectForKey:kS_countryCodingKey] retain];
	[theCountry addEntry:self]; // self escaping
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:rowDictionary   forKey:kS_RowDictionaryCodingKey];
	[coder encodeObject:theCountry         forKey:kS_countryCodingKey];
}

+ (NSSet *)purchaseProductTypesSet;
{
	static NSSet *purchaseSet = nil;
	
	if( !purchaseSet )
	{
		purchaseSet = [[NSSet setWithObjects:	kS_AppleReport_ProductType_iPhoneAppPurchase,
												kS_AppleReport_ProductType_iPadAppPurchase,
												kS_AppleReport_ProductType_UniveralAppPurchase,
												kS_AppleReport_ProductType_MacAppPurchase,
												kS_AppleReport_ProductType_InAppSubscription,
												nil] retain];		
	}
	return purchaseSet;
}

- (BOOL)isPurchase 
{
	return [[[self class] purchaseProductTypesSet] containsObject:[rowDictionary objectForKey:kS_AppleReport_ProductTypeIdentifier]];
}
- (BOOL)isInAppPurchase
{
	return [[rowDictionary objectForKey:kS_AppleReport_ProductTypeIdentifier] isEqualToString:kS_AppleReport_ProductType_InAppSubscription];
}


- (NSString *)productName
{
	return [rowDictionary objectForKey:kS_AppleReport_Title]; 
}
- (NSString *)productIdentifier
{
	return [rowDictionary objectForKey:kS_AppleReport_AppleIdentifier]; 
}
- (NSString *)currency
{
	return [rowDictionary objectForKey:kS_AppleReport_CurrencyofProceeds]; 
}
- (NSString *)transactionType
{
	return [rowDictionary objectForKey:kS_AppleReport_ProductTypeIdentifier]; 
}
- (float)royalties
{
	return [[rowDictionary objectForKey:kS_AppleReport_DeveloperProceeds] floatValue]; 
}
- (int)units
{
	return [[rowDictionary objectForKey:kS_AppleReport_Units] intValue]; 
}
- (float)customerprice
{
	return [[rowDictionary objectForKey:kS_AppleReport_CustomerPrice] floatValue]; 
}


- (float)totalRevenueInBaseCurrency {
	if (self.isPurchase) {
		float revenueInLocalCurrency = self.royalties * self.units;
		float revenueInBaseCurrency = [[CurrencyManager sharedManager] convertValue:revenueInLocalCurrency fromCurrency:self.currency];
		return revenueInBaseCurrency;
	}
	return 0;
}

- (NSString *)description {
	if (self.isPurchase) {
		NSNumberFormatter *numberFormatter = [[NSNumberFormatter new] autorelease];
		[numberFormatter setMinimumFractionDigits:2];
		[numberFormatter setMaximumFractionDigits:2];
		[numberFormatter setMinimumIntegerDigits:1];
		NSString *royaltiesString = [numberFormatter stringFromNumber:[NSNumber numberWithFloat:self.royalties]];
		NSString *totalRevenueString = [numberFormatter stringFromNumber:[NSNumber numberWithFloat:[self totalRevenueInBaseCurrency]]];
		NSString *royaltiesSumString = [numberFormatter stringFromNumber:[NSNumber numberWithFloat:self.royalties * self.units]];
		
		return [NSString stringWithFormat:@"%@ : %i × %@ %@ = %@ %@ ≈ %@", self.productName, self.units, royaltiesString, 
				self.currency, royaltiesSumString, self.currency, [[CurrencyManager sharedManager] baseCurrencyDescriptionForAmount:totalRevenueString]];
	}
	return [NSString stringWithFormat:NSLocalizedString(@"%@ : %i free downloads",nil), self.productName, self.units];
}

- (void)dealloc 
{
	[rowDictionary release];
	[theCountry release];
	
	[super dealloc];
}



@end
