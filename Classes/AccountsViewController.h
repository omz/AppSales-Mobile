//
//  RootViewController.h
//  AppSales
//
//  Created by Ole Zorn on 30.06.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FieldEditorViewController.h"
#import "KKPasscodeSettingsViewController.h"

#define kAccountUsername					@"username"
#define kAccountPassword					@"password"
#define kAccountVendorID					@"vendorID"
#define ASViewSettingsDidChangeNotification	@"ASViewSettingsDidChangeNotification"

@class ASAccount;
@protocol AccountsViewControllerDelegate;

@interface AccountsViewController : UITableViewController <NSFetchedResultsControllerDelegate, UIAlertViewDelegate, FieldEditorViewControllerDelegate, KKPasscodeSettingsViewControllerDelegate, UIDocumentInteractionControllerDelegate>
{
	id<AccountsViewControllerDelegate> __weak delegate;
	NSArray *accounts;
	NSManagedObjectContext *managedObjectContext;
	ASAccount *selectedAccount;
	UIBarButtonItem *refreshButtonItem;
	FieldSpecifier *passcodeLockField;
	FieldEditorViewController *settingsViewController;
	UINavigationController *settingsNavController;
	NSString *exportedReportsZipPath;
	UIDocumentInteractionController *documentInteractionController;
}

@property (nonatomic, weak) id<AccountsViewControllerDelegate> delegate;
@property (nonatomic, strong) UIBarButtonItem *refreshButtonItem;
@property (nonatomic, strong) NSArray *accounts;
@property (nonatomic, strong) ASAccount *selectedAccount;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSString *exportedReportsZipPath;
@property (nonatomic, strong) UIDocumentInteractionController *documentInteractionController;

- (void)reloadAccounts;
- (void)downloadReports:(id)sender;
- (void)doExport;
- (NSString *)folderNameForExportingReportsOfAccount:(ASAccount *)account;
- (void)showSettings;
- (void)addNewAccount;
- (void)editAccount:(ASAccount *)account;
- (void)saveContext;

@end

@protocol AccountsViewControllerDelegate <NSObject>

- (void)accountsViewController:(AccountsViewController *)viewController didSelectAccount:(ASAccount *)account;

@end