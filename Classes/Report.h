//
//  Report.h
//  AppSales
//
//  Created by Ole Zorn on 02.07.11.
//  Copyright (c) 2011 omz:software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ReportSummary.h"

#define kReportSummaryTransactions		@"t"
#define kReportSummaryRevenue			@"r"

#define kReportInfoClass				@"class"
#define kReportInfoDate					@"date"
#define kReportInfoClassWeekly			@"WeeklyReport"
#define kReportInfoClassDaily			@"DailyReport"

@class ASAccount, ReportCache;

@interface Report : NSManagedObject <ReportSummary> {

}

@property (nonatomic, strong) ReportCache *cache;
@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSSet *transactions;

+ (BOOL)validateColumnHeaders:(NSArray *)columnHeaders;
+ (NSDictionary *)infoForReportCSV:(NSString *)csv;
+ (Report *)insertNewReportWithCSV:(NSString *)csv inAccount:(ASAccount *)account;
+ (NSDate *)dateFromReportDateString:(NSString *)dateString;
+ (NSString *)identifierForDate:(NSDate *)date;

+ (NSSet *)combinedPaidTransactionTypes;
+ (NSSet *)combinedUpdateTransactionTypes;
+ (NSSet *)combinedRedownloadedTransactionTypes;
+ (NSSet *)combinedEducationalTransactionTypes;
+ (NSSet *)combinedGiftPurchaseTransactionTypes;
+ (NSSet *)combinedPromoCodeTransactionTypes;

+ (NSSet *)paidTransactionTypes;
- (void)generateCache;

- (int)totalNumberOfTransactionsInSet:(NSSet *)transactionTypes forProductWithID:(NSString *)productID;

@end
