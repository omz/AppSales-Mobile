//
//  IconManager.h
//  AppSales
//
//  Created by Ole Zorn on 20.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kIconManagerDownloadedIconNotificationAppID		@"appID"
#define IconManagerDownloadedIconNotification			@"IconManagerDownloadedIconNotification"
#define kIconManagerClearedIconNotificationAppID		@"appID"
#define IconManagerClearedIconNotification              @"IconManagerClearedIconNotification"

@interface IconManager : NSObject {
	
	dispatch_queue_t queue;
	NSMutableDictionary *iconCache;
	NSMutableArray *downloadQueue;
	BOOL isDownloading;
}

+ (id)sharedManager;
- (NSString *)iconDirectory;
- (UIImage *)iconForAppID:(NSString *)appID;
- (void)clearIconForAppID:(NSString *)appID;

@end
