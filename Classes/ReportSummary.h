//
//  ReportSummary.h
//  AppSales
//
//  Created by Ole Zorn on 23.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Report, ASAccount;

@protocol ReportSummary <NSObject>

- (Report *)firstReport;
- (NSArray *)allReports;
- (NSDate *)startDate;
- (NSString *)title;
- (float)totalRevenueInBaseCurrency;
- (float)totalRevenueInBaseCurrencyForProductWithID:(NSString *)productID inCountry:(NSString *)country;
- (float)totalRevenueInBaseCurrencyForProductWithID:(NSString *)productID;

- (NSInteger)totalNumberOfPaidDownloadsForProductWithID:(NSString *)productID;
- (NSInteger)totalNumberOfPaidDownloadsForProductWithID:(NSString *)productID inCountry:(NSString *)country;
- (NSDictionary *)totalNumberOfPaidNonRefundDownloadsByCountryAndProduct;
- (NSDictionary *)totalNumberOfRefundedDownloadsByCountryAndProduct;

- (NSInteger)totalNumberOfUpdatesForProductWithID:(NSString *)productID;
- (NSInteger)totalNumberOfEducationalSalesForProductWithID:(NSString *)productID;
- (NSInteger)totalNumberOfGiftPurchasesForProductWithID:(NSString *)productID;
- (NSInteger)totalNumberOfPromoCodeTransactionsForProductWithID:(NSString *)productID;

- (NSDictionary *)totalNumberOfPaidDownloadsByCountryAndProduct;

- (NSDictionary *)revenueInBaseCurrencyByCountry;
- (NSDictionary *)revenueInBaseCurrencyByCountryForProductWithID:(NSString *)productID;

@end
