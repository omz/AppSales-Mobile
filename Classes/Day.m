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

static BOOL parseDateString(NSString *dateString, int *year, int *month, int *day) {
	if ([dateString rangeOfString:@"/"].location == NSNotFound) {
		if (dateString.length == 8) { //old date format
			*year = [[dateString substringWithRange:NSMakeRange(0,4)] intValue];
			*month = [[dateString substringWithRange:NSMakeRange(4,2)] intValue];
			*day = [[dateString substringWithRange:NSMakeRange(6,2)] intValue];
			return YES; // parsed ok
		}
	} else if (dateString.length == 10) { //new date format
		*year = [[dateString substringWithRange:NSMakeRange(6,4)] intValue];
		*month = [[dateString substringWithRange:NSMakeRange(0,2)] intValue];
		*day = [[dateString substringWithRange:NSMakeRange(3,2)] intValue];
		return YES;
	}
	return NO; // unrecognized string
}

@interface Day (private) // used by class factory methods
- (void) setPathOnDisk:(NSString*)path;
@end


@implementation Day

@synthesize date;
@synthesize countries;
@synthesize isWeek;
@synthesize name;

- (id)initWithCSV:(NSString *)csv
{
	[self init];
		
	countries = [[NSMutableDictionary alloc] init];
	
	NSMutableArray *lines = [[[csv componentsSeparatedByString:@"\n"] mutableCopy] autorelease];
	if (lines.count == 0) { //sanity check
		NSLog(@"unrecognized CSV text %@", csv);
		[self release];
		return nil;
	}
	[lines removeObjectAtIndex:0];
	
	for (NSString *line in lines) {
		NSArray *columns = [line componentsSeparatedByString:@"\t"];
		if ([columns count] >= 19) {
			NSString *productName = [columns objectAtIndex:6];
			NSString *transactionType = [columns objectAtIndex:8];
			NSString *units = [columns objectAtIndex:9];
			NSString *royalties = [columns objectAtIndex:10];
			NSString *dateStartColumn = [columns objectAtIndex:11];
			NSString *dateEndColumn = [columns objectAtIndex:12];
			NSString *appId = [columns objectAtIndex:19];
			[[AppIconManager sharedManager] downloadIconForAppID:appId];
			isWeek = ![dateStartColumn isEqualToString:dateEndColumn];
			
			int startYear, startMonth, startDay;
			// not storing the end date, but we'll verify it's in the format we expect
			if (! parseDateString(dateStartColumn, &startYear, &startMonth, &startDay)) {
				NSLog(@"start date is invalid: %@", dateEndColumn);
				[self release];
				return nil;				
			}
			
			int endYear, endMonth, endDay;
			if (! parseDateString(dateEndColumn, &endYear, &endMonth, &endDay)) {
				NSLog(@"end date is invalid: %@", dateEndColumn);
				[self release];
				return nil;
			}
			
			int nameYear, nameMonth, nameDay;
			NSCalendar *calendar = [NSCalendar currentCalendar];
			NSDateComponents *components = [[NSDateComponents new] autorelease];
			if (isWeek) { // weeks use their ending period as the 'name', just as iTunes Connect does
				nameYear = endYear;
				nameMonth = endMonth;
				nameDay = endDay;
			} else {
				nameYear = startYear;
				nameMonth = startMonth;
				nameDay = startDay;				
			}
			[components setYear:nameYear];
			[components setMonth:nameMonth];
			[components setDay:nameDay];
			date = [[calendar dateFromComponents:components] retain];
			name = [[NSString alloc] initWithFormat:@"%02d/%02d/%d", nameMonth, nameDay, nameYear];	

			
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
			[[[Entry alloc] initWithProductIdentifier:appId
												 name:productName 
									  transactionType:[transactionType intValue] 
												units:[units intValue] 
											royalties:[royalties floatValue] 
											 currency:royaltyCurrency
											  country:country] autorelease]; //gets added to the countries entry list automatically
		}
	}
	return self;
}

static BOOL shouldLoadCountries = YES;

