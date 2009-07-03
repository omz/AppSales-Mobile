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

#import "Entry.h"
#import "Country.h"
#import "CurrencyManager.h"

@implementation Entry

@synthesize country;
@synthesize productName;
@synthesize currency;
@synthesize transactionType;
@synthesize royalties;
@synthesize units;


- (id)initWithProductName:(NSString *)name transactionType:(int)type units:(int)u royalties:(float)r currency:(NSString *)currencyCode country:(Country *)aCountry
{
	[super init];
	self.country = aCountry;
	self.productName = name;
	self.currency = currencyCode;
	self.transactionType = type;
	self.units = u;
	self.royalties = r;
	[country.entries addObject:self];
	return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
	[super init];
	self.country = [coder decodeObjectForKey:@"country"];
	[country.entries addObject:self];
	self.productName = [coder decodeObjectForKey:@"productName"];
	self.currency = [coder decodeObjectForKey:@"currency"];
	self.transactionType = [coder decodeIntForKey:@"transactionType"];
	self.units = [coder decodeIntForKey:@"units"];
	self.royalties = [coder decodeFloatForKey:@"royalties"];
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:self.country forKey:@"country"];
	[coder encodeObject:self.productName forKey:@"productName"];
	[coder encodeObject:self.currency forKey:@"currency"];
	[coder encodeInt:self.transactionType forKey:@"transactionType"];
	[coder encodeInt:self.units forKey:@"units"];
	[coder encodeFloat:self.royalties forKey:@"royalties"];
}


- (float)totalRevenueInBaseCurrency
{
	if (transactionType == 1) {
		float revenueInLocalCurrency = self.royalties * self.units;
		float revenueInBaseCurrency = [[CurrencyManager sharedManager] convertValue:revenueInLocalCurrency fromCurrency:self.currency];
		return revenueInBaseCurrency;
	}
	else {
		return 0.0;
	}
}

- (NSString *)description
{
	if (self.transactionType == 1) {
		NSNumberFormatter *numberFormatter = [[NSNumberFormatter new] autorelease];
		[numberFormatter setMinimumFractionDigits:2];
		[numberFormatter setMaximumFractionDigits:2];
		[numberFormatter setMinimumIntegerDigits:1];
		NSString *royaltiesString = [numberFormatter stringFromNumber:[NSNumber numberWithFloat:self.royalties]];
		NSString *totalRevenueString = [numberFormatter stringFromNumber:[NSNumber numberWithFloat:[self totalRevenueInBaseCurrency]]];
		NSString *royaltiesSumString = [numberFormatter stringFromNumber:[NSNumber numberWithFloat:self.royalties * self.units]];
		
		return [NSString stringWithFormat:@"%@ : %i × %@ %@ = %@ %@ ≈ %@", self.productName, self.units, royaltiesString, self.currency, royaltiesSumString, self.currency, [[CurrencyManager sharedManager] baseCurrencyDescriptionForAmount:totalRevenueString]];
	}
	else {
		return [NSString stringWithFormat:NSLocalizedString(@"%@ : %i free downloads",nil), self.productName, self.units];
	}
}

- (void)dealloc
{
	self.country = nil;
	self.productName = nil;
	self.currency = nil;
	
	[super dealloc];
}



@end
