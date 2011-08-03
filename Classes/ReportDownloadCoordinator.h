//
//  ReportDownloadCoordinator.h
//  AppSales
//
//  Created by Ole Zorn on 01.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Account;

@interface ReportDownloadCoordinator : NSObject {
	
	NSOperationQueue *reportDownloadQueue;
	BOOL isBusy;
}

@property (nonatomic, assign) BOOL isBusy;

+ (id)sharedReportDownloadCoordinator;
- (void)downloadReportsForAccount:(Account *)account;
- (void)cancelDownloadForAccount:(Account *)account;
- (void)importReportsIntoAccount:(Account *)account;
- (void)importReportsIntoAccount:(Account *)account fromDirectory:(NSString *)path deleteAfterImport:(BOOL)deleteFlag;

@end
