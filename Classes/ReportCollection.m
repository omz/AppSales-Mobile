//
//  ReportCollection.m
//  AppSales
//
//  Created by Ole Zorn on 23.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "ReportCollection.h"
#import "Report.h"

@implementation ReportCollection

@synthesize title;

- (instancetype)initWithReports:(NSArray *)reportsArray {
	self = [super init];
	if (self) {
		reports = reportsArray;
	}
	return self;
}

- (NSDate *)startDate {
	Report *firstReport = reports[0];
	return firstReport.startDate;
}

- (float)totalRevenueInBaseCurrency {
	return [[reports valueForKeyPath:@"@sum.totalRevenueInBaseCurrency"] floatValue];
}

- (float)totalRevenueInBaseCurrencyForProductWithID:(NSString *)productID {
	float sum = 0.0;
	for (Report *report in reports) {
		sum += [report totalRevenueInBaseCurrencyForProductWithID:productID];
	}
	return sum;
}

- (NSInteger)totalNumberOfPaidDownloadsForProductWithID:(NSString *)productID {
	NSInteger total = 0;
	for (Report *report in reports) {
		total += [report totalNumberOfPaidDownloadsForProductWithID:productID];
	}
	return total;
}

- (NSInteger)totalNumberOfUpdatesForProductWithID:(NSString *)productID {
	NSInteger total = 0;
	for (Report *report in reports) {
		total += [report totalNumberOfUpdatesForProductWithID:productID];
	}
	return total;
}

- (NSInteger)totalNumberOfRedownloadsForProductWithID:(NSString *)productID {
	NSInteger total = 0;
	for (Report *report in reports) {
		total += [report totalNumberOfRedownloadsForProductWithID:productID];
	}
	return total;
}

- (NSInteger)totalNumberOfEducationalSalesForProductWithID:(NSString *)productID {
	NSInteger total = 0;
	for (Report *report in reports) {
		total += [report totalNumberOfEducationalSalesForProductWithID:productID];
	}
	return total;
}

- (NSInteger)totalNumberOfGiftPurchasesForProductWithID:(NSString *)productID {
	NSInteger total = 0;
	for (Report *report in reports) {
		total += [report totalNumberOfGiftPurchasesForProductWithID:productID];
	}
	return total;
}

- (NSInteger)totalNumberOfPromoCodeTransactionsForProductWithID:(NSString *)productID {
	NSInteger total = 0;
	for (Report *report in reports) {
		total += [report totalNumberOfPromoCodeTransactionsForProductWithID:productID];
	}
	return total;
}

- (NSInteger)totalNumberOfPaidDownloadsForProductWithID:(NSString *)productID inCountry:(NSString *)country {
	NSInteger total = 0;
	for (Report *report in reports) {
		total += [report totalNumberOfPaidDownloadsForProductWithID:productID inCountry:country];
	}
	return total;
}

- (NSDictionary *)totalNumberOfPaidDownloadsByCountryAndProduct {
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	for (Report *report in reports) {
		NSDictionary *paidDownloadsForReport = [report totalNumberOfPaidDownloadsByCountryAndProduct];
		for (NSString *country in paidDownloadsForReport) {
			NSMutableDictionary *paidDownloadsByProductResult = result[country];
			if (!paidDownloadsByProductResult) {
				paidDownloadsByProductResult = [NSMutableDictionary dictionary];
				[result setObject:paidDownloadsByProductResult forKey:country];
			}
			NSDictionary *paidDownloadsByProduct = paidDownloadsForReport[country];
			for (NSString *productID in paidDownloadsByProduct) {
				NSInteger oldValue = [paidDownloadsByProductResult[productID] integerValue];
				NSInteger newValue = oldValue + [paidDownloadsByProduct[productID] integerValue];
				[paidDownloadsByProductResult setObject:@(newValue) forKey:productID];
			}
		}
	}
	return result;
}

