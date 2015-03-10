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
		
	self.availableCurrencies = [NSArray arrayWithObjects:
								@"USD", @"EUR", 
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
								@"ZAR", nil];
	
	currencySymbols = [[NSDictionary alloc] initWithObjectsAndKeys:@"€", @"EUR", @"$", @"USD", @"¥", @"JPY", @"£", @"GBP", @"₪", @"ILS", nil];
	
	isRefreshing = NO;
	self.baseCurrency = [[NSUserDefaults standardUserDefaults] objectForKey:@"CurrencyManagerBaseCurrency"];
	if (!self.baseCurrency) self.baseCurrency = @"USD";
	
	self.lastRefresh = [[NSUserDefaults standardUserDefaults] objectForKey:@"CurrencyManagerLastRefresh"];
	if (!self.lastRefresh) self.lastRefresh = [NSDate dateWithTimeIntervalSince1970:1225397963]; //Oct, 30, 2008
	
	exchangeRates = [[[NSUserDefaults standardUserDefaults] objectForKey:@"CurrencyManagerExchangeRates"] retain];
	if (!exchangeRates) {
		exchangeRates = [NSMutableDictionary new];
		[exchangeRates setObject:[NSNumber numberWithFloat:0.2178] forKey:@"\"AED/EUR\""];
		[exchangeRates setObject:[NSNumber numberWithFloat:0.5096] forKey:@"\"AUD/EUR\""];
		[exchangeRates setObject:[NSNumber numberWithFloat:2.1227] forKey:@"\"BHD/EUR\""];
		[exchangeRates setObject:[NSNumber numberWithFloat:0.5519] forKey:@"\"BND/EUR\""];
		[exchangeRates setObject:[NSNumber numberWithFloat:0.3351] forKey:@"\"BRL/EUR\""];
		[exchangeRates setObject:[NSNumber numberWithFloat:0.6378] forKey:@"\"CAD/EUR\""];
		[exchangeRates setObject:[NSNumber numberWithFloat:0.6605] forKey:@"\"CHF/EUR\""];
		[exchangeRates setObject:[NSNumber numberWithFloat:0.0012] forKey:@"\"CLP/EUR\""];
		[exchangeRates setObject:[NSNumber numberWithFloat:0.1171] forKey:@"\"CNY/EUR\""];
		[exchangeRates setObject:[NSNumber numberWithFloat:2.0112] forKey:@"\"CYP/EUR\""];
		[exchangeRates setObject:[NSNumber numberWithFloat:0.0389] forKey:@"\"CZK/EUR\""];
		[exchangeRates setObject:[NSNumber numberWithFloat:0.1343] forKey:@"\"DKK/EUR\""];
		[exchangeRates setObject:[NSNumber numberWithFloat:1.0000] forKey:@"\"EUR/EUR\""];
		[exchangeRates setObject:[NSNumber numberWithFloat:1.1968] forKey:@"\"GBP/EUR\""];
		[exchangeRates setObject:[NSNumber numberWithFloat:0.1033] forKey:@"\"HKD/EUR\""];
		[exchangeRates setObject:[NSNumber numberWithFloat:0.0037] forKey:@"\"HUF/EUR\""];
		[exchangeRates setObject:[NSNumber numberWithFloat:0.0001] forKey:@"\"IDR/EUR\""];
		[exchangeRates setObject:[NSNumber numberWithFloat:0.2003] forKey:@"\"ILS/EUR\""];
		[exchangeRates setObject:[NSNumber numberWithFloat:0.0159] forKey:@"\"INR/EUR\""];
		[exchangeRates setObject:[NSNumber numberWithFloat:0.0036] forKey:@"\"ISK/EUR\""];
		[exchangeRates setObject:[NSNumber numberWithFloat:0.0084] forKey:@"\"JPY/EUR\""];
		[exchangeRates setObject:[NSNumber numberWithFloat:0.0006] forKey:@"\"KRW/EUR\""];
		[exchangeRates setObject:[NSNumber numberWithFloat:2.9416] forKey:@"\"KWD/EUR\""];
		[exchangeRates setObject:[NSNumber numberWithFloat:0.0067] forKey:@"\"KZT/EUR\""];
		[exchangeRates setObject:[NSNumber numberWithFloat:0.0073] forKey:@"\"LKR/EUR\""];
		[exchangeRates setObject:[NSNumber numberWithFloat:2.7266] forKey:@"\"MTL/EUR\""];
		[exchangeRates setObject:[NSNumber numberWithFloat:0.0246] forKey:@"\"MUR/EUR\""];
		[exchangeRates setObject:[NSNumber numberWithFloat:0.0592] forKey:@"\"MXN/EUR\""];
		[exchangeRates setObject:[NSNumber numberWithFloat:0.221] forKey:@"\"MYR/EUR\""];
		[exchangeRates setObject:[NSNumber numberWithFloat:0.11335] forKey:@"\"NOK/EUR\""];
		[exchangeRates setObject:[NSNumber numberWithFloat:0.0101] forKey:@"\"NPR/EUR\""];
		[exchangeRates setObject:[NSNumber numberWithFloat:0.4338] forKey:@"\"NZD/EUR\""];
		[exchangeRates setObject:[NSNumber numberWithFloat:2.0786] forKey:@"\"OMR/EUR\""];
		[exchangeRates setObject:[NSNumber numberWithFloat:0.0101] forKey:@"\"PKR/EUR\""];
		[exchangeRates setObject:[NSNumber numberWithFloat:0.2198] forKey:@"\"QAR/EUR\""];
		[exchangeRates setObject:[NSNumber numberWithFloat:0.029] forKey:@"\"RUB/EUR\""];
		[exchangeRates setObject:[NSNumber numberWithFloat:0.2134] forKey:@"\"SAR/EUR\""];
		[exchangeRates setObject:[NSNumber numberWithFloat:0.0978] forKey:@"\"SEK/EUR\""];
		[exchangeRates setObject:[NSNumber numberWithFloat:0.5226] forKey:@"\"SGD/EUR\""];
		[exchangeRates setObject:[NSNumber numberWithFloat:0.0329] forKey:@"\"SKK/EUR\""];
		[exchangeRates setObject:[NSNumber numberWithFloat:0.0228] forKey:@"\"THB/EUR\""];
		[exchangeRates setObject:[NSNumber numberWithFloat:0.024] forKey:@"\"TWD/EUR\""];
		[exchangeRates setObject:[NSNumber numberWithFloat:0.8003] forKey:@"\"USD/EUR\""];
		[exchangeRates setObject:[NSNumber numberWithFloat:0.0764] forKey:@"\"ZAR/EUR\""];
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
	
	[newBaseCurrency retain];
	[baseCurrency release];
	baseCurrency = newBaseCurrency;
	[[NSUserDefaults standardUserDefaults] setObject:baseCurrency forKey:@"CurrencyManagerBaseCurrency"];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:CurrencyManagerDidChangeBaseCurrencyNotification object:self];
}

