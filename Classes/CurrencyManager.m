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
								 @"EGP",
								 @"GBP",
								 @"HUF", @"HKD",
								 @"IDR", @"ILS", @"INR", @"ISK",
								 @"JPY",
								 @"KRW", @"KWD", @"KZT",
								 @"LKR",
								 @"MUR", @"MXN", @"MYR",
								 @"NGN", @"NOK", @"NPR", @"NZD",
								 @"OMR",
								 @"PHP", @"PKR",
								 @"QAR",
								 @"RUB",
								 @"SAR", @"SEK", @"SGD",
								 @"THB", @"TRY", @"TWD", @"TZS",
								 @"VND",
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
		[exchangeRates setObject:@(0.2553) forKey:@"\"AED/EUR\""];
		[exchangeRates setObject:@(0.7045) forKey:@"\"AUD/EUR\""];
		[exchangeRates setObject:@(2.4866) forKey:@"\"BHD/EUR\""];
		[exchangeRates setObject:@(0.6595) forKey:@"\"BND/EUR\""];
		[exchangeRates setObject:@(0.2812) forKey:@"\"BRL/EUR\""];
		[exchangeRates setObject:@(0.7137) forKey:@"\"CAD/EUR\""];
		[exchangeRates setObject:@(0.9282) forKey:@"\"CHF/EUR\""];
		[exchangeRates setObject:@(0.0014) forKey:@"\"CLP/EUR\""];
		[exchangeRates setObject:@(0.1359) forKey:@"\"CNY/EUR\""];
		[exchangeRates setObject:@(0.0370) forKey:@"\"CZK/EUR\""];
		[exchangeRates setObject:@(0.1344) forKey:@"\"DKK/EUR\""];
		[exchangeRates setObject:@(0.0493) forKey:@"\"EGP/EUR\""];
		[exchangeRates setObject:@(1.0000) forKey:@"\"EUR/EUR\""];
		[exchangeRates setObject:@(1.1911) forKey:@"\"GBP/EUR\""];
		[exchangeRates setObject:@(0.1210) forKey:@"\"HKD/EUR\""];
		[exchangeRates setObject:@(0.0031) forKey:@"\"HUF/EUR\""];
		[exchangeRates setObject:@(0.0001) forKey:@"\"IDR/EUR\""];
		[exchangeRates setObject:@(0.2458) forKey:@"\"ILS/EUR\""];
		[exchangeRates setObject:@(0.0139) forKey:@"\"INR/EUR\""];
		[exchangeRates setObject:@(0.0084) forKey:@"\"ISK/EUR\""];
		[exchangeRates setObject:@(0.0081) forKey:@"\"JPY/EUR\""];
		[exchangeRates setObject:@(0.0008) forKey:@"\"KRW/EUR\""];
		[exchangeRates setObject:@(3.0646) forKey:@"\"KWD/EUR\""];
		[exchangeRates setObject:@(0.0028) forKey:@"\"KZT/EUR\""];
		[exchangeRates setObject:@(0.0063) forKey:@"\"LKR/EUR\""];
		[exchangeRates setObject:@(0.0259) forKey:@"\"MUR/EUR\""];
		[exchangeRates setObject:@(0.0459) forKey:@"\"MXN/EUR\""];
		[exchangeRates setObject:@(0.2110) forKey:@"\"MYR/EUR\""];
		[exchangeRates setObject:@(0.0030) forKey:@"\"NGN/EUR\""];
		[exchangeRates setObject:@(0.1108) forKey:@"\"NOK/EUR\""];
		[exchangeRates setObject:@(0.0087) forKey:@"\"NPR/EUR\""];
		[exchangeRates setObject:@(0.6774) forKey:@"\"NZD/EUR\""];
		[exchangeRates setObject:@(2.4336) forKey:@"\"OMR/EUR\""];
		[exchangeRates setObject:@(0.0188) forKey:@"\"PHP/EUR\""];
		[exchangeRates setObject:@(0.0089) forKey:@"\"PKR/EUR\""];
		[exchangeRates setObject:@(0.2572) forKey:@"\"QAR/EUR\""];
		[exchangeRates setObject:@(0.0152) forKey:@"\"RUB/EUR\""];
		[exchangeRates setObject:@(0.2478) forKey:@"\"SAR/EUR\""];
		[exchangeRates setObject:@(0.1019) forKey:@"\"SEK/EUR\""];
		[exchangeRates setObject:@(0.6591) forKey:@"\"SGD/EUR\""];
		[exchangeRates setObject:@(0.0262) forKey:@"\"THB/EUR\""];
		[exchangeRates setObject:@(0.2706) forKey:@"\"TRY/EUR\""];
		[exchangeRates setObject:@(0.0295) forKey:@"\"TWD/EUR\""];
		[exchangeRates setObject:@(0.0004) forKey:@"\"TZS/EUR\""];
		[exchangeRates setObject:@(0.9383) forKey:@"\"USD/EUR\""];
		[exchangeRates setObject:@(0.00004) forKey:@"\"VND/EUR\""];
		[exchangeRates setObject:@(0.0680) forKey:@"\"ZAR/EUR\""];
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
