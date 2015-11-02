//
//  Report.m
//  AppSales
//
//  Created by Ole Zorn on 02.07.11.
//  Copyright (c) 2011 omz:software. All rights reserved.
//

#import "Report.h"
#import "DailyReport.h"
#import "WeeklyReport.h"
#import "ASAccount.h"
#import "Product.h"
#import "Transaction.h"
#import "CurrencyManager.h"

#define kReportColumnDeveloperProceeds		@"royalty price"			//old report format
#define kReportColumnDeveloperProceeds2		@"developer proceeds"
#define kReportColumnCurrencyOfProceeds		@"royalty currency"			//old report format
#define kReportColumnCurrencyOfProceeds2	@"currency of proceeds"
#define kReportColumnTitle					@"title / episode / season"	//old report format
#define kReportColumnTitle2					@"title"
#define kReportColumnSKU					@"vendor identifier"		//old report format
#define kReportColumnSKU2					@"sku"

#define kReportColumnProductTypeIdentifier	@"product type identifier"
#define kReportColumnUnits					@"units"
#define kReportColumnBeginDate				@"begin date"
#define kReportColumnEndDate				@"end date"
#define kReportColumnCountryCode			@"country code"
#define kReportColumnAppleIdentifier		@"apple identifier"
#define kReportColumnParentIdentifier		@"parent identifier"
#define kReportColumnCustomerPrice			@"customer price"
#define kReportColumnPromoCode				@"promo code"
#define kReportColumnVersion				@"version"

@interface ReportCache : NSManagedObject

@property (nonatomic, retain) NSDictionary *content;
@property (nonatomic, retain) Report *report;

@end

@implementation ReportCache

@dynamic content, report;

@end



@implementation Report

@dynamic startDate, transactions, cache;

+ (NSDictionary *)infoForReportCSV:(NSString *)csv
{
	NSMutableArray *rows = [[[csv componentsSeparatedByString:@"\n"] mutableCopy] autorelease];
	if ([rows count] < 3)  {
		return nil;
	}
	
	NSString *headerLine = [[rows objectAtIndex:0] lowercaseString];
	NSArray *columnHeaders = [headerLine componentsSeparatedByString:@"\t"];
	if (![self validateColumnHeaders:columnHeaders]) {
		return nil;
	}
	
	[rows removeObjectAtIndex:0];
	NSString *row = [rows objectAtIndex:0];
	NSArray *rowFields = [row componentsSeparatedByString:@"\t"];
	if ([rowFields count] > [columnHeaders count]) {
		return nil;
	}
	NSMutableDictionary *rowDictionary = [NSMutableDictionary dictionaryWithObjects:rowFields forKeys:[columnHeaders subarrayWithRange:NSMakeRange(0, [rowFields count])]];
	NSString *beginDateString = [rowDictionary objectForKey:kReportColumnBeginDate];
	NSString *endDateString = [rowDictionary objectForKey:kReportColumnEndDate];
	if (!beginDateString || !endDateString) {
		return nil;
	}
	NSDate *beginDate = [self dateFromReportDateString:beginDateString];
	NSDate *endDate = [self dateFromReportDateString:endDateString];
	if (!beginDate || !endDate) {
		return nil;
	}
	BOOL isWeeklyReport = ![beginDate isEqual:endDate];
	return [NSDictionary dictionaryWithObjectsAndKeys:
			((isWeeklyReport) ? kReportInfoClassWeekly : kReportInfoClassDaily), kReportInfoClass,
			beginDate, kReportInfoDate, nil];
}

