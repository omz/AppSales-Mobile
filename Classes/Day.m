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
#import "AppSalesUtils.h"


#define kS_Archiving_VersionKey			@"v"
#define	kS_Archiving_VersionValue		@"2"
#define	kS_Archiving_DateKey			@"t"
#define	kS_Archiving_isWeekKey			@"w"
#define	kS_Archiving_CountryKeysKey		@"k"
#define	kS_Archiving_CountryObjectsKey	@"o"



static BOOL arrayContainsOnlyWhiteSpaceStrings(NSArray* array) {
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

static NSDate* reportDateFromString(NSString *dateString) 
{
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

@synthesize date, countriesDictionary, isWeek, wasLoadedFromDisk, summary, isFault;

//
// currently broken
//
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

#
#pragma mark initalization Methods
#

+ (Day *)dayWithData:(NSData *)dayData compressed:(BOOL)compressed 
{
	NSString *text = nil;
    
	if( !compressed)
    {
		text = [[[NSString alloc] initWithData:dayData encoding:NSUTF8StringEncoding] autorelease];
	}
    
    if( compressed || !text )
    {
        text = [[[NSString alloc] initWithData:[dayData gzipInflate] encoding:NSUTF8StringEncoding] autorelease];
	}
    
	return [[[Day alloc] initWithCSV:text] autorelease];
}



- (id)initWithCSV:(NSString *)csv
{
	if( !(self=[super init]) )
	{
		return nil;
	}
	
    NSMutableArray *rowStringArray = [[[csv componentsSeparatedByString:@"\n"] mutableCopy] autorelease];
	
	if( [rowStringArray count] < 3 ) 
	{
		JLog(@"Not enough lines in csv:%@",csv);
		[self release];
		return nil; // sanity check
	}
	
	wasLoadedFromDisk	= NO;	
	countriesDictionary			= [[NSMutableDictionary alloc] init];
		
	NSString	*headerLineString	= [[rowStringArray objectAtIndex:0] lowercaseString];
	NSArray		*columnHeadersArray	= [headerLineString componentsSeparatedByString:@"\t"];
	
	[rowStringArray removeObjectAtIndex:0];		// remove headerline
	
	{
		NSMutableSet *requiredHeadersSet	= [NSMutableSet setWithObjects:	kS_AppleReport_Title,
																			kS_AppleReport_ProductTypeIdentifier,
																			kS_AppleReport_Units,
																			kS_AppleReport_DeveloperProceeds,
																			kS_AppleReport_BeginDate,
																			kS_AppleReport_EndDate,
																			kS_AppleReport_CountryCode,
																			kS_AppleReport_CurrencyofProceeds,
																			kS_AppleReport_AppleIdentifier,
																			kS_AppleReport_ParentIdentifier,
																			kS_AppleReport_CustomerPrice,
																			nil];
																			
		if( ![requiredHeadersSet isSubsetOfSet:[NSSet setWithArray:columnHeadersArray]] )
		{
			JLog(@"Apples csv does not contain the required header fields:\n%@\n%@\n%@\n",columnHeadersArray,requiredHeadersSet,csv);
            
			[self release];
			return nil;
		}
	}	
	
	for( NSString *rowString in rowStringArray ) 
	{
		NSArray *rowFieldsArray = [rowString componentsSeparatedByString:@"\t"];
		
		if( arrayContainsOnlyWhiteSpaceStrings(rowFieldsArray) ) 
		{
			DJLog(@"row contains only whitespace - ignored:%@",rowString);
			continue;
		}
        
		if( rowFieldsArray.count != columnHeadersArray.count )
		{
			JLog(@"row contains different count of fields than header line:\n%@\n%@",headerLineString,rowString);
			continue;
		}
				
		NSMutableDictionary *rowDictionary = [NSMutableDictionary dictionaryWithObjects:rowFieldsArray forKeys:columnHeadersArray];
		
		for( NSString *columnName in columnHeadersArray )
		{
			id columnValue	= [rowDictionary objectForKey:columnName];
			
			if( [columnValue isEqualToString:@" "] )					// change plain space strings to zero strings
			{
				[rowDictionary setObject:@"" forKey:columnName];
			}
			else if( [columnName hasSuffix:@"date"] )
			{
				NSString	*fieldContents	= columnValue;
				NSDate		*fieldDate		= reportDateFromString([fieldContents stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]);
				
				if( !fieldDate )
				{
					JLog(@"Could not parse %@ date field:%@",columnName,fieldContents);
					continue;
				}
				[rowDictionary setObject:fieldDate forKey:columnName];
			}
		}
		DJLog(@"Rows:%@",rowDictionary);
		
		isWeek		= ![[rowDictionary objectForKey:kS_AppleReport_BeginDate] isEqual:[rowDictionary objectForKey:kS_AppleReport_EndDate]];
		date		= [[rowDictionary objectForKey:kS_AppleReport_BeginDate] retain];
		
		[[AppIconManager sharedManager] downloadIconForAppID:[rowDictionary objectForKey:kS_AppleReport_AppleIdentifier]];
        
        [[[Entry alloc] initWithRowDictionary:rowDictionary country:[self countryNamed:[rowDictionary objectForKey:kS_AppleReport_CountryCode]]] release];		//gets added to the countries entry list automatically
	}

	[self generateSummary];
	return self;
}



+ (Day *)dayFromCSVFile:(NSString *)filename atPath:(NSString *)docPath;
{
	NSString *fullPath = [docPath stringByAppendingPathComponent:filename];
	Day *loadedDay = [[Day alloc] initWithCSV:[NSString stringWithContentsOfFile:fullPath encoding:NSUTF8StringEncoding error:nil]];	
	return [loadedDay autorelease];
}



- (id) initWithSummary:(NSDictionary*)summaryToUse date:(NSDate*)dateToUse isWeek:(BOOL)week isFault:(BOOL)fault
{
	if( !(self = [super init]) )
    {
        return self;
    }
    
    summary             = [summaryToUse retain];
    date                = [dateToUse retain];
    isWeek              = week;
    isFault             = fault;
    wasLoadedFromDisk   = YES;

	return self;
}



+ (Day *)dayWithSummary:(NSDictionary *)reportSummary
{
	return [[[Day alloc] initWithSummary:reportSummary date:[reportSummary objectForKey:kSummaryDate]
								  isWeek:[[reportSummary objectForKey:kSummaryIsWeek] boolValue] isFault:YES] autorelease];
}



- (void)dealloc
{
	[countriesDictionary release];
	[date release];
	[summary release];
	
	[super dealloc];
}

#pragma mark Archiving / Unarchiving


- (id)initWithCoder:(NSCoder *)coder
{
	if( !(self = [self init]) )
	{
		return nil;
	}
	if(! [[coder decodeObjectForKey:kS_Archiving_VersionKey] isEqualToString:kS_Archiving_VersionValue] )
	{
        [self release];
        return nil;
	}
	
	date                        = [[coder decodeObjectForKey:kS_Archiving_DateKey] retain];
    NSArray *countriesKeys      = [coder decodeObjectForKey:kS_Archiving_CountryKeysKey];
    NSArray *countriesObjects   = [coder decodeObjectForKey:kS_Archiving_CountryObjectsKey];
	isWeek                      = [coder decodeBoolForKey:kS_Archiving_isWeekKey];
	wasLoadedFromDisk           = YES;
	
    if( !date || !countriesKeys || !countriesObjects || (countriesKeys.count <1) || (countriesKeys.count!=countriesObjects.count) )
    {
        [self release];
        return nil;
    }
    countriesDictionary = [[NSMutableDictionary alloc] initWithObjects:countriesObjects forKeys:countriesKeys];
	return self;
}



- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:kS_Archiving_VersionValue		forKey:kS_Archiving_VersionKey];
    [coder encodeObject:date                            forKey:kS_Archiving_DateKey];
	[coder encodeObject:[countriesDictionary allKeys]   forKey:kS_Archiving_CountryKeysKey];               // we encode keys and objects sperarate as a a new version in the encoding might 
	[coder encodeObject:[countriesDictionary allValues] forKey:kS_Archiving_CountryObjectsKey];            // not be compatible and that way we don't get NSDictionary to complain about nonexisting objects
	[coder encodeBool:isWeek                            forKey:kS_Archiving_isWeekKey];                     
}



