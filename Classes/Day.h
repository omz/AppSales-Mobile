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

@class Country;

@interface Day : NSObject {
	NSMutableDictionary *countries;
	NSDate *date;
	BOOL isWeek;
	NSString *pathOnDisk;	
	NSString *name;

	// generated as needed
	NSString *cachedDayString;
	NSString *cachedWeekEndDateString;
	UIColor *cachedWeekDayColor;
}

@property (readonly) NSDate *date;
@property (readonly) NSMutableDictionary *countries;
@property (readonly) NSString *weekEndDateString;
@property (readonly) UIColor *weekdayColor;
@property (readonly) NSString *dayString;
@property (readonly) NSString *weekdayString;
@property (readonly) NSString *totalRevenueString;
@property (readonly) BOOL isWeek;
@property (readonly) NSString *name; // the date as a full string, and typically used as a primary key

+ (Day *)dayFromFile:(NSString *)filename atPath:(NSString *)docPath; // from serialized data
+ (Day *)dayFromCSVFile:(NSString *)filename atPath:(NSString *)docPath;

- (id)initWithCSV:(NSString *)csv;
- (Country *)countryNamed:(NSString *)countryName;
- (float)totalRevenueInBaseCurrency;
- (float)totalRevenueInBaseCurrencyForAppID:(NSString *)app;
- (int)totalUnitsForAppID:(NSString *)appID;
- (int)totalUnits;
- (NSArray *)allProductIDs;
- (UIColor *)weekdayColor;
- (NSString *)proposedFilename;
- (NSArray *)children;

@end
