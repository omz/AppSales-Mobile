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

static BOOL containsOnlyWhiteSpace(NSArray* array) {
	NSCharacterSet *charSet = [NSCharacterSet whitespaceCharacterSet];
	for (NSString *string in array) {
		for (int i = string.length - 1; i >= 0; i--) {
			if (! [charSet characterIsMember:[string characterAtIndex:i]]) {
				return NO;
			}
		}
	}
	return YES;
}

static BOOL parseDateString(NSString *dateString, int *year, int *month, int *day) {
	if ([dateString rangeOfString:@"/"].location == NSNotFound) {
		if (dateString.length == 8) { // old date format
			*year = [[dateString substringWithRange:NSMakeRange(0,4)] intValue];
			*month = [[dateString substringWithRange:NSMakeRange(4,2)] intValue];
			*day = [[dateString substringWithRange:NSMakeRange(6,2)] intValue];
			return YES; // parsed ok
		}
	} else if (dateString.length == 10) { // new date format
		*year = [[dateString substringWithRange:NSMakeRange(6,4)] intValue];
		*month = [[dateString substringWithRange:NSMakeRange(0,2)] intValue];
		*day = [[dateString substringWithRange:NSMakeRange(3,2)] intValue];
		return YES;
	}
	return NO; // unrecognized string
}


@implementation Day

@synthesize date;
@synthesize countries;
@synthesize isWeek;
@synthesize name;

- (id)initWithCSV:(NSString *)csv
{
	[self init];
		
	countries = [[NSMutableDictionary alloc] init];
	
	NSArray *lines = [csv componentsSeparatedByString:@"\n"];
	if (lines.count == 0) {
		NSLog(@"unrecognized CSV text: %@", csv);
		[self release];
		return nil;
	}
	lines = [lines subarrayWithRange:NSMakeRange(1, lines.count-1)];
	
	for (NSString *line in lines) {
		NSArray *columns = [line componentsSeparatedByString:@"\t"];
		if (containsOnlyWhiteSpace(columns)) {
			continue;
		}
		if (columns.count < 19) {
			NSLog(@"unknown column format: %@", columns.description); // instead should stop parsing and return nil?
			continue;
		}
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
		if (! parseDateString(dateStartColumn, &startYear, &startMonth, &startDay)) {
			NSLog(@"invalid startDate: %@", dateStartColumn);
			[self release];
			return nil;
		}
		
		int endYear, endMonth, endDay;
		if (! parseDateString(dateEndColumn, &endYear, &endMonth, &endDay)) {
			NSLog(@"invalid endDate: %@", dateEndColumn);
			[self release];
			return nil;
		}
		
		NSCalendar *calendar = [NSCalendar currentCalendar];
		NSDateComponents *components = [[NSDateComponents new] autorelease];
		[components setYear:startYear];
		[components setMonth:startMonth];
		[components setDay:startDay];
		date = [[calendar dateFromComponents:components] retain];
		name = [[NSString alloc] initWithFormat:@"%02d/%02d/%d", startMonth, startDay, startYear];
		weekEndDateString = [[NSString alloc] initWithFormat:@"%02d/%02d/%d", endMonth, endDay, endYear];

		NSString *countryString = [columns objectAtIndex:14];
		if (countryString.length != 2) { // country code has two characters
			[NSException raise:@"invalid country code" format:countryString];
		}
		NSString *royaltyCurrency = [columns objectAtIndex:15];
		
		/* Treat in-app purchases as regular purchases for our purposes.
		 * IA1: In-App Purchase
		 * Presumably, IA7: In-App Free Upgrade / Repurchase.
		 */
		if ([transactionType isEqualToString:@"IA1"]) {
			transactionType = @"1";
		}

		Country *country = [self countryNamed:countryString]; // will be created on-the-fly if needed.
		[[[Entry alloc] initWithProductIdentifier:appId
											 name:productName 
								  transactionType:[transactionType intValue] 
											units:[units intValue] 
										royalties:[royalties floatValue] 
										 currency:royaltyCurrency
										  country:country] release]; // gets added to the countries entry list automatically
	}
	if (name == nil || date == nil) {
		NSLog(@"coulnd't parse CSV: %@", csv);
		[self release];
		return nil;
	}
	return self;
}

