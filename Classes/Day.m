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
#import "App.h"
#import "Country.h"
#import "Entry.h"
#import "CurrencyManager.h"
#import "AppIconManager.h"
#import "ReportManager.h"
#import "AppManager.h"
#import "NSData+Compression.h"
#import "NSDateFormatter+SharedInstances.h"

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

static NSDate* reportDateFromString(NSString *dateString) {
    const NSUInteger stringLength = dateString.length;
    const NSRange slashRange = [dateString rangeOfString:@"/"];
    int year, month, day;
	if (slashRange.location == NSNotFound && stringLength == 8) {
        //old date format
        year = [dateString substringWithRange:NSMakeRange(0,4)].intValue;
        month = [dateString substringWithRange:NSMakeRange(4,2)].intValue;
        day = [dateString substringWithRange:NSMakeRange(6,2)].intValue;
    } else if (slashRange.location != NSNotFound && stringLength == 10) {
        // new date format
        year = [dateString substringWithRange:NSMakeRange(6,4)].intValue;
        month = [dateString substringWithRange:NSMakeRange(0,2)].intValue;
        day = [dateString substringWithRange:NSMakeRange(3,2)].intValue;
    } else {
        NSLog(@"unknown date format: %@", dateString);
        return nil;
    }
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [[NSDateComponents new] autorelease];
    [components setYear:year];
    [components setMonth:month];
    [components setDay:day];
    
    return [calendar dateFromComponents:components];
}



@implementation Day

@synthesize date, countries, isWeek, wasLoadedFromDisk, summary, isFault;

+ (Day *)dayWithData:(NSData *)dayData compressed:(BOOL)compressed {
	NSString *text = nil;
	if (compressed) {
		NSData *uncompressedData = [dayData gzipInflate];
		text = [[NSString alloc] initWithData:uncompressedData encoding:NSUTF8StringEncoding];
	} else {
		text = [[NSString alloc] initWithData:dayData encoding:NSUTF8StringEncoding];
	}
	Day *day = [[[Day alloc] initWithCSV:text] autorelease];
	[text release];
	return day;
}



+ (NSDate*) adjustDateToLocalTimeZone:(NSDate *)inDate
{
    /* All dates should be set to midnight. If set otherwise, they were created in a different time zone.
     * We want the date corresponding to that midnight; using NSCalendar directly would give us the date in 
     * our local time zone.
     */
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSHourCalendarUnit
                                               fromDate:inDate];
    NSInteger hour = components.hour;
    if (hour) {
        NSCalendar *otherCal = [NSCalendar currentCalendar];
        otherCal.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:[NSTimeZone defaultTimeZone].secondsFromGMT + hour*60*60];
        
        /* Get the day/month/year as seen in the original time zone */
        components = [otherCal components:(NSDayCalendarUnit | NSMonthCalendarUnit| NSYearCalendarUnit)
                                 fromDate:inDate];
        
        /* Now set to the date with that day/month/year in our own time zone */
        return [calendar dateFromComponents:components];
    } else {
        return inDate;
    }
}


