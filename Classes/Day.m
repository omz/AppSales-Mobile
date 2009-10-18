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

@implementation Day

@synthesize date;
@synthesize countries;
@synthesize cachedWeekEndDateString;
@synthesize cachedWeekDayColor;
@synthesize cachedDayString;
@synthesize isWeek;
@synthesize wasLoadedFromDisk;
@synthesize name;
@synthesize pathOnDisk;

- (id)init
{
	if (self = [super init]) {
	}
	
	return self;
}

- (id)initWithCSV:(NSString *)csv
{
	[self init];
	
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
			NSString *appId = [columns objectAtIndex:19];
			[[AppIconManager sharedManager] downloadIconForAppID:appId appName:productName];
			if (!self.date) {
				if ((([dateColumn rangeOfString:@"/"].location != NSNotFound) && ([dateColumn length] == 10))
					|| (([dateColumn rangeOfString:@"/"].location == NSNotFound) && ([dateColumn length] == 8))) {
					[self setDateString:dateColumn];
				}
				else {
					NSLog(@"Date is invalid: %@", dateColumn);
					[self release];
					return nil;
				}
			}
			NSString *countryString = [columns objectAtIndex:14];
			if ([countryString length] != 2) {
				NSLog(@"Country code is invalid");
				[self release];
				return nil; //sanity check, country code has to have two characters
			}
			NSString *royaltyCurrency = [columns objectAtIndex:15];
			
			/* Treat in-app purchases as regular purchases for our purposes.
			 * IA1: In-App Purchase
			 * Presumably, IA7: In-App Free Upgrade / Repurchase.
			 */
			if ([transactionType isEqualToString:@"IA1"])
				transactionType = @"1";

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
	return self;
}

static BOOL shouldLoadCountries = YES;

- (id)initWithCoder:(NSCoder *)coder
{
	[self init];
	
	self.date = [coder decodeObjectForKey:@"date"];
	self.isWeek = [coder decodeBoolForKey:@"isWeek"];
	self.name = [coder decodeObjectForKey:@"name"];
	
	/* 
	 * shouldLoadCountries will be set to NO if we're loading via dayFromFile:atPath:
	 * This allows us to skip the costly part of loading until countries is actually accessed, at which
	 * point a new Day object will be loaded from disk at the same path and load its countries. We'll
	 * then assign countries to that Day object's countries.
	 */
	if (shouldLoadCountries)
		self.countries = [coder decodeObjectForKey:@"countries"];
	
	self.wasLoadedFromDisk = YES;
	
	return self;
}

+ (Day *)dayFromFile:(NSString *)filename atPath:(NSString *)docPath;
{
	NSString *fullPath = [docPath stringByAppendingPathComponent:filename];	
	
	shouldLoadCountries = NO;
	Day *loadedDay = [NSKeyedUnarchiver unarchiveObjectWithFile:fullPath];
	shouldLoadCountries = YES;
	loadedDay.pathOnDisk = fullPath;
	
	return loadedDay;
}

- (NSMutableDictionary *)countries
{	
	if (self.pathOnDisk && !countries) {
		if (!countries) {		
			countries = [((Day *)[NSKeyedUnarchiver unarchiveObjectWithFile:self.pathOnDisk]).countries retain];
			self.pathOnDisk = nil;
		}
	}
	return countries;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:self.countries forKey:@"countries"];
	[coder encodeObject:self.date forKey:@"date"];
	[coder encodeBool:self.isWeek forKey:@"isWeek"];
	[coder encodeObject:self.name forKey:@"name"];
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

- (void)setDateString:(NSString *)dateString
{
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
	self.date = [calendar dateFromComponents:components];
}

- (NSString *)description
{
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
	
	if ([productSummary isEqual:@"()"])
		return NSLocalizedString(@"No sales",nil);
	
	return productSummary;
}

- (float)totalRevenueInBaseCurrency
{
	float sum = 0.0;
	for (Country *c in [self.countries allValues]) {
		sum += [c totalRevenueInBaseCurrency];
	}
	return sum;
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
	if (!self.cachedDayString) {
		NSDateComponents *components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit fromDate:self.date];
		self.cachedDayString = [NSString stringWithFormat:@"%i", [components day]];
	}
	return self.cachedDayString;
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
	return @"---";
}

- (UIColor *)weekdayColor
{
	if (!self.cachedWeekDayColor) {
		NSDateComponents *components = [[NSCalendar currentCalendar] components:NSWeekdayCalendarUnit fromDate:self.date];
		int weekday = [components weekday];
		if (weekday == 1) //show sundays in red
			self.cachedWeekDayColor = [UIColor colorWithRed:0.8 green:0.0 blue:0.0 alpha:1.0];
		else
			self.cachedWeekDayColor = [UIColor blackColor];
	}
	return self.cachedWeekDayColor;
}

- (NSString *)weekEndDateString
{
	//The Day class is also used to represent weeks. This returns a formatted date of the day the week ends (7 days after date)
	if (!self.cachedWeekEndDateString) {
		NSDateComponents *comp = [[[NSDateComponents alloc] init] autorelease];
		[comp setHour:167];
		NSDate *dateWeekLater = [[NSCalendar currentCalendar] dateByAddingComponents:comp toDate:self.date options:0];
		NSDateFormatter *dateFormatter = [[NSDateFormatter new] autorelease];
		[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
		[dateFormatter setDateStyle:NSDateFormatterShortStyle];
		self.cachedWeekEndDateString = [dateFormatter stringFromDate:dateWeekLater];
	}
	return self.cachedWeekEndDateString;
}


- (NSArray *)children
{
	NSSortDescriptor *sorter = [[[NSSortDescriptor alloc] initWithKey:@"totalUnits" ascending:NO] autorelease];
	NSArray *sortedChildren = [[self.countries allValues] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sorter]];
	return sortedChildren;
}

- (NSString *)proposedFilename
{
	NSString *dateString = [self.name stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
	if (self.isWeek)
		return [NSString stringWithFormat:@"week_%@.dat", dateString];
	else
		return [NSString stringWithFormat:@"day_%@.dat", dateString];
}

- (void)dealloc
{
	self.cachedDayString = nil;
	self.cachedWeekDayColor = nil;
	self.cachedWeekEndDateString = nil;
	self.countries = nil;
	self.date = nil;
	self.name = nil;
	self.pathOnDisk = nil;
	//self.lock_countries = nil;
	
	[super dealloc];
}

@end
