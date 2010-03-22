/*
 Day.m
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
#import "Country.h"
#import "Entry.h"
#import "CurrencyManager.h"
#import "AppIconManager.h"
#import "ReportManager.h"

@implementation Day

@synthesize date, countries, isWeek, wasLoadedFromDisk, pathOnDisk, summary, isFault;

- (id)initWithCSV:(NSString *)csv
{
	[super init];
	
	self.wasLoadedFromDisk = NO;	
	self.countries = [NSMutableDictionary dictionary];
	
	NSMutableArray *lines = [[[csv componentsSeparatedByString:@"\n"] mutableCopy] autorelease];
	if ([lines count] > 0)
		[lines removeObjectAtIndex:0];
	if ([lines count] == 0) {
		[self release];
		return nil; //sanity check
	}
	
	for (NSString *line in lines) {
		NSArray *columns = [line componentsSeparatedByString:@"\t"];
		if ([columns count] >= 19) {
			NSString *productName = [columns objectAtIndex:6];
			NSString *transactionType = [columns objectAtIndex:8];
			NSString *units = [columns objectAtIndex:9];
			NSString *royalties = [columns objectAtIndex:10];
			NSString *dateColumn = [columns objectAtIndex:11];
			NSString *toDateColumn = [columns objectAtIndex:12];
			NSString *appId = [columns objectAtIndex:19];
			[[AppIconManager sharedManager] downloadIconForAppID:appId appName:productName];
			if (!self.date) {
				NSDate *fromDate = [self reportDateFromString:dateColumn];
				NSDate *toDate = [self reportDateFromString:toDateColumn];
				if (!fromDate) {
					NSLog(@"Date is invalid: %@", dateColumn);
					[self release];
					return nil;
				} else {
					self.date = fromDate;
					if (![fromDate isEqualToDate:toDate]) {
						self.isWeek = YES;
					}
				}
			}
			NSString *countryString = [columns objectAtIndex:14];
			if ([countryString length] != 2) {
				NSLog(@"Country code is invalid");
				[self release];
				return nil; //sanity check, country code has to have two characters
			}
			NSString *royaltyCurrency = [columns objectAtIndex:15];
			
			//Treat in-app purchases as regular purchases for our purposes.
			//IA1: In-App Purchase
			//IA7: In-App Free Upgrade / Repurchase (?)
			//IA9: In-App Subscription
			if ([transactionType isEqualToString:@"IA1"] || [transactionType isEqualToString:@"IA9"]) transactionType = @"1";
			if ([transactionType isEqualToString:@"IA7"]) transactionType = @"7";
			
			Country *country = [self countryNamed:countryString]; //will be created on-the-fly if needed.
			Entry *entry = [[[Entry alloc] initWithProductName:productName 
								transactionType:[transactionType intValue] 
										  units:[units intValue] 
									  royalties:[royalties floatValue] 
									   currency:royaltyCurrency
										country:country] autorelease]; //gets added to the countries entry list automatically
			entry.productIdentifier = appId;
		}
	}
	[self generateSummary];
	return self;
}

- (void)generateSummary
{
	NSMutableDictionary *revenueByCurrency = [NSMutableDictionary dictionary];
	NSMutableDictionary *salesByApp = [NSMutableDictionary dictionary];
	for (Country *country in [self.countries allValues]) {
		for (Entry *entry in country.entries) {
			if (entry.transactionType == 1) {
				NSNumber *newCount = [NSNumber numberWithInt:[[salesByApp objectForKey:entry.productName] intValue] + entry.units];
				[salesByApp setObject:newCount forKey:entry.productName];
				NSNumber *newRevenue = [NSNumber numberWithFloat:[[revenueByCurrency objectForKey:entry.currency] floatValue] + entry.royalties * entry.units];
				[revenueByCurrency setObject:newRevenue forKey:entry.currency];
			}
		}
	}
	self.summary = [NSDictionary dictionaryWithObjectsAndKeys:
									self.date, kSummaryDate,
									revenueByCurrency, kSummaryRevenue,
									salesByApp, kSummarySales,
									[NSNumber numberWithBool:self.isWeek], kSummaryIsWeek,
									nil];
}

+ (Day *)dayWithSummary:(NSDictionary *)reportSummary
{
	Day *d = [[[Day alloc] init] autorelease];
	d.summary = reportSummary;
	d.date = [reportSummary objectForKey:kSummaryDate];
	d.isWeek = [[reportSummary objectForKey:kSummaryIsWeek] boolValue];
	d.isFault = YES;
	d.wasLoadedFromDisk = YES;
	return d;
}

- (id)initWithCoder:(NSCoder *)coder
{
	[self init];
	self.date = [coder decodeObjectForKey:@"date"];
	self.isWeek = [coder decodeBoolForKey:@"isWeek"];
	self.countries = [coder decodeObjectForKey:@"countries"];
	self.wasLoadedFromDisk = YES;
	
	return self;
}


- (NSMutableDictionary *)countries
{	
	if (isFault) {
		NSString *filename = [self proposedFilename];
		NSString *docPath = [[ReportManager sharedManager] docPath];
		NSString *fullPath = [docPath stringByAppendingPathComponent:filename];
		Day *fulfilledFault = [NSKeyedUnarchiver unarchiveObjectWithFile:fullPath];
		self.countries = fulfilledFault.countries;
		isFault = NO;
	}
	return countries;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:self.countries forKey:@"countries"];
	[coder encodeObject:self.date forKey:@"date"];
	[coder encodeBool:self.isWeek forKey:@"isWeek"];
}

- (Country *)countryNamed:(NSString *)countryName
{
	Country *country = [self.countries objectForKey:countryName];
	if (!country) {
		country = [[[Country alloc] initWithName:countryName day:self] autorelease];
		[self.countries setObject:country forKey:countryName];
	}
	return country;
}

- (NSDate *)reportDateFromString:(NSString *)dateString
{
	if ((([dateString rangeOfString:@"/"].location != NSNotFound) && ([dateString length] == 10))
		|| (([dateString rangeOfString:@"/"].location == NSNotFound) && ([dateString length] == 8))) {
		int year, month, day;
		if ([dateString rangeOfString:@"/"].location == NSNotFound) { //old date format
			year = [[dateString substringWithRange:NSMakeRange(0,4)] intValue];
			month = [[dateString substringWithRange:NSMakeRange(4,2)] intValue];
			day = [[dateString substringWithRange:NSMakeRange(6,2)] intValue];
		}
		else { //new date format
			year = [[dateString substringWithRange:NSMakeRange(6,4)] intValue];
			month = [[dateString substringWithRange:NSMakeRange(0,2)] intValue];
			day = [[dateString substringWithRange:NSMakeRange(3,2)] intValue];
		}
		
		NSCalendar *calendar = [NSCalendar currentCalendar];
		NSDateComponents *components = [[NSDateComponents new] autorelease];
		[components setYear:year];
		[components setMonth:month];
		[components setDay:day];
		
		return [calendar dateFromComponents:components];
	}
	return nil;
}


- (NSString *)description
{
	NSDictionary *salesByProduct = nil;
	if (!self.summary) {
		NSMutableDictionary *salesByProduct = [NSMutableDictionary dictionary];
		for (Country *c in [self.countries allValues]) {
			for (Entry *e in [c entries]) {
				if ([e transactionType] == 1) {
					NSNumber *unitsOfProduct = [salesByProduct objectForKey:[e productName]];
					int u = (unitsOfProduct != nil) ? ([unitsOfProduct intValue]) : 0;
					u += [e units];
					[salesByProduct setObject:[NSNumber numberWithInt:u] forKey:[e productName]];
				}
			}
		}
	} else {
		salesByProduct = [summary objectForKey:kSummarySales];
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
	if ([productSummary isEqual:@"()"]) {
		return NSLocalizedString(@"No sales",nil);
	}
	return productSummary;
}

- (float)totalRevenueInBaseCurrency
{
	if (self.summary) {
		float sum = 0.0;
		NSDictionary *revenueByCurrency = [summary objectForKey:kSummaryRevenue];
		for (NSString *currency in revenueByCurrency) {
			float revenue = [[CurrencyManager sharedManager] convertValue:[[revenueByCurrency objectForKey:currency] floatValue] fromCurrency:currency];
			sum += revenue;
		}
		return sum;
	} else {
		float sum = 0.0;
		for (Country *c in [self.countries allValues]) {
			sum += [c totalRevenueInBaseCurrency];
		}
		return sum;
	}
}

- (float)totalRevenueInBaseCurrencyForApp:(NSString *)app
{
	if (app == nil)
		return [self totalRevenueInBaseCurrency];
	float sum = 0.0;
	for (Country *c in [self.countries allValues]) {
		sum += [c totalRevenueInBaseCurrencyForApp:app];
	}
	return sum;
}

- (int)totalUnitsForApp:(NSString *)app
{
	if (app == nil)
		return [self totalUnits];
	int sum = 0;
	for (Country *c in [self.countries allValues]) {
		sum += [c totalUnitsForApp:app];
	}
	return sum;
}

- (int)totalUnits
{
	int sum = 0;
	for (Country *c in [self.countries allValues]) {
		sum += [c totalUnits];
	}
	return sum;
}

- (NSArray *)allProductNames
{
	NSMutableSet *names = [NSMutableSet set];
	for (Country *c in [self.countries allValues]) {
		[names addObjectsFromArray:[c allProductNames]];
	}
	return [names allObjects];
}

- (NSString *)totalRevenueString
{
	return [[CurrencyManager sharedManager] baseCurrencyDescriptionForAmount:[NSNumber numberWithFloat:[self totalRevenueInBaseCurrency]] withFraction:YES];
}

- (NSString *)dayString
{
	NSDateComponents *components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit fromDate:self.date];
	return [NSString stringWithFormat:@"%i", [components day]];
}

- (NSString *)weekdayString
{
	NSDateComponents *components = [[NSCalendar currentCalendar] components:NSWeekdayCalendarUnit fromDate:self.date];
	int weekday = [components weekday];
	if (weekday == 1)
		return NSLocalizedString(@"SUN",nil);
	if (weekday == 2)
		return NSLocalizedString(@"MON",nil);
	if (weekday == 3)
		return NSLocalizedString(@"TUE",nil);
	if (weekday == 4)
		return NSLocalizedString(@"WED",nil);
	if (weekday == 5)
		return NSLocalizedString(@"THU",nil);
	if (weekday == 6)
		return NSLocalizedString(@"FRI",nil);
	if (weekday == 7)
		return NSLocalizedString(@"SAT",nil);
	return @"N/A";
}

- (UIColor *)weekdayColor
{
	NSDateComponents *components = [[NSCalendar currentCalendar] components:NSWeekdayCalendarUnit fromDate:self.date];
	int weekday = [components weekday];
	if (weekday == 1) {
		return [UIColor colorWithRed:0.8 green:0.0 blue:0.0 alpha:1.0];
	}
	return [UIColor blackColor];
}

- (NSString *)weekEndDateString
{
	NSDateComponents *comp = [[[NSDateComponents alloc] init] autorelease];
	[comp setHour:167];
	NSDate *dateWeekLater = [[NSCalendar currentCalendar] dateByAddingComponents:comp toDate:self.date options:0];
	NSDateFormatter *dateFormatter = [[NSDateFormatter new] autorelease];
	[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
	[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	return [dateFormatter stringFromDate:dateWeekLater];
}


- (NSArray *)children
{
	NSSortDescriptor *sorter = [[[NSSortDescriptor alloc] initWithKey:@"totalUnits" ascending:NO] autorelease];
	NSArray *sortedChildren = [[self.countries allValues] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sorter]];
	return sortedChildren;
}


- (NSString *)proposedFilename
{
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormatter setDateFormat:@"MM_dd_yyyy"];
	NSString *dateString = [dateFormatter stringFromDate:self.date];
	if (self.isWeek) {
		return [NSString stringWithFormat:@"week_%@.dat", dateString];
	} else {
		return [NSString stringWithFormat:@"day_%@.dat", dateString];
	}
}

- (void)dealloc
{
	[countries release];
	[date release];
	[pathOnDisk release];
	[summary release];
	
	[super dealloc];
}

@end