+ (Report *)insertNewReportWithCSV:(NSString *)csv inAccount:(ASAccount *)account
{
	NSManagedObjectContext *moc = account.managedObjectContext;
	NSSet *allProducts = account.products;
	
	NSMutableDictionary *productsBySKU = [NSMutableDictionary dictionary];
	for (Product *product in allProducts) {
		NSString *SKU = product.SKU;
		if (SKU) [productsBySKU setObject:product forKey:SKU];
	}
	
	NSMutableArray *rows = [[[csv componentsSeparatedByString:@"\n"] mutableCopy] autorelease];
	if ([rows count] < 3)  {
		return nil;
	}
	
	NSString *headerLine = [[rows objectAtIndex:0] lowercaseString];
	NSArray *columnHeaders = [headerLine componentsSeparatedByString:@"\t"];
	if (![self validateColumnHeaders:columnHeaders]) {
		return nil;
	}
	
	[rows removeObjectAtIndex:0];
	Report *report = nil;
	for (NSString *row in rows) {
		row = [row stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		NSArray *rowFields = [row componentsSeparatedByString:@"\t"];
		if ([rowFields count] > [columnHeaders count]) {
			continue;
		}
		NSMutableDictionary *rowDictionary = [NSMutableDictionary dictionaryWithObjects:rowFields forKeys:[columnHeaders subarrayWithRange:NSMakeRange(0, [rowFields count])]];
		NSString *beginDateString = [rowDictionary objectForKey:kReportColumnBeginDate];
		NSString *endDateString = [rowDictionary objectForKey:kReportColumnEndDate];
		if (!beginDateString || !endDateString) continue;
		NSDate *beginDate = [self dateFromReportDateString:beginDateString];
		NSDate *endDate = [self dateFromReportDateString:endDateString];
		if (!report && (!beginDate || !endDate)) {
			//Date couldn't be parsed
			return nil;
		} else {
			[rowDictionary setObject:beginDate forKey:kReportColumnBeginDate];
			[rowDictionary setObject:endDate forKey:kReportColumnEndDate];
		}
		BOOL isWeeklyReport = ![beginDate isEqual:endDate];
		NSString *productName = [rowDictionary objectForKey:kReportColumnTitle];
		if (!productName) productName = [rowDictionary objectForKey:kReportColumnTitle2];
		
		Transaction *transaction = [NSEntityDescription insertNewObjectForEntityForName:@"Transaction" inManagedObjectContext:moc];
		transaction.units = [NSNumber numberWithInteger:[[rowDictionary objectForKey:kReportColumnUnits] integerValue]];
		transaction.type = [rowDictionary objectForKey:kReportColumnProductTypeIdentifier];
		transaction.promoType = [rowDictionary objectForKey:kReportColumnPromoCode];
			
		NSString *developerProceedsColumn = [rowDictionary objectForKey:kReportColumnDeveloperProceeds];
		if (!developerProceedsColumn) developerProceedsColumn = [rowDictionary objectForKey:kReportColumnDeveloperProceeds2];
		NSNumber *revenue = [NSNumber numberWithFloat:[developerProceedsColumn floatValue]];
		transaction.revenue = revenue;
		
		NSString *currencyOfProceedsColumn = [rowDictionary objectForKey:kReportColumnCurrencyOfProceeds];
		if (!currencyOfProceedsColumn) currencyOfProceedsColumn = [rowDictionary objectForKey:kReportColumnCurrencyOfProceeds2];
		[transaction setValue:currencyOfProceedsColumn forKey:@"currency"];
		
		[transaction setValue:[rowDictionary objectForKey:kReportColumnCountryCode] forKey:@"countryCode"];
		NSString *productSKU = [rowDictionary objectForKey:kReportColumnSKU];
		if (!productSKU) productSKU = [rowDictionary objectForKey:kReportColumnSKU2];
		
        if ([productSKU hasSuffix:@" "])
        { // bug in 26th October reports, sku has trailing space
            // first delete 'productSKU plus space' duplicate and clean up the mess
            Product *product = [productsBySKU objectForKey:productSKU];
            if (product)
                [moc deleteObject:product];
            // now fix the SKU so it does not happen again
            int len = (int)productSKU.length;
            productSKU = [productSKU substringToIndex:len-1];
        }
        
		NSString *productVersion = [rowDictionary objectForKey:kReportColumnVersion];
		Product *product = [productsBySKU objectForKey:productSKU];
		if (!product) {
			product = [NSEntityDescription insertNewObjectForEntityForName:@"Product" inManagedObjectContext:moc];
			product.parentSKU = [rowDictionary objectForKey:kReportColumnParentIdentifier];
			product.account = account;
			product.productID = [rowDictionary objectForKey:kReportColumnAppleIdentifier];
			product.SKU = productSKU;
			product.currentVersion = productVersion;
			product.lastModified = beginDate;
			product.name = productName;
			[productsBySKU setObject:product forKey:productSKU];
		}
		if ((productName && ![product.name isEqualToString:productName]) || (productVersion && ![product.currentVersion isEqualToString:productVersion])) {
			if ([beginDate timeIntervalSinceDate:product.lastModified] > 0) {
				//Only update name and version if the current report is newer than the one the product was created with
				product.name = productName;
				product.currentVersion = productVersion;
			}
		}
		[transaction setValue:product forKey:@"product"];
		
		static NSDictionary *platformsByTransactionType = nil;
		if (!platformsByTransactionType) {
			platformsByTransactionType = [[NSDictionary alloc] initWithObjectsAndKeys:
										  kProductPlatformiPhone, @"1",
										  kProductPlatformiPhone, @"7",
										  kProductPlatformUniversal, @"1F",
										  kProductPlatformUniversal, @"7F",
										  kProductPlatformiPad, @"1T",
										  kProductPlatformiPad, @"7T",
										  kProductPlatformMac, @"F1",
										  kProductPlatformMac, @"F7",
										  kProductPlatformInApp, @"IA1",
										  kProductPlatformInApp, @"IA9",
										  nil];
		}
		NSString *platform = [platformsByTransactionType objectForKey:[rowDictionary objectForKey:kReportColumnProductTypeIdentifier]];
		if (platform) {
			product.platform = platform;
		}
		
		if (!report) {
			if (isWeeklyReport) {
				report = [NSEntityDescription insertNewObjectForEntityForName:@"WeeklyReport" inManagedObjectContext:moc];
				[(WeeklyReport *)report setEndDate:endDate];
				[(WeeklyReport *)report setAccount:account];
			} else {
				report = [NSEntityDescription insertNewObjectForEntityForName:@"DailyReport" inManagedObjectContext:moc];
				[(DailyReport *)report setAccount:account];
			}
			report.startDate = beginDate;
		}
		[[report mutableSetValueForKey:@"transactions"] addObject:transaction];
	}
	return report;
}

+ (BOOL)validateColumnHeaders:(NSArray *)columnHeaders
{
	static NSSet *requiredColumnsSet1 = nil;
	static NSSet *requiredColumnsSet2 = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		requiredColumnsSet1 = [[NSSet alloc] initWithObjects:
							   kReportColumnTitle,
							   kReportColumnProductTypeIdentifier,
							   kReportColumnUnits,
							   kReportColumnDeveloperProceeds,
							   kReportColumnBeginDate,
							   kReportColumnEndDate,
							   kReportColumnCountryCode,
							   kReportColumnCurrencyOfProceeds,
							   kReportColumnAppleIdentifier,
							   kReportColumnCustomerPrice,
							   kReportColumnSKU,
							   nil];
		requiredColumnsSet2 = [[NSSet alloc] initWithObjects:
							   kReportColumnTitle2,
							   kReportColumnProductTypeIdentifier,
							   kReportColumnUnits,
							   kReportColumnDeveloperProceeds2,
							   kReportColumnBeginDate,
							   kReportColumnEndDate,
							   kReportColumnCountryCode,
							   kReportColumnCurrencyOfProceeds2,
							   kReportColumnAppleIdentifier,
							   kReportColumnParentIdentifier,
							   kReportColumnCustomerPrice,
							   kReportColumnSKU2,
							   nil];
	});
	
	NSSet *columnHeadersSet = [NSSet setWithArray:columnHeaders];
	if ([requiredColumnsSet1 isSubsetOfSet:columnHeadersSet] || [requiredColumnsSet2 isSubsetOfSet:columnHeadersSet]) {
		return YES;
	}
	return NO;
}