- (id)initWithCoder:(NSCoder *)coder
{
	[self init];
	
	date = [[coder decodeObjectForKey:@"date"] retain];
	name = [[coder decodeObjectForKey:@"name"] retain];
	isWeek = [coder decodeBoolForKey:@"isWeek"];
	
	/* 
	 * shouldLoadCountries will be set to NO if we're loading via dayFromFile:atPath:
	 * This allows us to skip the costly part of loading until countries is actually accessed, at which
	 * point a new Day object will be loaded from disk at the same path and load its countries. We'll
	 * then assign countries to that Day object's countries.
	 */
	if (shouldLoadCountries) {
		countries = [[coder decodeObjectForKey:@"countries"] retain];
	}
	
	return self;
}

- (id) initAsAllOfTime { //  not intended to be used by anyone except TotalController
	NSSortDescriptor *dateSorter = [[[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO] autorelease];
	NSArray *sortedDays = [[[ReportManager sharedManager].days allValues] sortedArrayUsingDescriptors:[NSArray arrayWithObject:dateSorter]];
	NSArray *sortedWeeks = [[[ReportManager sharedManager].weeks allValues] sortedArrayUsingDescriptors:[NSArray arrayWithObject:dateSorter]];
	if (sortedWeeks.count == 0) {
		[self dealloc];
		return nil;
	}

	self = [self init];
	if (self) {		
		Day *latestWeek = [sortedWeeks objectAtIndex:0];
		
		countries = [[NSMutableDictionary alloc] init];
		isWeek = TRUE;
		name = cachedWeekEndDateString = @"total";
		date = [latestWeek.date retain];
		
		NSDate *startOfDay = [date addTimeInterval:(24*7-1)*3600];
		NSMutableArray *additionalDays = [NSMutableArray array];
		for (Day *d in sortedDays) {
			if ([d.date compare:startOfDay] == NSOrderedDescending) {
				[additionalDays addObject:d];
			}
		}
		
		if (sortedDays.count > 0) {
			[date release];
			date = [[[sortedDays objectAtIndex:0] date] retain];
		}
		
		NSArray *days = [sortedWeeks arrayByAddingObjectsFromArray:additionalDays];
		for (Day *w in days) {
			for (Country *c in [w.countries allValues]) {
				Country *country = [self countryNamed:c.name];
				Entry *totalEntry = nil;
				
				for (Entry *e in c.entries) {
					for (Entry *totalE in country.entries) {
						if ([e.productName isEqualToString:totalE.productName] &&
							e.royalties == totalE.royalties &&
							e.transactionType == totalE.transactionType) {
							totalEntry = totalE;
							break;
						}
					}
					if (totalEntry == nil) {
						[[[Entry alloc] initWithProductIdentifier:e.productIdentifier 
															name:e.productName 
												 transactionType:e.transactionType 
														   units:e.units 
													   royalties:e.royalties
														currency:e.currency
														  country:country] autorelease];
					} else {
						totalEntry.units += e.units;
						totalEntry = nil;
					}
				}
			}
		}
	}
	return self;
}

+ (Day *)dayFromFile:(NSString *)filename atPath:(NSString *)docPath; // serialized data 
{
	NSString *fullPath = [docPath stringByAppendingPathComponent:filename];
	
	shouldLoadCountries = NO;
	Day *loadedDay = [NSKeyedUnarchiver unarchiveObjectWithFile:fullPath];
	loadedDay.pathOnDisk = fullPath;
	shouldLoadCountries = YES;
	
	return loadedDay;
}

+ (Day *)dayFromCSVFile:(NSString *)filename atPath:(NSString *)docPath;
{
	NSString *fullPath = [docPath stringByAppendingPathComponent:filename];	
	
	Day *loadedDay = [[Day alloc] initWithCSV:[NSString stringWithContentsOfFile:fullPath encoding:NSUTF8StringEncoding error:nil]];
	loadedDay.pathOnDisk = fullPath;
	
	return [loadedDay autorelease];
}


- (NSMutableDictionary *)countries
{	
	if (pathOnDisk && !countries) {
		countries = [((Day *)[NSKeyedUnarchiver unarchiveObjectWithFile:pathOnDisk]).countries retain];
		[self setPathOnDisk:nil];
	}
	return countries;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:self.countries forKey:@"countries"];
	[coder encodeObject:self.date forKey:@"date"];
	[coder encodeObject:self.name forKey:@"name"];
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

- (void) setPathOnDisk:(NSString *)path {
	[path retain];
	[pathOnDisk release];
	pathOnDisk = path;
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

- (float)totalRevenueInBaseCurrencyForAppID:(NSString *)app
{
	if (app == nil)
		return [self totalRevenueInBaseCurrency];
	float sum = 0.0;
	for (Country *c in [self.countries allValues]) {
		sum += [c totalRevenueInBaseCurrencyForAppID:app];
	}
	return sum;
}

- (int)totalUnitsForAppID:(NSString *)appID
{
	if (appID == nil)
		return [self totalUnits];
	int sum = 0;
	for (Country *c in [self.countries allValues]) {
		sum += [c totalUnitsForAppID:appID];
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

- (NSArray *)allProductIDs
{
	NSMutableSet *names = [NSMutableSet set];
	for (Country *c in [self.countries allValues]) {
		[names addObjectsFromArray:[c allProductIDs]];
	}
	return [names allObjects];
}

- (NSString *)totalRevenueString
{
	return [[CurrencyManager sharedManager] baseCurrencyDescriptionForAmount:[NSNumber numberWithFloat:[self totalRevenueInBaseCurrency]] withFraction:YES];
}

- (NSString *)dayString
{
	if (!cachedDayString) {
		NSDateComponents *components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit fromDate:self.date];
		cachedDayString = [[NSString alloc] initWithFormat:@"%i", [components day]];
	}
	return cachedDayString;
}

- (NSString *)weekdayString
{
	NSDateComponents *components = [[NSCalendar currentCalendar] components:NSWeekdayCalendarUnit fromDate:self.date];
	switch ([components weekday]) {
		case 1:
			return NSLocalizedString(@"SUN",nil);
		case 2:
			return NSLocalizedString(@"MON",nil);
		case 3:
			return NSLocalizedString(@"TUE",nil);
		case 4:
			return NSLocalizedString(@"WED",nil);
		case 5:
			return NSLocalizedString(@"THU",nil);
		case 6:
			return NSLocalizedString(@"FRI",nil);
		case 7:
			return NSLocalizedString(@"SAT",nil);			
	}
	@throw [NSException exceptionWithName:@"unknown weekday" reason:[self.date description] userInfo:nil];
}

- (UIColor *)weekdayColor
{
	if (!cachedWeekDayColor) {
		NSDateComponents *components = [[NSCalendar currentCalendar] components:NSWeekdayCalendarUnit fromDate:self.date];
		int weekday = [components weekday];
		if (weekday == 1) //show sundays in red
			cachedWeekDayColor = [[UIColor colorWithRed:0.8 green:0.0 blue:0.0 alpha:1.0] retain];
		else
			cachedWeekDayColor = [[UIColor blackColor] retain];
	}
	return cachedWeekDayColor;
}

- (NSString *)weekEndDateString
{
	//The Day class is also used to represent weeks. This returns a formatted date of the day the week ends (7 days after date)
	if (!cachedWeekEndDateString) {
		NSDateComponents *comp = [[[NSDateComponents alloc] init] autorelease];
		[comp setHour:167];
		NSDate *dateWeekLater = [[NSCalendar currentCalendar] dateByAddingComponents:comp toDate:self.date options:0];
		NSDateFormatter *dateFormatter = [[NSDateFormatter new] autorelease];
		[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
		[dateFormatter setDateStyle:NSDateFormatterShortStyle];
		cachedWeekEndDateString = [[dateFormatter stringFromDate:dateWeekLater] retain];
	}
	return cachedWeekEndDateString;
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
	[cachedDayString release];
	[cachedWeekDayColor release];
	[cachedWeekEndDateString release];
	[countries release];
	[date release];
	[name release];
	[pathOnDisk release];
	
	[super dealloc];
}

@end