- (id)initWithCSV:(NSString *)csv
{
	[super init];
	
	wasLoadedFromDisk = NO;	
	countries = [[NSMutableDictionary alloc] init];
    
    NSMutableArray *lines = [[[csv componentsSeparatedByString:@"\n"] mutableCopy] autorelease];
	if ([lines count] == 0) {
		[self release];
		return nil; // sanity check
	}
    
    const NSUInteger numColumns = [[lines objectAtIndex:0] componentsSeparatedByString:@"\t"].count;
    [lines removeObjectAtIndex:0]; // remove column header
	
	NSCharacterSet *whitespaceCharacterSet = [NSCharacterSet whitespaceCharacterSet];
    
	for (NSString *line in lines) {
		NSArray *columns = [line componentsSeparatedByString:@"\t"];
		if (containsOnlyWhiteSpace(columns)) {
			continue;
		}
        NSString *productName;
        NSString *transactionType;
        NSString *units;
        NSString *royalties;
        NSString *dateColumn;
        NSString *toDateColumn;
        NSString *appId;
        NSString *parentID;
        NSString *countryString;
        NSString *royaltyCurrency;

		if ((numColumns == 18) || (numColumns == 20)) {
            // Sept 2010 format (18), Feb 2011 format (20)
            productName = [columns objectAtIndex:4];
            transactionType = [columns objectAtIndex:6];
            units = [columns objectAtIndex:7];
            royalties = [columns objectAtIndex:8];
            dateColumn = [[columns objectAtIndex:9] stringByTrimmingCharactersInSet:whitespaceCharacterSet];
            toDateColumn = [[columns objectAtIndex:10] stringByTrimmingCharactersInSet:whitespaceCharacterSet];
            countryString = [columns objectAtIndex:12];
            royaltyCurrency = [columns objectAtIndex:13];
            appId = [columns objectAtIndex:14];
            parentID = [columns objectAtIndex:17];
        } else if (numColumns > 19) {
            // old format	
            productName = [columns objectAtIndex:6];
            transactionType = [columns objectAtIndex:8];
            units = [columns objectAtIndex:9];
            royalties = [columns objectAtIndex:10];
            dateColumn = [[columns objectAtIndex:11] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            toDateColumn = [[columns objectAtIndex:12] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            countryString = [columns objectAtIndex:14];
            royaltyCurrency = [columns objectAtIndex:15];
            appId = [columns objectAtIndex:18];
            parentID = (([columns count] >= 27) ? [columns objectAtIndex:26] : nil);
        } else {
            NSLog(@"unknown CSV format: columns %d - %@", numColumns, line);
            [self release];
			self = nil;
            return self;
        }
			
        [[AppIconManager sharedManager] downloadIconForAppID:appId];
        NSDate *fromDate = reportDateFromString(dateColumn);
        NSDate *toDate = reportDateFromString(toDateColumn);
        if (!fromDate) {
            NSLog(@"Date is invalid: %@", dateColumn);
            [self release];
			self = nil;
            return self;
        } else {
//            date = [[Day adjustDateToLocalTimeZone:fromDate] retain];
            date = [fromDate retain];
            if (![fromDate isEqualToDate:toDate]) {
                isWeek = YES;
            }
        }
        if ([countryString length] != 2) {
            NSLog(@"Country code is invalid: %@", countryString);
            [self release];
			self = nil;
            return self; //sanity check, country code has to have two characters
        }
        
        //Treat in-app purchases as regular purchases for our purposes.
        //IA1: In-App Purchase
        //IA7: In-App Free Upgrade / Repurchase (?)
        //IA9: In-App Subscription
		//F1: Mac Purchase
		//F7: Mac Update ??? //TODO: Verify this, the iTC guide doesn't say anything about it yet.
		
        if ([transactionType isEqualToString:@"IA1"]) {
			transactionType = @"2";
		} else if([transactionType isEqualToString:@"IA9"]) {
			transactionType = @"9";
		} else if ([transactionType isEqualToString:@"IA7"]) {
			transactionType = @"7";
		} else if ([transactionType isEqualToString:@"F1"]) {
			transactionType = @"1";
		} else if ([transactionType isEqualToString:@"F7"]) {
			transactionType = @"7";
		}
        
        const BOOL inAppPurchase = ![parentID isEqualToString:@" "];
        Country *country = [self countryNamed:countryString]; //will be created on-the-fly if needed.
        [[[Entry alloc] initWithProductIdentifier:appId
                                             name:productName
                                  transactionType:[transactionType intValue]
                                            units:[units intValue]
                                        royalties:[royalties floatValue]
                                         currency:royaltyCurrency
                                          country:country
                                    inAppPurchase:inAppPurchase] autorelease]; //gets added to the countries entry list automatically
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
			if (entry.purchase ) {
				NSNumber *newCount = [NSNumber numberWithInt:[[salesByApp objectForKey:entry.productName] intValue] + entry.units];
				[salesByApp setObject:newCount forKey:entry.productName];
				NSNumber *oldRevenue = [revenueByCurrency objectForKey:entry.currency];
				NSNumber *newRevenue = [NSNumber numberWithFloat:(oldRevenue ? [oldRevenue floatValue] : 0.0) + entry.royalties * entry.units];
				[revenueByCurrency setObject:newRevenue forKey:entry.currency];
			}
		}
	}
	[summary release];
	summary = [[NSDictionary alloc] initWithObjectsAndKeys: 
									self.date, kSummaryDate,
									revenueByCurrency, kSummaryRevenue,
									salesByApp, kSummarySales,
									[NSNumber numberWithBool:self.isWeek], kSummaryIsWeek,
									nil];
}


- (id) initWithSummary:(NSDictionary*)summaryToUse date:(NSDate*)dateToUse isWeek:(BOOL)week isFault:(BOOL)fault
{
	self = [super init];
	if (self) {
		summary = [summaryToUse retain];
		date = [dateToUse retain];
		isWeek = week;
		isFault = fault;
		wasLoadedFromDisk = YES;
	}
	return self;
}

+ (Day *)dayWithSummary:(NSDictionary *)reportSummary
{
	return [[[Day alloc] initWithSummary:reportSummary date:[reportSummary objectForKey:kSummaryDate]
								  isWeek:[[reportSummary objectForKey:kSummaryIsWeek] boolValue] isFault:YES] autorelease];
}


- (id)initWithCoder:(NSCoder *)coder
{
	self = [self init];
	if (self) {
		date = [[coder decodeObjectForKey:@"date"] retain];
		countries = [[coder decodeObjectForKey:@"countries"] retain];
		isWeek = [coder decodeBoolForKey:@"isWeek"];
		wasLoadedFromDisk = YES;
	}
	return self;
}


- (NSMutableDictionary *)countries
{	
	if (isFault) {
		NSString *filename = [self proposedFilename];
		NSString *fullPath = [getDocPath() stringByAppendingPathComponent:filename];
		Day *fulfilledFault = [NSKeyedUnarchiver unarchiveObjectWithFile:fullPath];
		countries = [fulfilledFault.countries retain];
		isFault = NO;
	}
	return countries;
}

+ (Day *)dayFromCSVFile:(NSString *)filename atPath:(NSString *)docPath;
{
	NSString *fullPath = [docPath stringByAppendingPathComponent:filename];
	Day *loadedDay = [[Day alloc] initWithCSV:[NSString stringWithContentsOfFile:fullPath encoding:NSUTF8StringEncoding error:nil]];	
	return [loadedDay autorelease];
}

- (BOOL) archiveToDocumentPathIfNeeded:(NSString*)docPath {
	NSFileManager *manager = [NSFileManager defaultManager];
	NSString *fullPath = [docPath stringByAppendingPathComponent:self.proposedFilename];
	BOOL isDirectory = false;
	if ([manager fileExistsAtPath:fullPath isDirectory:&isDirectory]) {
		if (isDirectory) {
			[NSException raise:NSGenericException format:@"found unexpected directory at Day path: %@", fullPath];
		}
		return FALSE;
	}
	// hasn't been arhived yet, write it out now
	if (! [NSKeyedArchiver archiveRootObject:self toFile:fullPath]) {
		NSLog(@"could not archive out %@", self);
		return FALSE;
	}
	return TRUE;
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
		country = [[Country alloc] initWithName:countryName day:self];
		[self.countries setObject:country forKey:countryName];
		[country release];
	}
	return country;
}

