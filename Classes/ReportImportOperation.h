//
//  ReportImportOperation.h
//  AppSales
//
//  Created by Ole Zorn on 09.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Account;

@interface ReportImportOperation : NSOperation {

	Account *_account;
	NSPersistentStoreCoordinator *psc;
	NSManagedObjectID *accountObjectID;
	
	NSString *importDirectory;
	BOOL deleteOriginalFilesAfterImport;
}

@property (retain) NSString *importDirectory;
@property (assign) BOOL deleteOriginalFilesAfterImport;

+ (BOOL)filesAvailableToImport;
- (id)initWithAccount:(Account *)account;

@end
