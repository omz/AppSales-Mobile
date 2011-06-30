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


/*
on 2011-06-20 a header line looks like this:

Provider	Provider Country	SKU	Developer	Title	Version	Product Type Identifier	Units	Developer Proceeds	Begin Date	End Date	Customer Currency	Country Code	Currency of Proceeds	Apple Identifier	Customer Price	Promo Code	Parent Identifier	Subscription	Period

to create the following defines use the script in the commandline:
*/
// pbpaste |perl -ne '@fields=split(/\t/,$_);for( @fields) {$original=$_;s/\s*//g;print "#define\t kS_AppleReport_$_\t\t@\"".lc $original."\"\n";};'


#define	 kS_AppleReport_Provider				@"provider"
#define	 kS_AppleReport_ProviderCountry			@"provider country"
#define	 kS_AppleReport_SKU						@"sku"
#define	 kS_AppleReport_Developer				@"developer"
#define	 kS_AppleReport_Title					@"title"
#define	 kS_AppleReport_Version					@"version"
#define	 kS_AppleReport_ProductTypeIdentifier	@"product type identifier"
#define	 kS_AppleReport_Units					@"units"
#define	 kS_AppleReport_DeveloperProceeds		@"developer proceeds"
#define	 kS_AppleReport_BeginDate				@"begin date"
#define	 kS_AppleReport_EndDate					@"end date"
#define	 kS_AppleReport_CustomerCurrency		@"customer currency"
#define	 kS_AppleReport_CountryCode				@"country code"
#define	 kS_AppleReport_CurrencyofProceeds		@"currency of proceeds"
#define	 kS_AppleReport_AppleIdentifier			@"apple identifier"
#define	 kS_AppleReport_CustomerPrice			@"customer price"
#define	 kS_AppleReport_PromoCode				@"promo code"
#define	 kS_AppleReport_ParentIdentifier		@"parent identifier"
#define	 kS_AppleReport_Subscription			@"subscription"
#define	 kS_AppleReport_Period					@"period"



// defines taken from http://www.apple.com/itunesnews/docs/AppStoreReportingInstructions.pdf

#define	kS_AppleReport_ProductType_iPhoneAppPurchase	@"1"
#define	kS_AppleReport_ProductType_iPhoneAppUpdate		@"7"
#define	kS_AppleReport_ProductType_InAppPurchase		@"IA1"
#define	kS_AppleReport_ProductType_InAppSubscription	@"IA9"
#define	kS_AppleReport_ProductType_UniveralAppPurchase	@"1F"
#define	kS_AppleReport_ProductType_UniveralAppUpdate	@"7F"
#define	kS_AppleReport_ProductType_iPadAppPurchase		@"1T"
#define	kS_AppleReport_ProductType_iPadAppUpdate		@"7T"

// following encounterd in the wild and not (yet) described in the appstore reporting instrucitons
#define	kS_AppleReport_ProductType_MacAppPurchase		@"F1"
#define	kS_AppleReport_ProductType_MacAppUpdate			@"F7"




@class Country;

@interface Day : NSObject<NSCoding> {
	NSDate *date;
	NSMutableDictionary *countriesDictionary;
	
    BOOL isWeek:1;
	BOOL wasLoadedFromDisk:1;
	BOOL isFault:1;
    
	NSDictionary *summary;
}

@property (readonly) NSDate *date;
@property (readonly) NSMutableDictionary *countriesDictionary;
@property (readonly) BOOL isWeek;
@property (readonly) BOOL wasLoadedFromDisk;
@property (readonly) BOOL isFault;
@property (readonly) NSDictionary *summary;

+ (NSDate*) adjustDateToLocalTimeZone:(NSDate *)inDate;
#
#pragma mark initalization Methods
#
+ (Day *)dayWithData:(NSData *)dayData compressed:(BOOL)compressed;
- (id)initWithCSV:(NSString *)csv;
+ (Day *)dayFromCSVFile:(NSString *)filename atPath:(NSString *)docPath;
- (id) initWithSummary:(NSDictionary*)summaryToUse date:(NSDate*)dateToUse isWeek:(BOOL)week isFault:(BOOL)fault;
+ (Day *)dayWithSummary:(NSDictionary *)reportSummary;
- (void)dealloc;
#
#pragma mark Archiving / Unarchiving
#
- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;
- (BOOL)archiveToDocumentPathIfNeeded:(NSString*)docPath;
#
#pragma mark
#
- (void)generateSummary;
- (NSMutableDictionary *)countriesDictionary;
- (Country *)countryNamed:(NSString *)countryName;
- (NSString *)description;
- (float)totalRevenueInBaseCurrency;
- (float)totalRevenueInBaseCurrencyForAppWithID:(NSString *)appID;
- (int)totalUnitsForAppWithID:(NSString *)appID;
- (int)totalUnits;
- (float)customerUSPriceForAppWithID:(NSString *)appID;
- (NSArray *)allProductIDs;
- (NSString *)totalRevenueString;
- (NSString *)totalRevenueStringForApp:(NSString *)appName;
- (NSString *)dayString;
- (NSString *)weekdayString;
- (UIColor *)weekdayColor;
- (NSString *)weekEndDateString;
- (NSArray *)children;
- (NSString *)proposedFilename;
- (NSString *)appIDForApp:(NSString *)appName;

@end
