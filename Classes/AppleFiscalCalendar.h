//
//  AppleFiscalCalendar.h
//  AppSalesMobile
//
//  Created by Tim Shadel on 4/5/11.
//  Copyright 2011 Shadel Software, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    DayCalendarTypeCalendar,
    DayCalendarTypeAppleFiscal
} DayCalendarType;


@interface AppleFiscalCalendar : NSObject {
  @private
    NSArray *sortedFiscalMonthNames;
    NSArray *sortedDateStrings;
    NSArray *sortedDates;
}

/**
 *  Returns the full month name and year of the fiscal month in which the given date falls.
 */
- (NSString *)fiscalMonthForDate:(NSDate *)date;

/**
 *  Returns the shared instance for use anywhere fiscal date information is needed.
 */
+ (AppleFiscalCalendar *)sharedFiscalCalendar;

@end
