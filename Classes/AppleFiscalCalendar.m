//
//  AppleFiscalCalendar.m
//  AppSales
//
//  Created by Tim Shadel on 4/5/11.
//  Copyright 2011 Shadel Software, Inc. All rights reserved.
//

#import "AppleFiscalCalendar.h"

@implementation AppleFiscalCalendar

- (id)init
{
    self = [super init];
    if (self) {
		
		NSCalendar *calendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
		[calendar setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
		NSDateComponents *firstDateComponents = [[[NSDateComponents alloc] init] autorelease];
		[firstDateComponents setMonth:9];
		[firstDateComponents setDay:29];
		[firstDateComponents setYear:2007];
		NSDate *firstDate = [calendar dateFromComponents:firstDateComponents];
		
		NSDateComponents *components5Weeks = [[[NSDateComponents alloc] init] autorelease];
		[components5Weeks setWeek:5];
		NSDateComponents *components4Weeks = [[[NSDateComponents alloc] init] autorelease];
		[components4Weeks setWeek:4];
		
		NSMutableArray *dates = [NSMutableArray array];
		NSDate *currentDate = firstDate;
		int period = 0;
		//Covers the fiscal calendar from 2008 to 2016:
		while (period < 100) {
			//First month in a quarter covers 5 weeks, the others 4:
			NSDate *nextDate = [calendar dateByAddingComponents:((period % 3 == 0) ? components5Weeks : components4Weeks) toDate:currentDate options:0];
			[dates addObject:nextDate];
			currentDate = nextDate;
			period++;
		}
		
		NSMutableArray *names = [NSMutableArray array];
		
        NSDateFormatter *sectionTitleFormatter = [[NSDateFormatter new] autorelease];
		[sectionTitleFormatter setDateFormat:@"MMMM yyyy"];
        
        for (NSDate *date in dates) {
			// Name of the fiscal month can be reliably found by the calendar month of a day 2 weeks after the fiscal month begins
            NSDateComponents *components = [NSDateComponents new];
            [components setDay:14];
            NSDate *result = [calendar dateByAddingComponents:components toDate:date options:0];
            [components release];
            NSString *fiscalMonthName = [sectionTitleFormatter stringFromDate:result];
			[names addObject:fiscalMonthName];
		}
		sortedFiscalMonthNames = [[NSArray alloc] initWithArray:names];
		sortedDates = [[NSArray alloc] initWithArray:dates];
    }
    return self;
}

- (NSString *)fiscalMonthForDate:(NSDate *)requestedDate
{
    NSUInteger indexOfNextMonth = [self indexOfNextMonthForDate:requestedDate];
	if (indexOfNextMonth > 0) {
		return [sortedFiscalMonthNames objectAtIndex:indexOfNextMonth - 1];
	} else {
		return nil;
	}
}

- (NSDate *)representativeDateForFiscalMonthOfDate:(NSDate *)requestedDate
{
	NSUInteger indexOfNextMonth = [self indexOfNextMonthForDate:requestedDate];
	if (indexOfNextMonth > 0) {
		NSDate *startOfFiscalMonth = [sortedDates objectAtIndex:indexOfNextMonth - 1];
		NSDate *representativeDate = [startOfFiscalMonth dateByAddingTimeInterval:14 * 24 * 60 * 60];
		return representativeDate;
	} else {
		return nil;
	}
}

- (NSUInteger)indexOfNextMonthForDate:(NSDate *)requestedDate
{
	NSUInteger indexOfNextMonth = [sortedDates indexOfObject:requestedDate 
											   inSortedRange:NSMakeRange(0, [sortedDates count])
													 options:NSBinarySearchingLastEqual|NSBinarySearchingInsertionIndex
											 usingComparator:^ (id obj1, id obj2) {
												 // Pass the day if equals, so that we can always go back one index
												 return [obj1 compare:obj2] == NSOrderedAscending ? NSOrderedAscending : NSOrderedDescending;
											 }];
	
	return indexOfNextMonth;
}

+ (AppleFiscalCalendar *)sharedFiscalCalendar
{
	static id sharedFiscalCalendar = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedFiscalCalendar = [[self alloc] init];
	});
	return sharedFiscalCalendar;
}


- (void)dealloc
{
	[sortedDates release];
	[sortedFiscalMonthNames release];
    [super dealloc];
}

@end
