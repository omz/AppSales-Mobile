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

- (int)totalNumberOfPaidDownloadsForProductWithID:(NSString *)productID;
- (int)totalNumberOfPaidDownloadsForProductWithID:(NSString *)productID inCountry:(NSString *)country;

- (int)totalNumberOfUpdatesForProductWithID:(NSString *)productID;
- (int)totalNumberOfEducationalSalesForProductWithID:(NSString *)productID;
- (int)totalNumberOfGiftPurchasesForProductWithID:(NSString *)productID;
- (int)totalNumberOfPromoCodeTransactionsForProductWithID:(NSString *)productID;

- (NSDictionary *)totalNumberOfPaidDownloadsByCountryAndProduct;

- (NSDictionary *)revenueInBaseCurrencyByCountry;
- (NSDictionary *)revenueInBaseCurrencyByCountryForProductWithID:(NSString *)productID;

@end
