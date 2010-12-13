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

@interface Day : NSObject<NSCoding> {
	NSDate *date;
	NSMutableDictionary *countries;
	BOOL isWeek;
	
	BOOL wasLoadedFromDisk;
	BOOL isFault;
	NSDictionary *summary;
}

@property (readonly) NSDate *date;
@property (readonly) NSMutableDictionary *countries;
@property (readonly) BOOL isWeek;
@property (readonly) BOOL wasLoadedFromDisk;
@property (readonly) BOOL isFault;
@property (readonly) NSDictionary *summary;

+ (Day *)dayFromCSVFile:(NSString *)filename atPath:(NSString *)docPath;
+ (Day *)dayWithData:(NSData *)dayData compressed:(BOOL)compressed;

- (id)initWithCSV:(NSString *)csv;

// returns true if instances was serialized out to docPath
- (BOOL) archiveToDocumentPathIfNeeded:(NSString*)docPath;


- (void)generateSummary;
+ (Day *)dayWithSummary:(NSDictionary *)reportSummary;

- (Country *)countryNamed:(NSString *)countryName;

- (float)totalRevenueInBaseCurrency;
- (float)totalRevenueInBaseCurrencyForAppWithID:(NSString *)appID;
- (int)totalUnitsForAppWithID:(NSString *)appID;
- (int)totalUnits;

- (NSArray *)allProductIDs;

- (NSString *)dayString;
- (NSString *)weekdayString;
- (NSString *)weekEndDateString;
- (UIColor *)weekdayColor;

- (NSString *)totalRevenueString;
- (NSString *)totalRevenueStringForApp:(NSString *)appName;

- (NSString *)proposedFilename;

- (NSArray *)children;

- (NSString *)appIDForApp:(NSString *)appName; // TODO: rename

@end