- (id) initAsAllOfTime { // not intended to be used by anyone except TotalController
	NSSortDescriptor *dateSorter = [[[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO] autorelease];
	NSArray *sortingDescriptors = [NSArray arrayWithObject:dateSorter];
	NSArray *sortedDays = [[ReportManager sharedManager].days.allValues sortedArrayUsingDescriptors:sortingDescriptors];
	NSArray *sortedWeeks = [[ReportManager sharedManager].weeks.allValues sortedArrayUsingDescriptors:sortingDescriptors];
	if (sortedWeeks.count == 0) { // no data has been downloaded yet
		[self dealloc];
		return nil;
	}

	self = [self init];
	if (self) {		
		Day *latestWeek = [sortedWeeks objectAtIndex:0];
		
		countries = [[NSMutableDictionary alloc] init];
		isWeek = TRUE;
		name = weekEndDateString = @"total";
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
			for (Country *c in w.countries.allValues) {
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
														  country:country] release];
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

- (id)initWithCoder:(NSCoder *)coder
{
	if ([self init]) {
		name = [[coder decodeObjectForKey:@"name"] retain];
		date = [[coder decodeObjectForKey:@"date"] retain];
		countries = [[coder decodeObjectForKey:@"countries"] retain];
		isWeek = [coder decodeBoolForKey:@"isWeek"];
		
		// lazily computed values, which may be nil
		dayString = [[coder decodeObjectForKey:@"dayString"] retain];
		weekEndDateString = [[coder decodeObjectForKey:@"weekEndDateString"] retain];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:self.name forKey:@"name"];
	[coder encodeObject:self.date forKey:@"date"];
	[coder encodeObject:self.countries forKey:@"countries"];
	[coder encodeBool:self.isWeek forKey:@"isWeek"];
	
	[coder encodeObject:self.dayString forKey:@"dayString"];
	[coder encodeObject:self.weekEndDateString forKey:@"weekEndDateString"];
}

+ (Day *)dayFromFile:(NSString *)filename atPath:(NSString *)docPath; // serialized data 
{
	NSString *fullPath = [docPath stringByAppendingPathComponent:filename];	
	return [NSKeyedUnarchiver unarchiveObjectWithFile:fullPath];
}

+ (Day *)dayFromCSVFile:(NSString *)filename atPath:(NSString *)docPath;
{
	NSString *fullPath = [docPath stringByAppendingPathComponent:filename];
	Day *loadedDay = [[Day alloc] initWithCSV:[NSString stringWithContentsOfFile:fullPath encoding:NSUTF8StringEncoding error:nil]];	
	return [loadedDay autorelease];
}

- (BOOL) archiveToDocumentPathIfNeeded:(NSString*)docPath {
	NSFileManager *manager = [NSFileManager defaultManager];
	NSString *fullPath = [docPath stringByAppendingPathComponent:[self proposedFilename]];
	BOOL isDirectory = false;
	if ([manager fileExistsAtPath:fullPath isDirectory:&isDirectory]) {
		if (isDirectory) {
			[NSException raise:@"found unexpected directory at Day path" format:fullPath];
		}
		return FALSE;
	}
	// hasn't been arhived yet, write it out now
	[NSKeyedArchiver archiveRootObject:self toFile:fullPath];
	return YES;
}

- (Country *)countryNamed:(NSString *)countryName
{
	Country *country = [self.countries objectForKey:countryName];
	if (!country) {
		country = [[Country alloc] initWithName:countryName day:self];
		[self.countries setObject:country forKey:countryName];
		[country release];
	}
	return country;
}

- (NSString *)description
{
	NSMutableDictionary *salesByProduct = [NSMutableDictionary dictionary];
	for (Country *c in self.countries.allValues) {
		for (Entry *e in c.entries) {
			if (e.transactionType == 1) {
				NSNumber *unitsOfProduct = [salesByProduct objectForKey:[e productName]];
				int u = (unitsOfProduct != nil) ? (unitsOfProduct.intValue) : 0;
				u += e.units;
				[salesByProduct setObject:[NSNumber numberWithInt:u] forKey:e.productName];
			}
		}
	}
	NSMutableString *productSummary = [NSMutableString stringWithString:@"("];
	NSEnumerator *reverseEnum = [[salesByProduct keysSortedByValueUsingSelector:@selector(compare:)] reverseObjectEnumerator];
	NSString *productName;
	while (productName = reverseEnum.nextObject) {
		NSNumber *productSales = [salesByProduct objectForKey:productName];
		[productSummary appendFormat:@"%@ × %@, ", productSales, productName];
	}
	if (productSummary.length >= 2)
		[productSummary deleteCharactersInRange:NSMakeRange(productSummary.length - 2, 2)];
	[productSummary appendString:@")"];
	
	if ([productSummary isEqual:@"()"])
		return NSLocalizedString(@"No sales",nil);
	
	return productSummary;
}

- (float)totalRevenueInBaseCurrency
{
	float sum = 0;
	for (Country *c in self.countries.allValues) {
		sum += [c totalRevenueInBaseCurrency];
	}
	return sum;
}

- (float)totalRevenueInBaseCurrencyForAppID:(NSString *)app
{
	if (app == nil) {
		// FIXME this behavior is strange and may indicate a mistake by the caller
		// should instead throw an exception
		return [self totalRevenueInBaseCurrency];
	}
	float sum = 0;
	for (Country *c in self.countries.allValues) {
		sum += [c totalRevenueInBaseCurrencyForAppID:app];
	}
	return sum;
}

- (int)totalUnitsForAppID:(NSString *)appID
{
	if (appID == nil) {
		// FIXME: instead throw an exception
		return [self totalUnits];
	}
	int sum = 0;
	for (Country *c in self.countries.allValues) {
		sum += [c totalUnitsForAppID:appID];
	}
	return sum;
}

- (int)totalUnits
{
	int sum = 0;
	for (Country *c in self.countries.allValues) {
		sum += c.totalUnits;
	}
	return sum;
}

- (NSArray *)allProductIDs
{
	NSMutableSet *names = [NSMutableSet set];
	for (Country *c in self.countries.allValues) {
		[names addObjectsFromArray:c.allProductIDs];
	}
	return names.allObjects;
}

- (NSString *)totalRevenueString
{
	return [[CurrencyManager sharedManager] baseCurrencyDescriptionForAmount:
			[NSNumber numberWithFloat:self.totalRevenueInBaseCurrency] withFraction:YES];
}

- (NSString *)dayString
{
	if (!dayString) {
		NSDateComponents *components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit fromDate:self.date];
		dayString = [[NSString alloc] initWithFormat:@"%i", [components day]];
	}
	return dayString;
}

- (NSString *)weekdayString
{
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormatter setDateFormat:@"EEE"];
	return [[dateFormatter stringFromDate:self.date] uppercaseString];
}

