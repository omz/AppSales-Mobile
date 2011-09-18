//
//  AppleFiscalCalendar.h
//  AppSales
//
//  Created by Tim Shadel on 4/5/11.
//  Copyright 2011 Shadel Software, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface AppleFiscalCalendar : NSObject {
	
	NSArray *sortedFiscalMonthNames;
	NSArray *sortedDates;
}

+ (AppleFiscalCalendar *)sharedFiscalCalendar;
- (NSString *)fiscalMonthForDate:(NSDate *)date;
- (NSUInteger)indexOfNextMonthForDate:(NSDate *)requestedDate;
- (NSDate *)representativeDateForFiscalMonthOfDate:(NSDate *)requestedDate;

@end
