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

@implementation ReportDownloadCoordinator

@synthesize isBusy;

- (id)init
{
    self = [super init];
    if (self) {
		reportDownloadQueue = [[NSOperationQueue alloc] init];
		reportDownloadQueue.maxConcurrentOperationCount = 1;
		[reportDownloadQueue addObserver:self forKeyPath:@"operationCount" options:NSKeyValueObservingOptionNew context:nil];
    }
	return self;
}

+ (id)sharedReportDownloadCoordinator
{
	static id sharedCoordinator = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedCoordinator = [[self alloc] init];
	});
	return sharedCoordinator;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualToString:@"operationCount"]) {
		self.isBusy = (reportDownloadQueue.operationCount > 0);
	}
}

- (void)downloadReportsForAccount:(ASAccount *)account
{
	if (account.isDownloadingReports) {
		return;
	}
	ReportDownloadOperation *operation = [[[ReportDownloadOperation alloc] initWithAccount:account] autorelease];
	account.isDownloadingReports = YES;
	account.downloadStatus = NSLocalizedString(@"Waiting...", nil);
	account.downloadProgress = 0.0;
	[[UIApplication sharedApplication] setIdleTimerDisabled:YES];
	UIBackgroundTaskIdentifier backgroundTaskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^(void) {
		NSLog(@"Background task for downloading reports has expired!");
	}];
	[operation setCompletionBlock:^ {
		dispatch_async(dispatch_get_main_queue(), ^ {
			account.isDownloadingReports = NO;
			if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) {
				NSInteger numberOfReportsDownloaded = operation.downloadCount;
				[[UIApplication sharedApplication] setApplicationIconBadgeNumber:numberOfReportsDownloaded];
			}
			[[UIApplication sharedApplication] setIdleTimerDisabled:NO];
			if (backgroundTaskID != UIBackgroundTaskInvalid) {
				[[UIApplication sharedApplication] endBackgroundTask:backgroundTaskID];
			}
		});
	}];
	[reportDownloadQueue addOperation:operation];
}

- (void)cancelDownloadForAccount:(ASAccount *)account
{
	if (!account.isDownloadingReports) return;
	account.downloadStatus = NSLocalizedString(@"Cancelling...", nil);
	for (NSOperation *operation in [reportDownloadQueue operations]) {
		if ([operation isKindOfClass:[ReportDownloadOperation class]] && [[(ReportDownloadOperation *)operation accountObjectID] isEqual:account.objectID]) {
			[operation cancel];
		}
	}
}

- (void)cancelAllDownloads
{
	[reportDownloadQueue cancelAllOperations];
}

- (void)importReportsIntoAccount:(ASAccount *)account
{
	[self importReportsIntoAccount:account fromDirectory:nil deleteAfterImport:NO];
}

- (void)importReportsIntoAccount:(ASAccount *)account fromDirectory:(NSString *)path deleteAfterImport:(BOOL)deleteFlag
{
	ReportImportOperation *operation = [[[ReportImportOperation alloc] initWithAccount:account] autorelease];
	operation.importDirectory = path;
	operation.deleteOriginalFilesAfterImport = deleteFlag;
	account.isDownloadingReports = YES;
	[[UIApplication sharedApplication] setIdleTimerDisabled:YES];
	UIBackgroundTaskIdentifier backgroundTaskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^(void) {
		NSLog(@"Background task for importing has expired!");
	}];
	[operation setCompletionBlock:^ {
		dispatch_async(dispatch_get_main_queue(), ^ {
			account.isDownloadingReports = NO;
			[[UIApplication sharedApplication] setIdleTimerDisabled:NO];
			if (backgroundTaskID != UIBackgroundTaskInvalid) {
				[[UIApplication sharedApplication] endBackgroundTask:backgroundTaskID];
			}
		});
	}];
	[reportDownloadQueue addOperation:operation];
}

- (void)dealloc
{
	[reportDownloadQueue removeObserver:self forKeyPath:@"operationCount"];
	[reportDownloadQueue release];
	[super dealloc];
}

@end