- (NSString *)description
{
	NSDictionary *salesByProduct = nil;
	if (!self.summary) {
		NSMutableDictionary *temp = [NSMutableDictionary dictionary];
		for (Country *c in [self.countries allValues]) {
			for (Entry *e in [c entries]) {
				if (e.purchase) {
					NSNumber *unitsOfProduct = [temp objectForKey:[e productName]];
					int u = (unitsOfProduct != nil) ? ([unitsOfProduct intValue]) : 0;
					u += [e units];
					[temp setObject:[NSNumber numberWithInt:u] forKey:[e productName]];
				}
			}
		}
		salesByProduct = temp;
	} else {
		salesByProduct = [summary objectForKey:kSummarySales];
	}
		
	NSMutableString *productSummary = [NSMutableString stringWithString:@"("];
	
	NSEnumerator *reverseEnum = [[salesByProduct keysSortedByValueUsingSelector:@selector(compare:)] reverseObjectEnumerator];
    for (NSString *productName in reverseEnum) {
		NSNumber *productSales = [salesByProduct objectForKey:productName];
		[productSummary appendFormat:@"%@ × %@, ", productSales, productName];
	}
	if (productSummary.length >= 2)
		[productSummary deleteCharactersInRange:NSMakeRange(productSummary.length - 2, 2)];
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

- (float)totalRevenueInBaseCurrencyForAppWithID:(NSString *)appID {
	if (appID == nil)
		return [self totalRevenueInBaseCurrency];
	float sum = 0.0;
	for (Country *c in [self.countries allValues]) {
		sum += [c totalRevenueInBaseCurrencyForAppWithID:appID];
	}
	return sum;
}

- (int)totalUnitsForAppWithID:(NSString *)appID {
	if (appID == nil)
		return [self totalUnits];
	int sum = 0;
	for (Country *c in [self.countries allValues]) {
		sum += [c totalUnitsForAppWithID:appID];
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

//- (NSArray *)allProductNames
//{
//	NSMutableSet *names = [NSMutableSet set];
//	for (Country *c in [self.countries allValues]) {
//		[names addObjectsFromArray:[c allProductNames]];
//	}
//	return [names allObjects];
//}

- (NSString *)totalRevenueString
{
	return [[CurrencyManager sharedManager] baseCurrencyDescriptionForAmount:
			[NSNumber numberWithFloat:self.totalRevenueInBaseCurrency] withFraction:YES];
}

- (NSString *)totalRevenueStringForApp:(NSString *)appName
{
	NSString *appID = [[AppManager sharedManager] appIDForAppName:appName];
	return [[CurrencyManager sharedManager] baseCurrencyDescriptionForAmount:[NSNumber numberWithFloat:[self totalRevenueInBaseCurrencyForAppWithID:appID]] withFraction:YES];
}

- (NSString *)dayString
{
	NSDateComponents *components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit fromDate:self.date];
	return [NSString stringWithFormat:@"%i", [components day]];
}

- (NSString *)weekdayString
{
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormatter setDateFormat:@"EEE"];
	return [[dateFormatter stringFromDate:self.date] uppercaseString];
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
	NSDateFormatter *dateFormatter = [NSDateFormatter sharedShortDateFormatter];
	return [dateFormatter stringFromDate:dateWeekLater];
}


- (NSArray *)children
{
	NSSortDescriptor *sorter = [[[NSSortDescriptor alloc] initWithKey:@"totalUnits" ascending:NO] autorelease];
	NSArray *sortedChildren = [self.countries.allValues sortedArrayUsingDescriptors:[NSArray arrayWithObject:sorter]];
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

- (NSString *)appIDForApp:(NSString *)appName {
	NSString *appID = nil;
	for(Country *c in [self.countries allValues]){
		appID = [c appIDForApp:appName];
		if(appID)
			break;
	}
	return appID;
}

- (void)dealloc
{
	[countries release];
	[date release];
	[summary release];
	
	[super dealloc];
}

@end