- (void)generateCache
{
	NSMutableDictionary *tmpSummary = [NSMutableDictionary dictionary];
	NSMutableDictionary *revenueByCurrency = [NSMutableDictionary dictionary];
	[tmpSummary setObject:revenueByCurrency forKey:kReportSummaryRevenue];
	NSMutableDictionary *transactionsByType = [NSMutableDictionary dictionary];
	[tmpSummary setObject:transactionsByType forKey:kReportSummaryTransactions];
	
	for (Transaction *transaction in self.transactions) {
		NSString *currency = transaction.currency;
		NSString *productIdentifier = transaction.product.productID;
		float transactionRevenue = [transaction.revenue floatValue];
		NSInteger transactionUnits = [transaction.units integerValue];
		NSString *transactionType = transaction.type;
		if (currency) {
			float revenue = [[[revenueByCurrency objectForKey:productIdentifier] objectForKey:currency] floatValue];
			revenue += (transactionRevenue * transactionUnits);
			NSMutableDictionary *revenuesForProduct = [revenueByCurrency objectForKey:productIdentifier];
			if (!revenuesForProduct) {
				revenuesForProduct = [NSMutableDictionary dictionary];
				[revenueByCurrency setObject:revenuesForProduct forKey:productIdentifier];
			}
			[revenuesForProduct setObject:[NSNumber numberWithFloat:revenue] forKey:currency];
		}
		if (transactionType) {
			NSString *promoType = transaction.promoType;
			//Some old reports have "FREE" as the promo code identifier for updates, in newer reports, the field is empty.
			if (promoType && ![promoType isEqualToString:@"FREE"] && ![promoType isEqualToString:@" "]) {
				transactionType = [NSString stringWithFormat:@"%@.%@", transactionType, promoType];
			}
			NSInteger count = [[[transactionsByType objectForKey:productIdentifier] objectForKey:transactionType] integerValue];
			count += transactionUnits;
			NSMutableDictionary *transactionsForProduct = [transactionsByType objectForKey:productIdentifier];
			if (!transactionsForProduct) {
				transactionsForProduct = [NSMutableDictionary dictionary];
				[transactionsByType setObject:transactionsForProduct forKey:productIdentifier];
			}
			[transactionsForProduct setObject:[NSNumber numberWithInteger:count] forKey:transactionType];
		}
	}
	self.cache = [NSEntityDescription insertNewObjectForEntityForName:@"ReportCache" inManagedObjectContext:self.managedObjectContext];
	self.cache.content = [NSDictionary dictionaryWithDictionary:tmpSummary];
}

