//
//  ReportDownloadCoordinator.m
//  AppSales
//
//  Created by Ole Zorn on 01.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "ReportDownloadCoordinator.h"
#import "ReportDownloadOperation.h"
#import "ReportImportOperation.h"
#import "ASAccount.h"
#import "Product.h"
#import "PromoCodeOperation.h"

@implementation ReportDownloadCoordinator

- (instancetype)init {
	self = [super init];
	if (self) {
		reportDownloadQueue = [[NSOperationQueue alloc] init];
		reportDownloadQueue.maxConcurrentOperationCount = 1;
		reportDownloadQueue.qualityOfService = NSQualityOfServiceUserInitiated;
		[reportDownloadQueue addObserver:self forKeyPath:@"operationCount" options:NSKeyValueObservingOptionNew context:nil];
	}
	return self;
}

+ (instancetype)sharedReportDownloadCoordinator {
	static id sharedCoordinator = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedCoordinator = [[self alloc] init];
	});
	return sharedCoordinator;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"operationCount"]) {
		isBusy = (reportDownloadQueue.operationCount > 0);
	}
}

- (BOOL)isBusy {
	return isBusy;
}

- (void)downloadReportsForAccount:(ASAccount *)account {
	if (account.isDownloadingReports) { return; }
	ReportDownloadOperation *operation = [[ReportDownloadOperation alloc] initWithAccount:account];
	account.isDownloadingReports = YES;
	account.downloadStatus = NSLocalizedString(@"Waiting...", nil);
	account.downloadProgress = 0.0;
	[reportDownloadQueue addOperation:operation];
}

- (void)cancelDownloadForAccount:(ASAccount *)account {
	if (!account.isDownloadingReports) { return; }
	account.downloadStatus = NSLocalizedString(@"Canceling...", nil);
	for (NSOperation *operation in reportDownloadQueue.operations) {
		if ([operation isKindOfClass:[ReportDownloadOperation class]] && [((ReportDownloadOperation *)operation).accountObjectID isEqual:account.objectID]) {
			[operation cancel];
		}
	}
}

- (void)downloadPromoCodesForProduct:(Product *)product numberOfCodes:(NSInteger)numberOfCodes {
	if (product.isDownloadingPromoCodes) { return; }
	product.isDownloadingPromoCodes = YES;
	PromoCodeOperation *operation = [[PromoCodeOperation alloc] initWithProduct:product numberOfCodes:numberOfCodes];
	operation.completionBlock = ^{
		dispatch_async(dispatch_get_main_queue(), ^{
			product.isDownloadingPromoCodes = NO;
		});
	};
	[reportDownloadQueue addOperation:operation];
}

- (void)cancelAllDownloads {
	[reportDownloadQueue cancelAllOperations];
}

- (void)importReportsIntoAccount:(ASAccount *)account {
	[self importReportsIntoAccount:account fromDirectory:nil deleteAfterImport:NO];
}

- (void)importReportsIntoAccount:(ASAccount *)account fromDirectory:(NSString *)path deleteAfterImport:(BOOL)deleteFlag {
	ReportImportOperation *operation = [[ReportImportOperation alloc] initWithAccount:account];
	operation.importDirectory = path;
	operation.deleteOriginalFilesAfterImport = deleteFlag;
	account.isDownloadingReports = YES;
	[[UIApplication sharedApplication] setIdleTimerDisabled:YES];
	UIBackgroundTaskIdentifier backgroundTaskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^(void) {
		NSLog(@"Background task for importing has expired!");
	}];
	[operation setCompletionBlock:^{
		dispatch_async(dispatch_get_main_queue(), ^{
			account.isDownloadingReports = NO;
			[[UIApplication sharedApplication] setIdleTimerDisabled:NO];
			if (backgroundTaskID != UIBackgroundTaskInvalid) {
				[[UIApplication sharedApplication] endBackgroundTask:backgroundTaskID];
			}
		});
	}];
	[reportDownloadQueue addOperation:operation];
}

- (void)dealloc {
	[reportDownloadQueue removeObserver:self forKeyPath:@"operationCount"];
}

@end