- (BOOL)archiveToDocumentPathIfNeeded:(NSString*)docPath
{
	NSFileManager	*manager	= [NSFileManager defaultManager];
	NSString		*fullPath	= [docPath stringByAppendingPathComponent:self.proposedFilename];
	BOOL			isDirectory = false;
	if([manager fileExistsAtPath:fullPath isDirectory:&isDirectory])
	{
		JLog(@"could not archive out fileExistsAtPath :%@ , %@",docPath,fullPath);
		if (isDirectory) 
		{
			[NSException raise:NSGenericException format:@"found unexpected directory at Day path: %@", fullPath];
		}
		return FALSE;
	}
	// hasn't been arhived yet, write it out now
	if(! [NSKeyedArchiver archiveRootObject:self toFile:fullPath] ) 
	{
		JLog(@"could not archive out to:%@ self:%@",fullPath,self);
		return FALSE;
	}
	return TRUE;
}


#pragma mark

- (void)generateSummary
{
	NSMutableDictionary *revenueByCurrency = [NSMutableDictionary dictionary];
	NSMutableDictionary *salesByApp = [NSMutableDictionary dictionary];
	for (Country *country in [self.countriesDictionary allValues]) {
		for (Entry *entry in country.entriesArray) {
			if (entry.isPurchase ) {
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



- (NSMutableDictionary *)countriesDictionary
{	
	if (isFault) {
		NSString *filename = [self proposedFilename];
		NSString *fullPath = [getDocPath() stringByAppendingPathComponent:filename];
		Day *fulfilledFault = [NSKeyedUnarchiver unarchiveObjectWithFile:fullPath];
		
		if( !fulfilledFault )
		{
			JLog(@"Entry seems to be not compatible - reloading from csv");
			
			{
				NSError *error;
				
				if( [[NSFileManager defaultManager] fileExistsAtPath:fullPath] && ![[NSFileManager defaultManager] removeItemAtPath:fullPath error:&error] )
				{
					JLog(@"Could not remove file at %@ due to %@",fullPath,error);
				}
			}
		
			NSMutableDictionary		*originalFilenameDictionary     = nil;
			NSString				*originalFilenameDirectoryPath  = [getDocPath() stringByAppendingPathComponent:@"OriginalReports"];

			if( !originalFilenameDictionary )
			{
				originalFilenameDictionary = [NSMutableDictionary dictionary];
				
				for( NSString	*originalFilename in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:originalFilenameDirectoryPath error:NULL] )
				{
					NSArray *originalFilenameParts = [originalFilename componentsSeparatedByString:@"_"];
					
					if(		[originalFilenameParts count] == 5 )
					{
						NSString	*reportType = [originalFilenameParts objectAtIndex:1];
						NSString	*reportDate	= [originalFilenameParts objectAtIndex:3];
						
						if( [reportType isEqual:@"D"] || [reportType isEqual:@"W"])
						{
							[originalFilenameDictionary setObject:originalFilename	forKey:[NSString stringWithFormat:@"%@_%@",[reportType isEqual:@"D"]?@"day":@"week",reportDate]];
						}
					}
				}
			}

			NSArray	*filenameParts		= [[filename stringByDeletingPathExtension] componentsSeparatedByString:@"_"];
			
			if( [filenameParts count] == 4 )
			{
				NSString	*originalReportFilename = [originalFilenameDictionary objectForKey:[NSString stringWithFormat:@"%@_%@%@%@"	,[filenameParts objectAtIndex:0]
																																		,[filenameParts objectAtIndex:3]
																																		,[filenameParts objectAtIndex:1]
																																		,[filenameParts objectAtIndex:2]]];
				if( originalReportFilename )
				{
					JLog(@"Generating report from original filename:%@",originalReportFilename);
					
                    NSString    *originalReportFullFilename = [originalFilenameDirectoryPath stringByAppendingPathComponent:originalReportFilename];
					NSData      *filecontentData            = [NSData dataWithContentsOfFile:originalReportFullFilename];
					
					if( !filecontentData || filecontentData.length < 1)
					{
						JLog(@"Could not read file:%@",originalReportFullFilename);
					}
					else
					{
                        if( (fulfilledFault	= [Day dayWithData:filecontentData compressed:[originalReportFullFilename hasSuffix:@".gz"]?YES:NO]) )
                        {
                            [fulfilledFault archiveToDocumentPathIfNeeded:getDocPath()];
                        }
                        else
                        {
                            JLog(@"Could not create Day from report file:%@\n%@",originalReportFilename,filecontentData);
                        }
					}
				}
			}
			else
			{
				JLog(@"Cache filename looks weird.%@",filename);
			}	
		}
		
		countriesDictionary = [fulfilledFault.countriesDictionary retain];
		isFault = NO;
	}
	return countriesDictionary;
}




- (Country *)countryNamed:(NSString *)countryName
{
	Country *country = [self.countriesDictionary objectForKey:countryName];
	if (!country) {
		country = [[Country alloc] initWithName:countryName day:self];
		[self.countriesDictionary setObject:country forKey:countryName];
		[country release];
	}
	return country;
}

- (NSString *)description
{
	NSDictionary *salesByProduct = nil;
	if (!self.summary) {
		NSMutableDictionary *temp = [NSMutableDictionary dictionary];
		for (Country *c in [self.countriesDictionary allValues]) {
			for (Entry *e in [c entriesArray]) {
				if (e.isPurchase) {
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
		for (Country *c in [self.countriesDictionary allValues]) {
			sum += [c totalRevenueInBaseCurrency];
		}
		return sum;
	}
}

- (float)totalRevenueInBaseCurrencyForAppWithID:(NSString *)appID {
	if (appID == nil)
		return [self totalRevenueInBaseCurrency];
	float sum = 0.0;
	for (Country *c in [self.countriesDictionary allValues]) {
		sum += [c totalRevenueInBaseCurrencyForAppWithID:appID];
	}
	return sum;
}

- (int)totalUnitsForAppWithID:(NSString *)appID {
	if (appID == nil)
		return [self totalUnits];
	int sum = 0;
	for (Country *c in [self.countriesDictionary allValues]) {
		sum += [c totalUnitsForAppWithID:appID];
	}
	return sum;
}

- (int)totalUnits
{
	int sum = 0;
	for (Country *c in self.countriesDictionary.allValues) {
		sum += c.totalUnits;
	}
	return sum;
}
- (float)customerUSPriceForAppWithID:(NSString *)appID 
{
	if(appID == nil)
	{
		return -1.0;
	}	
	return [[[self countriesDictionary] objectForKey:@"US"] customerPriceForAppWithID:appID];
}

- (NSArray *)allProductIDs
{
	NSMutableSet *names = [NSMutableSet set];
	for (Country *c in self.countriesDictionary.allValues) {
		[names addObjectsFromArray:c.allProductIDs];
	}
	return names.allObjects;
}

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
	NSArray *sortedChildren = [self.countriesDictionary.allValues sortedArrayUsingDescriptors:[NSArray arrayWithObject:sorter]];
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
	for(Country *c in [self.countriesDictionary allValues]){
        NSString *appID = [c appIDForApp:appName];
		if(appID)
			return appID;
	}
	return nil;
}


@end
