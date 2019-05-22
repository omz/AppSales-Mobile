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
                                 @"BHD", @"BGN", @"BND", @"BRL",
								 @"CAD", @"CHF", @"CLP", @"CNY", @"COP", @"CZK",
								 @"DKK",
								 @"EGP",
								 @"GBP",
								 @"HKD", @"HRK", @"HUF",
								 @"IDR", @"ILS", @"INR", @"ISK",
								 @"JPY",
								 @"KRW", @"KWD", @"KZT",
								 @"LKR",
								 @"MUR", @"MXN", @"MYR",
								 @"NGN", @"NOK", @"NPR", @"NZD",
								 @"OMR",
								 @"PEN", @"PHP", @"PKR", @"PLN",
								 @"QAR",
								 @"RON", @"RUB",
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
		[exchangeRates setObject:@(0.2400) forKey:@"\"AED/EUR\""];
		[exchangeRates setObject:@(0.6200) forKey:@"\"AUD/EUR\""];
		[exchangeRates setObject:@(2.3800) forKey:@"\"BHD/EUR\""];
        [exchangeRates setObject:@(0.5100) forKey:@"\"BGN/EUR\""];
		[exchangeRates setObject:@(0.6600) forKey:@"\"BND/EUR\""];
		[exchangeRates setObject:@(0.2200) forKey:@"\"BRL/EUR\""];
		[exchangeRates setObject:@(0.6700) forKey:@"\"CAD/EUR\""];
		[exchangeRates setObject:@(0.8900) forKey:@"\"CHF/EUR\""];
		[exchangeRates setObject:@(0.0013) forKey:@"\"CLP/EUR\""];
		[exchangeRates setObject:@(0.1300) forKey:@"\"CNY/EUR\""];
        [exchangeRates setObject:@(0.00027) forKey:@"\"COP/EUR\""];
		[exchangeRates setObject:@(0.0400) forKey:@"\"CZK/EUR\""];
		[exchangeRates setObject:@(0.1344) forKey:@"\"DKK/EUR\""];
		[exchangeRates setObject:@(0.0493) forKey:@"\"EGP/EUR\""];
		[exchangeRates setObject:@(1.0000) forKey:@"\"EUR/EUR\""];
		[exchangeRates setObject:@(1.1300) forKey:@"\"GBP/EUR\""];
		[exchangeRates setObject:@(0.1100) forKey:@"\"HKD/EUR\""];
        [exchangeRates setObject:@(0.1300) forKey:@"\"HRK/EUR\""];
		[exchangeRates setObject:@(0.0031) forKey:@"\"HUF/EUR\""];
		[exchangeRates setObject:@(0.0001) forKey:@"\"IDR/EUR\""];
		[exchangeRates setObject:@(0.2500) forKey:@"\"ILS/EUR\""];
		[exchangeRates setObject:@(0.0130) forKey:@"\"INR/EUR\""];
		[exchangeRates setObject:@(0.0073) forKey:@"\"ISK/EUR\""];
		[exchangeRates setObject:@(0.0081) forKey:@"\"JPY/EUR\""];
		[exchangeRates setObject:@(0.0008) forKey:@"\"KRW/EUR\""];
		[exchangeRates setObject:@(2.9400) forKey:@"\"KWD/EUR\""];
		[exchangeRates setObject:@(0.0024) forKey:@"\"KZT/EUR\""];
		[exchangeRates setObject:@(0.0051) forKey:@"\"LKR/EUR\""];
		[exchangeRates setObject:@(0.0250) forKey:@"\"MUR/EUR\""];
		[exchangeRates setObject:@(0.0470) forKey:@"\"MXN/EUR\""];
		[exchangeRates setObject:@(0.2110) forKey:@"\"MYR/EUR\""];
		[exchangeRates setObject:@(0.0025) forKey:@"\"NGN/EUR\""];
		[exchangeRates setObject:@(0.1000) forKey:@"\"NOK/EUR\""];
		[exchangeRates setObject:@(0.0080) forKey:@"\"NPR/EUR\""];
		[exchangeRates setObject:@(0.5800) forKey:@"\"NZD/EUR\""];
		[exchangeRates setObject:@(2.3300) forKey:@"\"OMR/EUR\""];
        [exchangeRates setObject:@(0.2700) forKey:@"\"PEN/EUR\""];
		[exchangeRates setObject:@(0.0170) forKey:@"\"PHP/EUR\""];
		[exchangeRates setObject:@(0.0059) forKey:@"\"PKR/EUR\""];
        [exchangeRates setObject:@(0.2300) forKey:@"\"PLN/EUR\""];
		[exchangeRates setObject:@(0.2500) forKey:@"\"QAR/EUR\""];
        [exchangeRates setObject:@(0.2100) forKey:@"\"RON/EUR\""];
		[exchangeRates setObject:@(0.0140) forKey:@"\"RUB/EUR\""];
		[exchangeRates setObject:@(0.2400) forKey:@"\"SAR/EUR\""];
		[exchangeRates setObject:@(0.0930) forKey:@"\"SEK/EUR\""];
		[exchangeRates setObject:@(0.6500) forKey:@"\"SGD/EUR\""];
		[exchangeRates setObject:@(0.0280) forKey:@"\"THB/EUR\""];
		[exchangeRates setObject:@(0.1500) forKey:@"\"TRY/EUR\""];
		[exchangeRates setObject:@(0.0280) forKey:@"\"TWD/EUR\""];
		[exchangeRates setObject:@(0.0004) forKey:@"\"TZS/EUR\""];
		[exchangeRates setObject:@(0.9000) forKey:@"\"USD/EUR\""];
		[exchangeRates setObject:@(0.000038) forKey:@"\"VND/EUR\""];
		[exchangeRates setObject:@(0.0620) forKey:@"\"ZAR/EUR\""];
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
		
		NSMutableString *urlString = [NSMutableString stringWithString:@"https://query1.finance.yahoo.com/v7/finance/quote?symbols="];
		int i = 0;
        for (NSString *currency in self.availableCurrencies) {
            if (![currency isEqual:@"EUR"]) {
                if (i > 0) {
                    [urlString appendString:@","];
                }
                
                [urlString appendFormat:@"%@%@=X", currency, @"EUR"];
                i++;
            }
		}
		[urlString appendString:@"&f=nl1&fields=regularMarketPrice,shortName,symbol"];
			
		NSString *json = [NSString stringWithContentsOfURL:[NSURL URLWithString:urlString] usedEncoding:nil error:nil];
		if (!json) {
			[self performSelectorOnMainThread:@selector(refreshFailed) withObject:nil waitUntilDone:YES];
			return;
		}
        // Convert response JSON to NSDictionary
        NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if (dict[@"quoteResponse"] && dict[@"quoteResponse"][@"result"])
        {
            NSArray *results = dict[@"quoteResponse"][@"result"];
            for (NSDictionary *result in results) {
                if (result[@"regularMarketPrice"] && result[@"shortName"])
                {
                    NSString *currenciesString = [NSString stringWithFormat:@"\"%@\"", result[@"shortName"]];
                    float exchangeRate = [result[@"regularMarketPrice"] floatValue];
                    
                    [newExchangeRates setObject:@(exchangeRate) forKey:currenciesString];
                }
            }
            [self performSelectorOnMainThread:@selector(finishRefreshWithExchangeRates:) withObject:newExchangeRates waitUntilDone:YES];
            return;
        }
        
        [self performSelectorOnMainThread:@selector(refreshFailed) withObject:nil waitUntilDone:YES];
        return;
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
