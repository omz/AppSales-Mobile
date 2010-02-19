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

// only needed if using backup feature.  See comments in upload_appsales.php file.
//#define BACKUP_HOSTNAME \
//	@"http://<computer-name>.local/~<username>/upload_appsales.php"

@class Day;

@interface ReportManager : NSObject {
	NSMutableDictionary *days;
	NSMutableDictionary *weeks;
	NSMutableArray      *backupList;
	
	BOOL isRefreshing;
	BOOL needsDataSavedToDisk;
	NSString *reportDownloadStatus;
	
	int retryIfBackupFailure;
	BOOL backupReviewsFile;
	
	// temporary fields, used while fetching reports
	NSString *username;
	NSString *password;
	NSArray *weeksToSkip;
	NSArray *daysToSkip;
}

@property (readonly) NSDictionary *days;
@property (readonly) NSDictionary *weeks;
@property (readonly) NSString *reportDownloadStatus;

+ (ReportManager *)sharedManager;

- (BOOL)isDownloadingReports;
- (void)downloadReports;
- (void)loadSavedFiles;

- (Day *)dayWithData:(NSData *)dayData compressed:(BOOL)compressed;
- (void)backupData; // backup to a remote host

- (void)deleteDay:(Day *)dayToDelete;

@end
