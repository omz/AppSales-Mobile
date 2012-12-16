//
//  ReportDownloadCoordinator.h
//  AppSales
//
//  Created by Ole Zorn on 01.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ASAccount, Product;

@interface ReportDownloadCoordinator : NSObject {
	
	NSOperationQueue *reportDownloadQueue;
	BOOL isBusy;
}

@property (nonatomic, assign) BOOL isBusy;

+ (id)sharedReportDownloadCoordinator;
- (void)downloadReportsForAccount:(ASAccount *)account;
- (void)cancelDownloadForAccount:(ASAccount *)account;
- (void)cancelAllDownloads;
- (void)importReportsIntoAccount:(ASAccount *)account;
- (void)importReportsIntoAccount:(ASAccount *)account fromDirectory:(NSString *)path deleteAfterImport:(BOOL)deleteFlag;

@end