- (NSDictionary *)totalNumberOfPaidNonRefundDownloadsByCountryAndProduct {
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	for (Report *report in reports) {
		NSDictionary *paidDownloadsForReport = [report totalNumberOfPaidNonRefundDownloadsByCountryAndProduct];
		for (NSString *country in paidDownloadsForReport) {
			NSMutableDictionary *paidDownloadsByProductResult = result[country];
			if (!paidDownloadsByProductResult) {
				paidDownloadsByProductResult = [NSMutableDictionary dictionary];
				[result setObject:paidDownloadsByProductResult forKey:country];
			}
			NSDictionary *paidDownloadsByProduct = paidDownloadsForReport[country];
			for (NSString *productID in paidDownloadsByProduct) {
				NSInteger oldValue = [paidDownloadsByProductResult[productID] integerValue];
				NSInteger newValue = oldValue + [paidDownloadsByProduct[productID] integerValue];
				[paidDownloadsByProductResult setObject:@(newValue) forKey:productID];
			}
		}
	}
	return result;
}

- (NSDictionary *)totalNumberOfRefundedDownloadsByCountryAndProduct {
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	for (Report *report in reports) {
		NSDictionary *paidDownloadsForReport = [report totalNumberOfRefundedDownloadsByCountryAndProduct];
		for (NSString *country in paidDownloadsForReport) {
			NSMutableDictionary *paidDownloadsByProductResult = result[country];
			if (!paidDownloadsByProductResult) {
				paidDownloadsByProductResult = [NSMutableDictionary dictionary];
				[result setObject:paidDownloadsByProductResult forKey:country];
			}
			NSDictionary *paidDownloadsByProduct = paidDownloadsForReport[country];
			for (NSString *productID in paidDownloadsByProduct) {
				NSInteger oldValue = [paidDownloadsByProductResult[productID] integerValue];
				NSInteger newValue = oldValue + [paidDownloadsByProduct[productID] integerValue];
				[paidDownloadsByProductResult setObject:@(newValue) forKey:productID];
			}
		}
	}
	return result;
}

- (NSDictionary *)revenueInBaseCurrencyByCountry {
	NSMutableDictionary *revenueByCountry = [NSMutableDictionary dictionary];
	for (Report *report in reports) {
		NSDictionary *revenueByCountryForReport = [report revenueInBaseCurrencyByCountry];
		for (NSString *country in revenueByCountryForReport) {
			float revenueForCountryInReport = [revenueByCountryForReport[country] floatValue];
			float totalRevenueForCountry = [revenueByCountry[country] floatValue];
			[revenueByCountry setObject:@(totalRevenueForCountry + revenueForCountryInReport) forKey:country];
		}
	}
	return revenueByCountry;
}

- (NSDictionary *)revenueInBaseCurrencyByCountryForProductWithID:(NSString *)productID {
	if (!productID) {
		return [self revenueInBaseCurrencyByCountry];
	}
	NSMutableDictionary *revenueByCountry = [NSMutableDictionary dictionary];
	for (Report *report in reports) {
		NSDictionary *revenueByCountryForReport = [report revenueInBaseCurrencyByCountryForProductWithID:productID];
		for (NSString *country in revenueByCountryForReport) {
			float revenueForCountryInReport = [revenueByCountryForReport[country] floatValue];
			float totalRevenueForCountry = [revenueByCountry[country] floatValue];
			[revenueByCountry setObject:@(totalRevenueForCountry + revenueForCountryInReport) forKey:country];
		}
	}
	return revenueByCountry;
}

- (float)totalRevenueInBaseCurrencyForProductWithID:(NSString *)productID inCountry:(NSString *)country {
	float total = 0.0;
	for (Report *report in reports) {
		total += [report totalRevenueInBaseCurrencyForProductWithID:productID inCountry:country];
	}
	return total;
}

- (Report *)firstReport {
	return reports[0];
}

- (NSArray *)allReports {
	return [NSArray arrayWithArray:reports];
}

- (ASAccount *)account {
	return [[self firstReport] valueForKey:@"account"];
}


@end