- (NSString *)baseCurrencyDescription
{
	NSString *currencySymbol = [currencySymbols objectForKey:baseCurrency];
	return (currencySymbol != nil) ? currencySymbol : baseCurrency;
}

- (NSString *)currencySymbolForCurrency:(NSString *)currencyCode
{
	NSString *currencySymbol = [currencySymbols objectForKey:currencyCode];
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
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	NSMutableDictionary *newExchangeRates = [NSMutableDictionary dictionary];

	[newExchangeRates setObject:[NSNumber numberWithFloat:1.0] forKey:@"\"EUR/EUR\""];

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
		[pool release];
		return;
	}
	csv = [csv stringByReplacingOccurrencesOfString:@" to " withString:@"/"];
	NSArray *lines = [csv componentsSeparatedByString:@"\n"];
	for (NSString *line in lines) {
		NSArray *comps = [line componentsSeparatedByString:@","];
		if ([comps count] == 2) {
			NSString *currenciesString = [comps objectAtIndex:0]; //ex: "USD/EUR"
			float exchangeRate = [[comps objectAtIndex:1] floatValue];
			
			[newExchangeRates setObject:[NSNumber numberWithFloat:exchangeRate] forKey:currenciesString];
		}
	}
	if (fabsf([[newExchangeRates objectForKey:@"\"USD/EUR\""] floatValue]) > 9999) {
		//Yes, this could theoretically happen, but more likely, 
		//Yahoo returned bogus values, which apparently does happen every now and then...
		NSLog(@"Exchange rates returned by Yahoo are likely incorrect, ignoring...");
		[self performSelectorOnMainThread:@selector(refreshFailed) withObject:nil waitUntilDone:YES];
		[pool release];
		return;
	}
	[self performSelectorOnMainThread:@selector(finishRefreshWithExchangeRates:) withObject:newExchangeRates waitUntilDone:YES];
	[pool release];
}

- (float)convertValue:(float)sourceValue fromCurrency:(NSString *)sourceCurrency
{
	/* short-circuit if the source is the same as the destination */
	if ([sourceCurrency isEqualToString:self.baseCurrency])
		return sourceValue;

	NSNumber *conversionFromSourceCurrency = [self.conversionDict objectForKey:sourceCurrency];
	float conversionFactor;

	if (conversionFromSourceCurrency) {
		conversionFactor = [conversionFromSourceCurrency floatValue];

	} else {
		/* Convert to euros, our universal common factor */
		NSNumber *conversionRateEuroNumber = [exchangeRates objectForKey:[NSString stringWithFormat:@"\"%@/EUR\"", sourceCurrency]];
		if (!conversionRateEuroNumber) {
			//NSLog(@"Error: Currency code not found or exchange rates not downloaded yet");
			return 0.0;
		}	
		
		conversionFactor = [conversionRateEuroNumber floatValue];
		if (![self.baseCurrency isEqualToString:@"EUR"]) {
			/* If the destination currency isn't euros, convert euros to our destination currency.
			 * The exchangeRates stores X to EUR, so we divide by the conversion rate to go EUR to X.
			 */
			NSNumber *conversionRateBaseCurrencyNumber = [exchangeRates objectForKey:[NSString stringWithFormat:@"\"%@/EUR\"", self.baseCurrency]];
			conversionFactor /= [conversionRateBaseCurrencyNumber floatValue];
		}
		
		/* Cache this conversion for next time */
		[self.conversionDict setObject:[NSNumber numberWithFloat:conversionFactor] forKey:sourceCurrency];
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

- (void)dealloc
{
	self.conversionDict = nil;

	[numberFormatterWithFraction release];
	[numberFormatterWithoutFraction release];
	
	[exchangeRates release];
	[baseCurrency release];
	[currencySymbols release];
	
	[super dealloc];
}

@end