- (float)totalRevenueInBaseCurrency
{
	float total = 0.0;
	NSDictionary *revenueByProduct = [self.cache.content objectForKey:kReportSummaryRevenue];
	for (NSString *productID in [revenueByProduct allKeys]) {
		NSDictionary *revenueByCurrency = [revenueByProduct objectForKey:productID];
		for (NSString *currency in [revenueByCurrency allKeys]) {
			float revenue = [[revenueByCurrency objectForKey:currency] floatValue];
			float revenueInBaseCurrency = [[CurrencyManager sharedManager] convertValue:revenue fromCurrency:currency];
			total += revenueInBaseCurrency;
		}
	}
	return total;
}

- (float)totalRevenueInBaseCurrencyForProductWithID:(NSString *)productID
{
	return [self totalRevenueInBaseCurrencyForProductWithID:productID inCountry:nil];
}

- (float)totalRevenueInBaseCurrencyForProductWithID:(NSString *)productID inCountry:(NSString *)country
{
	if (!country) {
		if (!productID) {
			return [self totalRevenueInBaseCurrency];
		}
		float total = 0.0;
		NSDictionary *revenueByProduct = [self.cache.content objectForKey:kReportSummaryRevenue];
		NSDictionary *revenueByCurrency = [revenueByProduct objectForKey:productID];
		for (NSString *currency in revenueByCurrency) {
			float revenue = [[revenueByCurrency objectForKey:currency] floatValue];
			float revenueInBaseCurrency = [[CurrencyManager sharedManager] convertValue:revenue fromCurrency:currency];
			total += revenueInBaseCurrency;
		}
		return total;
	} else {
		float total = 0.0;
		for (Transaction *transaction in self.transactions) {
			if (!productID || [transaction.product.productID isEqualToString:productID]) {
				if (!country || [transaction.countryCode isEqualToString:country]) {
					float revenue = [transaction.revenue floatValue];
					NSString *currency = transaction.currency;
					int units = [transaction.units intValue];
					float revenueInBaseCurrency = [[CurrencyManager sharedManager] convertValue:(revenue * units) fromCurrency:currency];
					total += revenueInBaseCurrency;
				}
			}
		}
		return total;
	}
}

