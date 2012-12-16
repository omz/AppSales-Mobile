/*
 CurrencyManager.m
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

#import "CurrencyManager.h"


@implementation CurrencyManager

@synthesize lastRefresh;
@synthesize exchangeRates;
@synthesize availableCurrencies;
@synthesize conversionDict;

- (id)init
{
	if (!(self=[super init])) {
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
								@"THB", @"TWD",			
								@"ZAR"];
	
	currencySymbols = @{@"EUR": @"€", @"USD": @"$", @"JPY": @"¥", @"GBP": @"£", @"ILS": @"₪"};
	
	isRefreshing = NO;
	self.baseCurrency = [[NSUserDefaults standardUserDefaults] objectForKey:@"CurrencyManagerBaseCurrency"];
	if (!self.baseCurrency) self.baseCurrency = @"USD";
	
	self.lastRefresh = [[NSUserDefaults standardUserDefaults] objectForKey:@"CurrencyManagerLastRefresh"];
	if (!self.lastRefresh) self.lastRefresh = [NSDate dateWithTimeIntervalSince1970:1225397963]; //Oct, 30, 2008
	
	exchangeRates = [[NSUserDefaults standardUserDefaults] objectForKey:@"CurrencyManagerExchangeRates"];
	if (!exchangeRates) {
		exchangeRates = [NSMutableDictionary new];
		exchangeRates[@"\"AED to EUR\""] = @0.2178f;
		exchangeRates[@"\"AUD to EUR\""] = @0.5096f;
		exchangeRates[@"\"BHD to EUR\""] = @2.1227f;
		exchangeRates[@"\"BND to EUR\""] = @0.5519f;
		exchangeRates[@"\"BRL to EUR\""] = @0.3351f;
		exchangeRates[@"\"CAD to EUR\""] = @0.6378f;
		exchangeRates[@"\"CHF to EUR\""] = @0.6605f;
		exchangeRates[@"\"CLP to EUR\""] = @0.0012f;
		exchangeRates[@"\"CNY to EUR\""] = @0.1171f;
		exchangeRates[@"\"CYP to EUR\""] = @2.0112f;
		exchangeRates[@"\"CZK to EUR\""] = @0.0389f;
		exchangeRates[@"\"DKK to EUR\""] = @0.1343f;
		exchangeRates[@"\"EUR to EUR\""] = @1.0000f;
		exchangeRates[@"\"GBP to EUR\""] = @1.1968f;
		exchangeRates[@"\"HKD to EUR\""] = @0.1033f;
		exchangeRates[@"\"HUF to EUR\""] = @0.0037f;
		exchangeRates[@"\"IDR to EUR\""] = @0.0001f;
		exchangeRates[@"\"ILS to EUR\""] = @0.2003f;
		exchangeRates[@"\"INR to EUR\""] = @0.0159f;
		exchangeRates[@"\"ISK to EUR\""] = @0.0036f;
		exchangeRates[@"\"JPY to EUR\""] = @0.0084f;
		exchangeRates[@"\"KRW to EUR\""] = @0.0006f;
		exchangeRates[@"\"KWD to EUR\""] = @2.9416f;
		exchangeRates[@"\"KZT to EUR\""] = @0.0067f;
		exchangeRates[@"\"LKR to EUR\""] = @0.0073f;
		exchangeRates[@"\"MTL to EUR\""] = @2.7266f;
		exchangeRates[@"\"MUR to EUR\""] = @0.0246f;
		exchangeRates[@"\"MXN to EUR\""] = @0.0592f;
		exchangeRates[@"\"MYR to EUR\""] = @0.221f;
		exchangeRates[@"\"NOK to EUR\""] = @0.11335f;
		exchangeRates[@"\"NPR to EUR\""] = @0.0101f;
		exchangeRates[@"\"NZD to EUR\""] = @0.4338f;
		exchangeRates[@"\"OMR to EUR\""] = @2.0786f;
		exchangeRates[@"\"PKR to EUR\""] = @0.0101f;
		exchangeRates[@"\"QAR to EUR\""] = @0.2198f;
		exchangeRates[@"\"RUB to EUR\""] = @0.029f;
		exchangeRates[@"\"SAR to EUR\""] = @0.2134f;
		exchangeRates[@"\"SEK to EUR\""] = @0.0978f;
		exchangeRates[@"\"SGD to EUR\""] = @0.5226f;
		exchangeRates[@"\"SKK to EUR\""] = @0.0329f;
		exchangeRates[@"\"THB to EUR\""] = @0.0228f;
		exchangeRates[@"\"TWD to EUR\""] = @0.024f;
		exchangeRates[@"\"USD to EUR\""] = @0.8003f;
		exchangeRates[@"\"ZAR to EUR\""] = @0.0764f;
		[self forceRefresh];
	}

	conversionDict = [NSMutableDictionary new];
		
	return self;
}

- (NSString*) baseCurrency 
{
	return baseCurrency;
}

- (void)setBaseCurrency:(NSString *)newBaseCurrency
{
	[self.conversionDict removeAllObjects];
	
	baseCurrency = newBaseCurrency;
	[[NSUserDefaults standardUserDefaults] setObject:baseCurrency forKey:@"CurrencyManagerBaseCurrency"];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:CurrencyManagerDidChangeBaseCurrencyNotification object:self];
}

- (NSString *)baseCurrencyDescription
{
	NSString *currencySymbol = currencySymbols[baseCurrency];
	return (currencySymbol != nil) ? currencySymbol : baseCurrency;
}

- (NSString *)currencySymbolForCurrency:(NSString *)currencyCode
{
	NSString *currencySymbol = currencySymbols[currencyCode];
	return (currencySymbol != nil) ? currencySymbol : currencyCode;
}

- (NSString *)baseCurrencyDescriptionForAmount:(NSString *)amount
{
	return [NSString stringWithFormat:@"%@%@", [self baseCurrencyDescription], amount];
}

- (NSString *)baseCurrencyDescriptionForAmount:(NSNumber *)amount withFraction:(BOOL)withFraction
{
	NSNumberFormatter *numberFormatter = (withFraction) ? (numberFormatterWithFraction) : (numberFormatterWithoutFraction);
	NSString *formattedAmount = [numberFormatter stringFromNumber:amount];
	return [self baseCurrencyDescriptionForAmount:formattedAmount];
}

- (void)refreshIfNeeded
{
	if (!isRefreshing && ([[NSDate date] timeIntervalSinceDate:self.lastRefresh] > 21600)) { 
		isRefreshing = YES;
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
		[self performSelectorInBackground:@selector(refreshExchangeRates) withObject:nil];
	}
}

- (void)forceRefresh
{
	if (!isRefreshing) {
		isRefreshing = YES;
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
		[self performSelectorInBackground:@selector(refreshExchangeRates) withObject:nil];
	}
}

- (void)refreshFailed
{
	isRefreshing = NO;
	[self.conversionDict removeAllObjects];
	[[NSNotificationCenter defaultCenter] postNotificationName:CurrencyManagerErrorNotification object:self];
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void)finishRefreshWithExchangeRates:(NSMutableDictionary *)newExchangeRates
{
	isRefreshing = NO;
	self.exchangeRates = newExchangeRates;
	self.lastRefresh = [NSDate date];
	[self.conversionDict removeAllObjects];
	
	[[NSUserDefaults standardUserDefaults] setObject:self.exchangeRates forKey:@"CurrencyManagerExchangeRates"];
	[[NSUserDefaults standardUserDefaults] setObject:self.lastRefresh forKey:@"CurrencyManagerLastRefresh"];
	[[NSNotificationCenter defaultCenter] postNotificationName:CurrencyManagerDidUpdateNotification object:self];
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void)refreshExchangeRates
{
	@autoreleasepool {
		NSMutableDictionary *newExchangeRates = [NSMutableDictionary dictionary];
		
		newExchangeRates[@"\"EUR to EUR\""] = @1.0f;
		
		NSMutableString *urlString = [NSMutableString stringWithString:@"http://quote.yahoo.com/d/quotes.csv?s="];
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
			
		NSString *csv = [NSString stringWithContentsOfURL:[NSURL URLWithString:urlString] usedEncoding:NULL error:NULL];
		if (!csv) {
			[self performSelectorOnMainThread:@selector(refreshFailed) withObject:nil waitUntilDone:YES];
			return;
		}
		NSArray *lines = [csv componentsSeparatedByString:@"\n"];
		for (NSString *line in lines) {
			NSArray *comps = [line componentsSeparatedByString:@","];
			if ([comps count] == 2) {
				NSString *currenciesString = comps[0]; //ex: "USD to EUR"
				float exchangeRate = [comps[1] floatValue];
				
				newExchangeRates[currenciesString] = @(exchangeRate);
			}
		}
		if (fabsf([newExchangeRates[@"\"USD to EUR\""] floatValue]) > 9999) {
			//Yes, this could theoretically happen, but more likely, 
			//Yahoo returned bogus values, which apparently does happen every now and then...
			NSLog(@"Exchange rates returned by Yahoo are likely incorrect, ignoring...");
			[self performSelectorOnMainThread:@selector(refreshFailed) withObject:nil waitUntilDone:YES];
			return;
		}
		[self performSelectorOnMainThread:@selector(finishRefreshWithExchangeRates:) withObject:newExchangeRates waitUntilDone:YES];
	}
}

- (float)convertValue:(float)sourceValue fromCurrency:(NSString *)sourceCurrency
{
	/* short-circuit if the source is the same as the destination */
	if ([sourceCurrency isEqualToString:self.baseCurrency])
		return sourceValue;

	NSNumber *conversionFromSourceCurrency = (self.conversionDict)[sourceCurrency];
	float conversionFactor;

	if (conversionFromSourceCurrency) {
		conversionFactor = [conversionFromSourceCurrency floatValue];

	} else {
		/* Convert to euros, our universal common factor */
		NSNumber *conversionRateEuroNumber = exchangeRates[[NSString stringWithFormat:@"\"%@ to EUR\"", sourceCurrency]];
		if (!conversionRateEuroNumber) {
			//NSLog(@"Error: Currency code not found or exchange rates not downloaded yet");
			return 0.0;
		}	
		
		conversionFactor = [conversionRateEuroNumber floatValue];
		if (![self.baseCurrency isEqualToString:@"EUR"]) {
			/* If the destination currency isn't euros, convert euros to our destination currency.
			 * The exchangeRates stores X to EUR, so we divide by the conversion rate to go EUR to X.
			 */
			NSNumber *conversionRateBaseCurrencyNumber = exchangeRates[[NSString stringWithFormat:@"\"%@ to EUR\"", self.baseCurrency]];
			conversionFactor /= [conversionRateBaseCurrencyNumber floatValue];
		}
		
		/* Cache this conversion for next time */
		(self.conversionDict)[sourceCurrency] = @(conversionFactor);
	}
	return (sourceValue * conversionFactor);
}

+ (CurrencyManager *)sharedManager
{
	static CurrencyManager *sharedManager = nil;
	if (sharedManager == nil)
		sharedManager = [CurrencyManager new];
	return sharedManager;
}


@end
