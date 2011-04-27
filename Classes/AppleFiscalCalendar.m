//
//  AppleFiscalCalendar.m
//  AppSalesMobile
//
//  Created by Tim Shadel on 4/5/11.
//  Copyright 2011 Shadel Software, Inc. All rights reserved.
//

#import "AppleFiscalCalendar.h"
#import "AppSalesUtils.h"

@implementation AppleFiscalCalendar

- (id)init
{
    self = [super init];
    if (self) {
        sortedDateStrings = [[NSArray alloc] initWithObjects:
                                        @"20080928", // Oct 2008
                                        @"20081102", // Nov 2008
                                        @"20081130", // Dec 2008
                                        @"20081228", // Jan 2009
                                        @"20090201", // Feb 2009
                                        @"20090301", // Mar 2009
                                        @"20090329", // Apr 2009
                                        @"20090503", // May 2009
                                        @"20090531", // Jun 2009
                                        @"20090628", // Jul 2009
                                        @"20090802", // Aug 2009
                                        @"20090830", // Sep 2009
                                        @"20090927", // Oct 2009
                                        @"20091101", // Nov 2009
                                        @"20091129", // Dec 2009
                                        @"20091227", // Jan 2010
                                        @"20100131", // Feb 2010
                                        @"20100228", // Mar 2010
                                        @"20100328", // Apr 2010
                                        @"20100502", // May 2010
                                        @"20100530", // Jun 2010
                                        @"20100629", // Jul 2010
                                        @"20100801", // Aug 2010
                                        @"20100829", // Sep 2010
                                        @"20100926", // Oct 2010
                                        @"20101031", // Nov 2010
                                        @"20101128", // Dec 2010
                                        @"20101226", // Jan 2011
                                        @"20110130", // Feb 2011
                                        @"20110227", // Mar 2011
                                        @"20110327", // Apr 2011
                                        @"20110501", // May 2011
                                        @"20110529", // Jun 2011
                                        @"20110626", // Jul 2011
                                        @"20110731", // Aug 2011
                                        @"20110828", // Sep 2011
                                       nil];

        const NSUInteger numSortedDates = [sortedDateStrings count];
        NSMutableArray *names = [NSMutableArray arrayWithCapacity:numSortedDates];
        NSMutableArray *dates = [NSMutableArray arrayWithCapacity:numSortedDates];

        NSDateFormatter *dayStringParser = [NSDateFormatter new];
        [dayStringParser setDateFormat:@"YYYYMMdd"];
		NSDateFormatter *sectionTitleFormatter = [NSDateFormatter new];
		[sectionTitleFormatter setDateFormat:@"MMMM yyyy"];
        NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        for (NSString *dayString in sortedDateStrings) {
            NSDate *date = [dayStringParser dateFromString:dayString];
            [dates addObject:date];

            // Name of the fiscal month can be reliably found by the calendar month of a day 2 weeks after the fiscal month begins
            NSDateComponents *components = [NSDateComponents new];
            [components setDay:14];
            NSDate *result = [gregorian dateByAddingComponents:components toDate:date options:0];
            [components release];
            
            NSString *fiscalMonthName = [sectionTitleFormatter stringFromDate:result];
            [names addObject:fiscalMonthName];
        }
        [gregorian release];
        [dayStringParser release];
        [sectionTitleFormatter release];
        sortedFiscalMonthNames = [[NSArray arrayWithArray:names] retain];
        sortedDates = [[NSArray arrayWithArray:dates] retain];
    }
    return self;
}

- (NSString *)fiscalMonthForDate:(NSDate *)requestedDate
{
    NSUInteger indexOfNextMonth = [sortedDates
                                   indexOfObject:requestedDate
                                   inSortedRange:NSMakeRange(0, [sortedDates count])
                                   options:NSBinarySearchingLastEqual|NSBinarySearchingInsertionIndex
                                   usingComparator:
    ^(id obj1, id obj2){
            // Pass the day if equals, so that we can always go back one index
            return [obj1 compare:obj2] == NSOrderedAscending ? NSOrderedAscending : NSOrderedDescending;
    }];

    if (indexOfNextMonth > 0) {
        return [sortedFiscalMonthNames objectAtIndex:indexOfNextMonth-1];
    } else {
        return nil;
    }
}

+ (AppleFiscalCalendar *)sharedFiscalCalendar
{
    ASSERT_IS_MAIN_THREAD();
	static AppleFiscalCalendar *sharedFiscalCalendar = nil;
	if (sharedFiscalCalendar == nil)
		sharedFiscalCalendar = [AppleFiscalCalendar new];
	return sharedFiscalCalendar;
}


- (void)dealloc
{
    RELEASE_SAFELY(sortedDates);
    RELEASE_SAFELY(sortedDateStrings);
    RELEASE_SAFELY(sortedFiscalMonthNames);
    [super dealloc];
}

@end
