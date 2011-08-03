//
//  AppSalesAppDelegate.h
//  AppSales
//
//  Created by Ole Zorn on 30.06.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppSalesAppDelegate : NSObject <UIApplicationDelegate>
{
	UIWindow *window;
	
	NSManagedObjectContext *managedObjectContext;
	NSManagedObjectModel *managedObjectModel;
	NSPersistentStoreCoordinator *persistentStoreCoordinator;
}

@property (nonatomic, retain) UIWindow *window;

@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (BOOL)migrateDataIfNeeded;
- (void)saveContext;
- (NSString *)applicationDocumentsDirectory;
- (NSURL *)applicationSupportDirectory;

@end