- (int)totalNumberOfPaidDownloads
{
	return [self totalNumberOfPaidDownloadsForProductWithID:nil];
}

- (NSDictionary *)totalNumberOfPaidDownloadsByCountryAndProduct
{
	NSSet *paidTransactionTypes = [[self class] combinedPaidTransactionTypes];
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	for (Transaction *transaction in self.transactions) {
		NSString *type = transaction.type;
		NSString *promoType = transaction.promoType;
		if(promoType != nil) {
			promoType = [promoType stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			if([promoType isEqualToString:@""])promoType = nil;
		}
		NSString *combinedType = (promoType != nil) ? [NSString stringWithFormat:@"%@.%@", type, promoType] : type;
		if (![paidTransactionTypes containsObject:combinedType]) {
			continue;
		}
		NSString *transactionCountry = transaction.countryCode;
		NSString *transactionProductID = transaction.product.productID;
		NSMutableDictionary *paidDownloadsByProduct = [result objectForKey:transactionCountry];
		if (!paidDownloadsByProduct) {
			paidDownloadsByProduct = [NSMutableDictionary dictionary];
			[result setObject:paidDownloadsByProduct forKey:transactionCountry];
		}
		NSInteger oldNumberOfPaidDownloads = [[paidDownloadsByProduct objectForKey:transactionProductID] integerValue];
		NSInteger newNumberOfPaidDownloads = oldNumberOfPaidDownloads + [transaction.units integerValue];
		[paidDownloadsByProduct setObject:[NSNumber numberWithInteger:newNumberOfPaidDownloads] forKey:transactionProductID];
	}
	return result;
}

- (int)totalNumberOfPaidDownloadsForProductWithID:(NSString *)productID inCountry:(NSString *)country
{
	NSSet *paidTransactionTypes = [[self class] paidTransactionTypes];
	NSInteger total = 0;
	for (Transaction *transaction in self.transactions) {
		NSString *type = transaction.type;
		if (![paidTransactionTypes containsObject:type]) {
			continue;
		}
		if (country) {
			NSString *transactionCountry = transaction.countryCode;
			if (![transactionCountry isEqualToString:country]) {
				continue;
			}
		}
		if (productID) {
			NSString *transactionProductID = transaction.product.productID;
			if (![transactionProductID isEqualToString:productID]) {
				continue;
			}
		}
		NSNumber *units = transaction.units;
		total += [units integerValue];
	}
	return total;
}

- (int)totalNumberOfPaidDownloadsForProductWithID:(NSString *)productID
{
	return [self totalNumberOfTransactionsInSet:[[self class] combinedPaidTransactionTypes] forProductWithID:productID];
}

- (int)totalNumberOfUpdatesForProductWithID:(NSString *)productID
{
	return [self totalNumberOfTransactionsInSet:[[self class] combinedUpdateTransactionTypes] forProductWithID:productID];
}

- (int)totalNumberOfEducationalSalesForProductWithID:(NSString *)productID
{
	return [self totalNumberOfTransactionsInSet:[[self class] combinedEducationalTransactionTypes] forProductWithID:productID];
}

- (int)totalNumberOfGiftPurchasesForProductWithID:(NSString *)productID
{
	return [self totalNumberOfTransactionsInSet:[[self class] combinedGiftPurchaseTransactionTypes] forProductWithID:productID];
}

- (int)totalNumberOfPromoCodeTransactionsForProductWithID:(NSString *)productID
{
	return [self totalNumberOfTransactionsInSet:[[self class] combinedPromoCodeTransactionTypes] forProductWithID:productID];
}

- (int)totalNumberOfTransactionsInSet:(NSSet *)transactionTypes forProductWithID:(NSString *)productID
{
	int total = 0;
	NSDictionary *transactionsByProduct = [self.cache.content objectForKey:kReportSummaryTransactions];
	if (productID) {
		NSDictionary *transactionsByType = [transactionsByProduct objectForKey:productID];
		for (NSString *transactionType in transactionsByType) {
			if ([transactionTypes containsObject:transactionType]) {
				total += [[transactionsByType objectForKey:transactionType] intValue];
			}
		}
	} else {
		for (NSString *productID in transactionsByProduct) {
			NSDictionary *transactionsByType = [transactionsByProduct objectForKey:productID];
			for (NSString *transactionType in transactionsByType) {
				if ([transactionTypes containsObject:transactionType]) {
					total += [[transactionsByType objectForKey:transactionType] intValue];
				}
			}
		}
	}
	return total;
}

+ (NSSet *)combinedPaidTransactionTypes
{
	static NSSet *combinedPaidTransactionTypes = nil;
	if (!combinedPaidTransactionTypes) {
		combinedPaidTransactionTypes = [[NSSet alloc] initWithObjects:
							@"1",		//iPhone App
							@"1. ",		//iPhone App
							@"1F",		//Universal App
							@"1F. ",	//Universal App
							@"1T",		//iPad App
							@"1T. ",	//iPad App
							@"F1",		//Mac App
							@"F1. ",	//Mac App
							@"IA1",		//In-App Purchase
							@"IA1. ",	//In-App Purchase
							@"IA9",		//In-App Subscription
							@"IA9. ",	//In-App Subscription
							@"1.GP",	//GP = Gift Purchase
							@"1F.GP",
							@"1T.GP",
							@"F1.GP",
							@"IA1.GP",
							@"IA9.GP",
							@"1.EDU",	//EDU = Education Store transaction
							@"1F.EDU",
							@"1T.EDU",
							@"F1.EDU",
							@"IA1.EDU",
							@"IA9.EDU",
							nil];
	}
	return combinedPaidTransactionTypes;
}

+ (NSSet *)combinedUpdateTransactionTypes
{
	static NSSet *combinedUpdateTransactionTypes = nil;
	if (!combinedUpdateTransactionTypes) {
		combinedUpdateTransactionTypes = [[NSSet alloc] initWithObjects:
										@"7",		//iPhone App
										@"7F",		//Universal App
										@"7T",		//iPad App
										@"F7",		//Mac App
										@"7.GP",	//GP = Gift Purchase
										@"7F.GP",
										@"7T.GP",
										@"F7.GP",
										@"7.EDU",	//EDU = Education Store transaction
										@"7F.EDU",
										@"7T.EDU",
										@"F7.EDU",
										nil];
	}
	return combinedUpdateTransactionTypes;
}

+ (NSSet *)combinedEducationalTransactionTypes
{
	static NSSet *combinedEducationalTransactionTypes = nil;
	if (!combinedEducationalTransactionTypes) {
		combinedEducationalTransactionTypes = [[NSSet alloc] initWithObjects:
										@"1.EDU",
										@"1F.EDU",
										@"1T.EDU",
										@"F1.EDU",
										@"IA1.EDU",
										@"IA9.EDU",
										nil];
	}
	return combinedEducationalTransactionTypes;
}

+ (NSSet *)combinedGiftPurchaseTransactionTypes
{
	static NSSet *combinedGiftPurchaseTransactionTypes = nil;
	if (!combinedGiftPurchaseTransactionTypes) {
		combinedGiftPurchaseTransactionTypes = [[NSSet alloc] initWithObjects:
										@"1.GP",	//GP = Gift Purchase
										@"1F.GP",
										@"1T.GP",
										@"F1.GP",
										@"IA1.GP",
										@"IA9.GP",
										nil];
	}
	return combinedGiftPurchaseTransactionTypes;
}

+ (NSSet *)combinedPromoCodeTransactionTypes
{
	static NSSet *combinedPromoCodeTransactionTypes = nil;
	if (!combinedPromoCodeTransactionTypes) {
		combinedPromoCodeTransactionTypes = [[NSSet alloc] initWithObjects:
												@"1.CR-RW",
												@"1F.CR-RW",
												@"1T.CR-RW",
												@"F1.CR-RW",
												@"IA1.CR-RW",
												@"IA9.CR-RW",
												nil];
	}
	return combinedPromoCodeTransactionTypes;
}

+ (NSSet *)paidTransactionTypes
{
	static NSSet *paidTransactionTypes = nil;
	if (!paidTransactionTypes) {
		paidTransactionTypes = [[NSSet alloc] initWithObjects:
								@"1",		//iPhone App
								@"1F",		//Universal App
								@"1T",		//iPad App
								@"F1",		//Mac App
								@"IA1",		//In-App Purchase
								@"IA9",		//In-App Subscription
								nil];
	}
	return paidTransactionTypes;
}

- (NSDictionary *)revenueInBaseCurrencyByCountry
{
	return [self revenueInBaseCurrencyByCountryForProductWithID:nil];
}

- (NSDictionary *)revenueInBaseCurrencyByCountryForProductWithID:(NSString *)productID
{
	NSMutableDictionary *revenueByCountry = [NSMutableDictionary dictionary];
	for (Transaction *transaction in self.transactions) {
		if (productID && ![transaction.product.productID isEqualToString:productID]) {
			continue;
		}
		float revenue = [transaction.revenue floatValue];
		NSString *currency = transaction.currency;
		int units = [transaction.units intValue];
		float revenueInBaseCurrency = [[CurrencyManager sharedManager] convertValue:(revenue * units) fromCurrency:currency];
		NSString *country = transaction.countryCode;
		float oldRevenue = [[revenueByCountry objectForKey:country] floatValue];
		float newRevenue = oldRevenue + revenueInBaseCurrency;
		[revenueByCountry setObject:[NSNumber numberWithFloat:newRevenue] forKey:country];
	}
	return revenueByCountry;
}

- (Report *)firstReport
{
	//ReportSummary protocol method, allows us to treat "virtual" reports (like months) the same as actual reports in many situations.
	return self;
}

- (NSArray *)allReports
{
	//ReportSummary protocol method, allows us to treat "virtual" reports (like months) the same as actual reports in many situations.
	return [NSArray arrayWithObject:self];
}

- (NSString *)title
{
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	return [dateFormatter stringFromDate:self.startDate];
}

+ (NSDate *)dateFromReportDateString:(NSString *)dateString
{
	dateString = [dateString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	BOOL containsSlash = [dateString rangeOfString:@"/"].location != NSNotFound;
	int year, month, day;
	if (!containsSlash && [dateString length] == 8) {
        //old date format
		year = [[dateString substringWithRange:NSMakeRange(0, 4)] intValue];
		month = [[dateString substringWithRange:NSMakeRange(4, 2)] intValue];
		day = [[dateString substringWithRange:NSMakeRange(6, 2)] intValue];
    } else if (containsSlash && [dateString length] == 10) {
		// new date format
		year = [[dateString substringWithRange:NSMakeRange(6, 4)] intValue];
		month = [[dateString substringWithRange:NSMakeRange(0, 2)] intValue];
		day = [[dateString substringWithRange:NSMakeRange(3, 2)] intValue];
	} else {
		return nil;
	}
	
	NSCalendar *calendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	[calendar setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	NSDateComponents *components = [[NSDateComponents alloc] init];
	[components setYear:year];
	[components setMonth:month];
	[components setDay:day];
	NSDate *date = [calendar dateFromComponents:components];
	[components release];
	return date;
}

+ (NSString *)identifierForDate:(NSDate *)date
{
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"MM/dd/yyyy"];
	[formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	NSString *reportIdentifier = [formatter stringFromDate:date];
	[formatter release];
	return reportIdentifier;
}

@end
