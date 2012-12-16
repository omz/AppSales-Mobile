//
//  AppSalesAppDelegate.h
//  AppSales
//
//  Created by Ole Zorn on 30.06.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AccountsViewController.h"
#import "KKPasscodeLock.h"

@class ASAccount;

@interface AppSalesAppDelegate : NSObject <UIApplicationDelegate, UIActionSheetDelegate, AccountsViewControllerDelegate, KKPasscodeViewControllerDelegate>
{
	UIWindow *window;
	
	AccountsViewController *accountsViewController;
	
	NSManagedObjectContext *managedObjectContext;
	NSManagedObjectModel *managedObjectModel;
	NSPersistentStoreCoordinator *persistentStoreCoordinator;
	
	UIPopoverController *accountsPopover;
}

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) AccountsViewController *accountsViewController;
@property (nonatomic, strong) UIPopoverController *accountsPopover;
@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSString *)applicationDocumentsDirectory;
- (NSURL *)applicationSupportDirectory;
- (void)loadAccount:(ASAccount *)account;
- (void)selectAccount:(id)sender;
- (void)showPasscodeLockIfNeeded;

@end
