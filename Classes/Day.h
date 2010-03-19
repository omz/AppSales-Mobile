/*
 Day.h
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

#import <UIKit/UIKit.h>

#define kSummaryDate	@"date"
#define kSummarySales	@"sales"
#define kSummaryRevenue	@"revenue"
#define kSummaryIsWeek	@"isWeek"

@class Country;


@interface Day : NSObject {
	
	NSDate *date;
	NSMutableDictionary *countries;
	
	BOOL isWeek;
	BOOL wasLoadedFromDisk;
	NSString *pathOnDisk;
	
	BOOL isFault;
	NSDictionary *summary;
}

@property (nonatomic, retain) NSDate *date;
@property (nonatomic, retain) NSMutableDictionary *countries;
@property (nonatomic, assign) BOOL isWeek;
@property (nonatomic, assign) BOOL wasLoadedFromDisk;
@property (nonatomic, retain) NSString *pathOnDisk;

@property (nonatomic, assign) BOOL isFault;
@property (nonatomic, retain) NSDictionary *summary;


- (id)initWithCSV:(NSString *)csv;

- (void)generateSummary;
+ (Day *)dayWithSummary:(NSDictionary *)reportSummary;

- (Country *)countryNamed:(NSString *)countryName;

- (NSDate *)reportDateFromString:(NSString *)dateString;

- (float)totalRevenueInBaseCurrency;
- (float)totalRevenueInBaseCurrencyForApp:(NSString *)app;

- (int)totalUnitsForApp:(NSString *)app;
- (int)totalUnits;

- (NSArray *)allProductNames;

- (NSString *)dayString;
- (NSString *)weekdayString;
- (NSString *)weekEndDateString;
- (UIColor *)weekdayColor;

- (NSString *)totalRevenueString;

- (NSString *)proposedFilename;

- (NSArray *)children;

@end
