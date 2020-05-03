//
//  ReportDownloadOperation.h
//  AppSales
//
//  Created by Ole Zorn on 01.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LoginManager.h"

@class ASAccount;

@interface ReportDownloadOperation : NSOperation <LoginManagerDelegate> {
	ASAccount *_account;
	NSString *accessToken;
	NSString *providerID;
	NSMutableDictionary *downloadedVendors;
	NSPersistentStoreCoordinator *psc;
	NSManagedObjectID *accountObjectID;
	UIBackgroundTaskIdentifier backgroundTaskID;
}

@property (readonly) NSInteger downloadCount;
@property (copy) NSManagedObjectID *accountObjectID;

- (instancetype)initWithAccount:(ASAccount *)account;

@end