- (UIColor *)weekdayColor
{
	if (!weekDayColor) {
		NSDateComponents *components = [[NSCalendar currentCalendar] components:NSWeekdayCalendarUnit fromDate:self.date];
		int weekday = [components weekday];
		if (weekday == 1) { // show sundays in red
			weekDayColor = [[UIColor colorWithRed:0.8 green:0.0 blue:0.0 alpha:1.0] retain];
		} else {
			weekDayColor = [[UIColor blackColor] retain];
		}
	}
	return weekDayColor;
}

- (NSString *)weekEndDateString
{
	return weekEndDateString;
}


- (NSArray *)children
{
	NSSortDescriptor *sorter = [[[NSSortDescriptor alloc] initWithKey:@"totalUnits" ascending:NO] autorelease];
	NSArray *sortedChildren = [self.countries.allValues sortedArrayUsingDescriptors:[NSArray arrayWithObject:sorter]];
	return sortedChildren;
}

- (NSString *)proposedFilename
{
	if (proposedFileName == nil) {
		NSString *dateString = [self.name stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
		if (self.isWeek) {
			proposedFileName = [[NSString alloc] initWithFormat:@"week_%@.dat", dateString];
		} else {
			proposedFileName = [[NSString alloc] initWithFormat:@"day_%@.dat", dateString];
		}
	}
	return proposedFileName;
}

- (void)dealloc
{
	[name release];
	[date release];
	[countries release];

	[dayString release];
	[weekEndDateString release];

	[weekDayString release];
	[weekDayColor release];
	[proposedFileName release];
	
	[super dealloc];
}

@end
