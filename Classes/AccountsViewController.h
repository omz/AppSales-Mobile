//
//  RootViewController.h
//  AppSales
//
//  Created by Ole Zorn on 30.06.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FieldEditorViewController.h"

@class Account;

@interface AccountsViewController : UITableViewController <NSFetchedResultsControllerDelegate, UIAlertViewDelegate, FieldEditorViewControllerDelegate>
{
	NSArray *accounts;
	NSManagedObjectContext *managedObjectContext;
	Account *selectedAccount;
	UIBarButtonItem *refreshButtonItem;
}

@property (nonatomic, retain) UIBarButtonItem *refreshButtonItem;
@property (nonatomic, retain) NSArray *accounts;
@property (nonatomic, retain) Account *selectedAccount;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

- (void)reloadAccounts;
- (NSString *)folderNameForExportingReportsOfAccount:(Account *)account;
- (void)showSettings;
- (void)addNewAccount;
- (void)editAccount:(Account *)account;
- (void)saveContext;

@end
