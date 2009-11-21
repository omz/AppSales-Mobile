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
#define ReportManagerDownloadedReviewsNotification					@"ReportManagerDownloadedReviewsNotification"
#define ReportManagerUpdatedReviewDownloadProgressNotification		@"ReportManagerUpdatedReviewDownloadProgressNotification"

@class Day;

@interface ReportManager : NSObject {

	NSMutableDictionary *days;
	NSMutableDictionary *weeks;
	NSMutableArray      *backupList;
	
	BOOL isRefreshing;
	NSString *reportDownloadStatus;
	
	int retryIfBackupFailure;
	BOOL backupReviewsFile;
	
	NSMutableDictionary *appsByID;
	BOOL isDownloadingReviews;
	NSString *reviewDownloadStatus;
}

@property (retain) NSMutableDictionary *days;
@property (retain) NSMutableDictionary *weeks;
@property (retain) NSMutableArray      *backupList;
@property (retain) NSMutableDictionary *appsByID;
@property (retain) NSString *reviewDownloadStatus;
@property (retain) NSString *reportDownloadStatus;

+ (ReportManager *)sharedManager;
- (BOOL)isDownloadingReports;
- (void)downloadReports;

- (void)setProgress:(NSString *)status;

- (Day *)dayWithData:(NSData *)dayData compressed:(BOOL)compressed;
- (void)saveData;
- (void)backupData;
- (NSString *)docPath;
- (NSString *)prefetchedPath;

- (void)deleteDay:(Day *)dayToDelete;

- (void)downloadReviewsForTopCountriesOnly:(BOOL)topCountriesOnly;
- (void)updateReviewDownloadProgress:(NSString *)status;
- (BOOL)isDownloadingReviews;
- (NSString *)reviewDownloadStatus;

@end
