/*
 CurrencyManager.m
 AppSalesMobile
 
 * Copyright (c) 2008, omz:software
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *	 * Redistributions of source code must retain the above copyright
 *	   notice, this list of conditions and the following disclaimer.
 *	 * Redistributions in binary form must reproduce the above copyright
 *	   notice, this list of conditions and the following disclaimer in the
 *	   documentation and/or other materials provided with the distribution.
 *	 * Neither the name of the <organization> nor the
 *	   names of its contributors may be used to endorse or promote products
 *	   derived from this software without specific prior written permission.
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

#import "CurrencyManager.h"


@implementation CurrencyManager

@synthesize lastRefresh;
@synthesize exchangeRates;
@synthesize availableCurrencies;
@synthesize conversionDict;

- (instancetype)init {
	if (!(self = [super init])) {
		return nil;
	}
	
	numberFormatterWithFraction = [NSNumberFormatter new];
	[numberFormatterWithFraction setMinimumFractionDigits:2];
	[numberFormatterWithFraction setMaximumFractionDigits:2];
	[numberFormatterWithFraction setMinimumIntegerDigits:1];
	
	numberFormatterWithoutFraction = [NSNumberFormatter new];
	[numberFormatterWithoutFraction setMinimumFractionDigits:0];
	[numberFormatterWithoutFraction setMaximumFractionDigits:0];
	[numberFormatterWithoutFraction setMinimumIntegerDigits:1];
		
	self.availableCurrencies = @[@"USD", @"EUR",
								 @"AED", @"AUD",
								 @"BHD", @"BND", @"BRL",
								 @"CAD", @"CHF", @"CLP", @"CNY", @"CZK",
								 @"DKK",
								 @"GBP",
								 @"HUF", @"HKD",
								 @"IDR", @"ILS", @"INR", @"ISK",
								 @"JPY",
								 @"KRW", @"KWD", @"KZT",
								 @"LKR",
								 @"MUR", @"MXN", @"MYR",
								 @"NOK", @"NPR", @"NZD",
								 @"OMR",
								 @"PKR",
								 @"QAR",
								 @"RUB",
								 @"SAR", @"SEK", @"SGD",
								 @"THB", @"TRY", @"TWD",
								 @"ZAR"];
	
	currencySymbols = @{@"EUR": @"€",
						@"USD": @"$",
						@"JPY": @"¥",
						@"GBP": @"£",
						@"ILS": @"₪"};
	
	isRefreshing = NO;
	self.baseCurrency = [[NSUserDefaults standardUserDefaults] objectForKey:@"CurrencyManagerBaseCurrency"];
	if (!self.baseCurrency) self.baseCurrency = @"USD";
	
	self.lastRefresh = [[NSUserDefaults standardUserDefaults] objectForKey:@"CurrencyManagerLastRefresh"];
	if (!self.lastRefresh) self.lastRefresh = [NSDate dateWithTimeIntervalSince1970:1225397963]; // Oct 30, 2008
	
	exchangeRates = [[NSUserDefaults standardUserDefaults] objectForKey:@"CurrencyManagerExchangeRates"];
	if (!exchangeRates) {
		exchangeRates = [NSMutableDictionary new];
		[exchangeRates setObject:@(0.242829) forKey:@"\"AED/EUR\""];
		[exchangeRates setObject:@(0.631788) forKey:@"\"AUD/EUR\""];
		[exchangeRates setObject:@(2.36573) forKey:@"\"BHD/EUR\""];
		[exchangeRates setObject:@(0.634964) forKey:@"\"BND/EUR\""];
		[exchangeRates setObject:@(0.228870) forKey:@"\"BRL/EUR\""];
		[exchangeRates setObject:@(0.639934) forKey:@"\"CAD/EUR\""];
		[exchangeRates setObject:@(0.905730) forKey:@"\"CHF/EUR\""];
		[exchangeRates setObject:@(0.00125179) forKey:@"\"CLP/EUR\""];
		[exchangeRates setObject:@(0.135733) forKey:@"\"CNY/EUR\""];
		[exchangeRates setObject:@(1.70860) forKey:@"\"CYP/EUR\""];
		[exchangeRates setObject:@(0.0369449) forKey:@"\"CZK/EUR\""];
		[exchangeRates setObject:@(0.133990) forKey:@"\"DKK/EUR\""];
		[exchangeRates setObject:@(1.0000) forKey:@"\"EUR/EUR\""];
		[exchangeRates setObject:@(1.28771) forKey:@"\"GBP/EUR\""];
		[exchangeRates setObject:@(0.114475) forKey:@"\"HKD/EUR\""];
		[exchangeRates setObject:@(0.00321362) forKey:@"\"HUF/EUR\""];
		[exchangeRates setObject:@(0.0000651) forKey:@"\"IDR/EUR\""];
		[exchangeRates setObject:@(0.229208) forKey:@"\"ILS/EUR\""];
		[exchangeRates setObject:@(0.0131144) forKey:@"\"INR/EUR\""];
		[exchangeRates setObject:@(0.00695861) forKey:@"\"ISK/EUR\""];
		[exchangeRates setObject:@(0.00773167) forKey:@"\"JPY/EUR\""];
		[exchangeRates setObject:@(0.000739939) forKey:@"\"KRW/EUR\""];
		[exchangeRates setObject:@(2.97282) forKey:@"\"KWD/EUR\""];
		[exchangeRates setObject:@(0.00249111) forKey:@"\"KZT/EUR\""];
		[exchangeRates setObject:@(0.00619831) forKey:@"\"LKR/EUR\""];
		[exchangeRates setObject:@(2.32937) forKey:@"\"MTL/EUR\""];
		[exchangeRates setObject:@(0.0250685) forKey:@"\"MUR/EUR\""];
		[exchangeRates setObject:@(0.0475557) forKey:@"\"MXN/EUR\""];
		[exchangeRates setObject:@(0.213494) forKey:@"\"MYR/EUR\""];
		[exchangeRates setObject:@(0.103968) forKey:@"\"NOK/EUR\""];
		[exchangeRates setObject:@(0.00820824) forKey:@"\"NPR/EUR\""];
		[exchangeRates setObject:@(0.590547) forKey:@"\"NZD/EUR\""];
		[exchangeRates setObject:@(2.31784) forKey:@"\"OMR/EUR\""];
		[exchangeRates setObject:@(0.00854538) forKey:@"\"PKR/EUR\""];
		[exchangeRates setObject:@(0.245013) forKey:@"\"QAR/EUR\""];
		[exchangeRates setObject:@(0.0114155) forKey:@"\"RUB/EUR\""];
		[exchangeRates setObject:@(0.237926) forKey:@"\"SAR/EUR\""];
		[exchangeRates setObject:@(0.105716) forKey:@"\"SEK/EUR\""];
		[exchangeRates setObject:@(0.635250) forKey:@"\"SGD/EUR\""];
		[exchangeRates setObject:@(0.0331939) forKey:@"\"SKK/EUR\""];
		[exchangeRates setObject:@(0.0251129) forKey:@"\"THB/EUR\""];
		[exchangeRates setObject:@(0.302758) forKey:@"\"TRY/EUR\""];
		[exchangeRates setObject:@(0.0266770) forKey:@"\"TWD/EUR\""];
		[exchangeRates setObject:@(0.892245) forKey:@"\"USD/EUR\""];
		[exchangeRates setObject:@(0.0550936) forKey:@"\"ZAR/EUR\""];
		[self forceRefresh];
	}

	conversionDict = [NSMutableDictionary new];
		
	return self;
}

- (NSString *)baseCurrency  {
	return baseCurrency;
}

- (void)setBaseCurrency:(NSString *)newBaseCurrency {
	[self.conversionDict removeAllObjects];
	
	baseCurrency = newBaseCurrency;
	[[NSUserDefaults standardUserDefaults] setObject:baseCurrency forKey:@"CurrencyManagerBaseCurrency"];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:CurrencyManagerDidChangeBaseCurrencyNotification object:self];
}

- (NSString *)baseCurrencyDescription {
	NSString *currencySymbol = currencySymbols[baseCurrency];
	return currencySymbol ?: baseCurrency;
}

- (NSString *)currencySymbolForCurrency:(NSString *)currencyCode {
	NSString *currencySymbol = currencySymbols[currencyCode];
	return currencySymbol ?: currencyCode;
}

- (NSString *)baseCurrencyDescriptionForAmount:(NSString *)amount {
	return [NSString stringWithFormat:@"%@%@", [self baseCurrencyDescription], amount];
}

- (NSString *)baseCurrencyDescriptionForAmount:(NSNumber *)amount withFraction:(BOOL)withFraction {
	NSNumberFormatter *numberFormatter = withFraction ? numberFormatterWithFraction : numberFormatterWithoutFraction;
	NSString *formattedAmount = [numberFormatter stringFromNumber:amount];
	return [self baseCurrencyDescriptionForAmount:formattedAmount];
}

- (void)refreshIfNeeded {
	if (!isRefreshing && ([[NSDate date] timeIntervalSinceDate:self.lastRefresh] > 21600)) { 
		isRefreshing = YES;
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
		[self performSelectorInBackground:@selector(refreshExchangeRates) withObject:nil];
	}
}

- (void)forceRefresh {
	if (!isRefreshing) {
		isRefreshing = YES;
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
		[self performSelectorInBackground:@selector(refreshExchangeRates) withObject:nil];
	}
}

- (void)refreshFailed {
	isRefreshing = NO;
	[self.conversionDict removeAllObjects];
	[[NSNotificationCenter defaultCenter] postNotificationName:CurrencyManagerErrorNotification object:self];
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void)finishRefreshWithExchangeRates:(NSMutableDictionary *)newExchangeRates {
	isRefreshing = NO;
	self.exchangeRates = newExchangeRates;
	self.lastRefresh = [NSDate date];
	[self.conversionDict removeAllObjects];
	
	[[NSUserDefaults standardUserDefaults] setObject:self.exchangeRates forKey:@"CurrencyManagerExchangeRates"];
	[[NSUserDefaults standardUserDefaults] setObject:self.lastRefresh forKey:@"CurrencyManagerLastRefresh"];
	[[NSNotificationCenter defaultCenter] postNotificationName:CurrencyManagerDidUpdateNotification object:self];
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void)refreshExchangeRates {
	@autoreleasepool {
		NSMutableDictionary *newExchangeRates = [NSMutableDictionary dictionary];
		
		[newExchangeRates setObject:@(1.0) forKey:@"\"EUR/EUR\""];
		
		NSMutableString *urlString = [NSMutableString stringWithString:@"https://download.finance.yahoo.com/d/quotes.csv?s="];
		int i = 0;
		for (NSString *currency in self.availableCurrencies) {
			if (i > 0) {
				[urlString appendString:@"+"];
			}
			if (![currency isEqual:@"EUR"]) {
				[urlString appendFormat:@"%@%@=X", currency, @"EUR"];
			}
			i++;
		}
		[urlString appendString:@"&f=nl1"];
			
		NSString *csv = [NSString stringWithContentsOfURL:[NSURL URLWithString:urlString] usedEncoding:nil error:nil];
		if (!csv) {
			[self performSelectorOnMainThread:@selector(refreshFailed) withObject:nil waitUntilDone:YES];
			return;
		}
		csv = [csv stringByReplacingOccurrencesOfString:@" to " withString:@"/"];
		NSArray *lines = [csv componentsSeparatedByString:@"\n"];
		for (NSString *line in lines) {
			NSArray *comps = [line componentsSeparatedByString:@","];
			if ([comps count] == 2) {
				NSString *currenciesString = comps[0]; // ex: "USD/EUR"
				float exchangeRate = [comps[1] floatValue];
				
				[newExchangeRates setObject:@(exchangeRate) forKey:currenciesString];
			}
		}
		if (fabsf([newExchangeRates[@"\"USD/EUR\""] floatValue]) > 9999) {
			// Yes, this could theoretically happen, but more likely,
			// Yahoo returned bogus values, which apparently does happen every now and then...
			NSLog(@"Exchange rates returned by Yahoo are likely incorrect, ignoring...");
			[self performSelectorOnMainThread:@selector(refreshFailed) withObject:nil waitUntilDone:YES];
			return;
		}
		[self performSelectorOnMainThread:@selector(finishRefreshWithExchangeRates:) withObject:newExchangeRates waitUntilDone:YES];
	}
}

- (float)convertValue:(float)sourceValue fromCurrency:(NSString *)sourceCurrency {
	/* short-circuit if the source is the same as the destination */
	if ([sourceCurrency isEqualToString:self.baseCurrency])
		return sourceValue;

	NSNumber *conversionFromSourceCurrency = self.conversionDict[sourceCurrency];
	float conversionFactor;

	if (conversionFromSourceCurrency) {
		conversionFactor = [conversionFromSourceCurrency floatValue];

	} else {
		/* Convert to euros, our universal common factor */
		NSNumber *conversionRateEuroNumber = exchangeRates[[NSString stringWithFormat:@"\"%@/EUR\"", sourceCurrency]];
		if (!conversionRateEuroNumber) {
			//NSLog(@"Error: Currency code not found or exchange rates not downloaded yet");
			return 0.0;
		}	
		
		conversionFactor = [conversionRateEuroNumber floatValue];
		if (![self.baseCurrency isEqualToString:@"EUR"]) {
			/* If the destination currency isn't euros, convert euros to our destination currency.
			 * The exchangeRates stores X to EUR, so we divide by the conversion rate to go EUR to X.
			 */
			NSNumber *conversionRateBaseCurrencyNumber = exchangeRates[[NSString stringWithFormat:@"\"%@/EUR\"", self.baseCurrency]];
			conversionFactor /= [conversionRateBaseCurrencyNumber floatValue];
		}
		
		/* Cache this conversion for next time */
		[self.conversionDict setObject:@(conversionFactor) forKey:sourceCurrency];
	}
	return (sourceValue * conversionFactor);
}

+ (CurrencyManager *)sharedManager {
	static CurrencyManager *sharedManager = nil;
	if (sharedManager == nil)
		sharedManager = [CurrencyManager new];
	return sharedManager;
}


@end
