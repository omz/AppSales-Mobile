//
//  RootViewController.h
//  AppSales
//
//  Created by Ole Zorn on 30.06.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FieldEditorViewController.h"

@class ASAccount;

@interface AccountsViewController : UITableViewController <NSFetchedResultsControllerDelegate, UIAlertViewDelegate, FieldEditorViewControllerDelegate>
{
	NSArray *accounts;
	NSManagedObjectContext *managedObjectContext;
	ASAccount *selectedAccount;
	UIBarButtonItem *refreshButtonItem;
}

@property (nonatomic, retain) UIBarButtonItem *refreshButtonItem;
@property (nonatomic, retain) NSArray *accounts;
@property (nonatomic, retain) ASAccount *selectedAccount;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

- (void)reloadAccounts;
- (NSString *)folderNameForExportingReportsOfAccount:(ASAccount *)account;
- (void)showSettings;
- (void)addNewAccount;
- (void)editAccount:(ASAccount *)account;
- (void)saveContext;

@end
