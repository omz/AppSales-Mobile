//
//  ReportImportOperation.h
//  AppSales
//
//  Created by Ole Zorn on 09.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ASAccount;

@interface ReportImportOperation : NSOperation {

	ASAccount *_account;
	NSPersistentStoreCoordinator *psc;
	NSManagedObjectID *accountObjectID;
	
	NSString *importDirectory;
	BOOL deleteOriginalFilesAfterImport;
}

@property (retain) NSString *importDirectory;
@property (assign) BOOL deleteOriginalFilesAfterImport;

+ (BOOL)filesAvailableToImport;
- (id)initWithAccount:(ASAccount *)account;

@end
