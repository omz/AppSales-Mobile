//
//  ReportDownloadOperation.h
//  AppSales
//
//  Created by Ole Zorn on 01.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LoginManager.h"

#define kASReportDownloadErrorDescription	@"error"
#define ASReportDownloadFailedNotification	@"ASReportDownloadFailedNotification"

@class ASAccount;

@interface ReportDownloadOperation : NSOperation <LoginManagerDelegate> {
	
	ASAccount *_account;
	NSString *username;
	NSString *password;
	NSString *appPassword;
	NSPersistentStoreCoordinator *psc;
	NSManagedObjectID *accountObjectID;
	NSInteger downloadCount;
}

@property (readonly) NSInteger downloadCount;
@property (copy) NSManagedObjectID *accountObjectID;

- (id)initWithAccount:(ASAccount *)account;

@end
