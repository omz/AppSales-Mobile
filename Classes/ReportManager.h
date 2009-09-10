//
//  ReportManager.h
//  AppSalesMobile
//
//  Created by Ole Zorn on 10.09.09.
//  Copyright 2009 omz:software. All rights reserved.
//

#import <Foundation/Foundation.h>

#define ReportManagerDownloadedDailyReportsNotification		@"ReportManagerDownloadedDailyReportsNotification"
#define ReportManagerDownloadedWeeklyReportsNotification	@"ReportManagerDownloadedWeeklyReportsNotification"
#define ReportManagerUpdatedDownloadProgressNotification	@"ReportManagerUpdatedDownloadProgressNotification"

@class Day;

@interface ReportManager : NSObject {

	NSMutableDictionary *days;
	NSMutableDictionary *weeks;
	BOOL isRefreshing;
	
	float downloadProgress;
}

@property (retain) NSMutableDictionary *days;
@property (retain) NSMutableDictionary *weeks;

+ (ReportManager *)sharedManager;
- (void)downloadReports;

- (void)setProgress:(NSNumber *)progress;
- (float)downloadProgress;

- (Day *)dayWithData:(NSData *)dayData compressed:(BOOL)compressed;
- (void)saveData;
- (NSString *)docPath;

- (void)deleteDay:(Day *)dayToDelete;

@end
