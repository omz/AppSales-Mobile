//
//  ReportManager.h
//  AppSalesMobile
//
//  Created by Ole Zorn on 10.09.09.
//  Copyright 2009 omz:software. All rights reserved.
//

#import <Foundation/Foundation.h>

#define ReportManagerDownloadedDailyReportsNotification				@"ReportManagerDownloadedDailyReportsNotification"
#define ReportManagerDownloadedWeeklyReportsNotification			@"ReportManagerDownloadedWeeklyReportsNotification"
#define ReportManagerUpdatedDownloadProgressNotification			@"ReportManagerUpdatedDownloadProgressNotification"

@class Day;

@interface ReportManager : NSObject {
	NSMutableDictionary *days;
	NSMutableDictionary *weeks;
	
	BOOL isRefreshing;
	BOOL needsDataSavedToDisk;
	NSString *reportDownloadStatus;
}

@property (readonly) NSDictionary *days;
@property (readonly) NSDictionary *weeks;
@property (readonly) NSString *reportDownloadStatus;

+ (ReportManager *)sharedManager;

- (BOOL)loadReportCache;
- (void)generateReportCache:(NSString *)reportCacheFile;

- (BOOL)isDownloadingReports;
- (void)downloadReports;

- (void)saveData;
- (NSString *)originalReportsPath;
- (NSString *)reportCachePath;

- (void)importReport:(Day *)report;
- (void)deleteDay:(Day *)dayToDelete;


@end
