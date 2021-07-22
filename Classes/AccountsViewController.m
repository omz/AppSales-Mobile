//
//  AccountsViewController.m
//  AppSales
//
//  Created by Ole Zorn on 30.06.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "AccountsViewController.h"
#import "AccountsViewController+ButtonActions.h"
#import "SalesViewController.h"
#import "ReviewsViewController.h"
#import "SAMKeychain.h"
#import "ASAccount.h"
#import "Report.h"
#import "Product.h"
#import "CurrencyManager.h"
#import "ReportDownloadCoordinator.h"
#import "ASProgressHUD.h"
#import "ReportImportOperation.h"
#import "PaymentsViewController.h"
#import "BadgedCell.h"
#import "UIImage+Tinting.h"
#import "AboutViewController.h"
#import "AccountStatusView.h"
#import "PromoCodesViewController.h"
#import "PromoCodesLicenseViewController.h"
#import "KKPasscodeLock.h"
#import "IconManager.h"
#import "ZIPArchive.h"
#import "UIViewController+Alert.h"

#define kAddNewAccountEditorIdentifier		@"AddNewAccountEditorIdentifier"
#define kEditAccountEditorIdentifier		@"EditAccountEditorIdentifier"
#define kSettingsEditorIdentifier			@"SettingsEditorIdentifier"
#define kUpdateExchangeRatesButton			@"UpdateExchangeRatesButton"
#define kPasscodeLockButton					@"PasscodeLockButton"
#define kImportReportsButton				@"ImportReportsButton"
#define kExportReportsButton				@"ExportReportsButton"
#define	kDeleteAccountButton				@"DeleteAccount"
#define kAccountTitle						@"title"
#define kKeychainServiceIdentifier			@"iTunesConnect"


@implementation AccountsViewController

@synthesize managedObjectContext, accounts, selectedAccount, refreshButtonItem, delegate, documentInteractionController;

- (void)viewDidLoad {
	[super viewDidLoad];
	
	UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", nil) style:UIBarButtonItemStylePlain target:self action:nil];
	self.navigationItem.backBarButtonItem = backButton;
	
	self.refreshButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(downloadReports:)];
	
	UIBarButtonItem *settingsButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Gear"] style:UIBarButtonItemStylePlain target:self action:@selector(showSettings)];
	
	UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	
	UILabel *statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 200.0f, 44.0f)];
	statusLabel.font = [UIFont systemFontOfSize:14.0f];
	statusLabel.backgroundColor = [UIColor clearColor];
	statusLabel.textColor = [UIColor grayColor];
	statusLabel.textAlignment = NSTextAlignmentCenter;
	UIBarButtonItem *statusItem = [[UIBarButtonItem alloc] initWithCustomView:statusLabel];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
		NSString *currentBuild = AboutViewController.currentBuild;
		NSString *latestBuild = AboutViewController.latestBuild;
		if ((latestBuild != nil) && (currentBuild.integerValue < latestBuild.integerValue)) {
			dispatch_async(dispatch_get_main_queue(), ^{
				statusLabel.text = NSLocalizedString(@"UPDATE AVAILABLE", nil);
			});
		}
		dispatch_async(dispatch_get_main_queue(), ^{
			[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
		});
	});
	
	UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
	[infoButton addTarget:self action:@selector(showInfo:) forControlEvents:UIControlEventTouchUpInside];
	UIBarButtonItem *infoButtonItem = [[UIBarButtonItem alloc] initWithCustomView:infoButton];
	
	self.toolbarItems = @[infoButtonItem, flexSpace, statusItem, flexSpace, settingsButtonItem];
	self.navigationItem.rightBarButtonItem = refreshButtonItem;
	
	self.title = NSLocalizedString(@"AppSales", nil);
	UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNewAccount)];
	self.navigationItem.leftBarButtonItem = addButton;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextDidChange:) name:NSManagedObjectContextObjectsDidChangeNotification object:[self managedObjectContext]];
	
	[[ReportDownloadCoordinator sharedReportDownloadCoordinator] addObserver:self forKeyPath:@"isBusy" options:NSKeyValueObservingOptionNew context:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(iconCleared:) name:IconManagerClearedIconNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(iconReloadFailed:) name:IconManagerReloadFailedIconNotification object:nil];
	
	[self reloadAccounts];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"isBusy"]) {
		dispatch_async(dispatch_get_main_queue(), ^{
			self.refreshButtonItem.enabled = ![[ReportDownloadCoordinator sharedReportDownloadCoordinator] isBusy];
		});
	}
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	if (![[ReportDownloadCoordinator sharedReportDownloadCoordinator] isBusy] && [self.accounts count] == 0) {
		[self addNewAccount];
	}
}

- (void)contextDidChange:(NSNotification *)notification {
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[self.tableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.1];
}

- (void)reloadAccounts {
	NSFetchRequest *accountsFetchRequest = [[NSFetchRequest alloc] init];
	[accountsFetchRequest setEntity:[NSEntityDescription entityForName:@"Account" inManagedObjectContext:self.managedObjectContext]];
	[accountsFetchRequest setSortDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES], [[NSSortDescriptor alloc] initWithKey:@"username" ascending:YES]]];
	self.accounts = [self.managedObjectContext executeFetchRequest:accountsFetchRequest error:nil];
	
	[self.tableView reloadData];
}

- (void)downloadReports:(id)sender {
    for (ASAccount *account in self.accounts) {
        if ((account.providerID == nil) || (account.providerID.length == 0)) {
            [[UIViewController topViewController] displayAlertWithTitle:NSLocalizedString(@"Provider ID Missing", nil)
                                                                message:[NSString stringWithFormat:NSLocalizedString(@"Provider ID not set for the account \"%@\". Please go to the account's settings and fill in the missing information.", nil), account.displayName]];
        } else if ((account.accessToken == nil) || (account.accessToken.length == 0)) {
            [[UIViewController topViewController] displayAlertWithTitle:NSLocalizedString(@"Access Token Missing", nil)
                                                                message:[NSString stringWithFormat:NSLocalizedString(@"Access token not set for the account \"%@\". Please go to the account's settings and fill in the missing information.", nil), account.displayName]];
        } else if ((account.vendorID == nil) || (account.vendorID.length == 0)) {
            [[UIViewController topViewController] displayAlertWithTitle:NSLocalizedString(@"Vendor ID Missing", nil)
                                                                message:[NSString stringWithFormat:NSLocalizedString(@"You have not entered a vendor ID for the account \"%@\". Please go to the account's settings and fill in the missing information.", nil), account.displayName]];
        } else {
            [[ReportDownloadCoordinator sharedReportDownloadCoordinator] downloadReportsForAccount:account];
        }
	}
}

- (void)showInfo:(id)sender {
	AboutViewController *aboutViewController = [[AboutViewController alloc] init];
	UINavigationController *aboutNavController = [[UINavigationController alloc] initWithRootViewController:aboutViewController];
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
		aboutNavController.modalPresentationStyle = UIModalPresentationFormSheet;
	}
	[self presentViewController:aboutNavController animated:YES completion:nil];
}


#pragma mark - Table view

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) return nil;
	
	if ([self.accounts count] == 0) {
		return nil;
	}
	ASAccount *account = self.accounts[section];
	NSString *title = account.title;
	if (!title || [title isEqualToString:@""]) {
		title = account.username;
	}
	return title;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) return 1;
	
	if ([self.accounts count] == 0) {
		return 1;
	}
	return [self.accounts count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) return self.accounts.count;
	
	if ([self.accounts count] == 0) {
		return 0;
	}
	return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *cellIdentifier = @"Cell";
	BadgedCell *cell = (BadgedCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil) {
		cell = [[BadgedCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
	}
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
		cell.textLabel.text = [self.accounts[indexPath.row] displayName];
		cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
		return cell;
	}
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	if (indexPath.row == 0) {
		NSInteger badge = [[self.accounts[indexPath.section] reportsBadge] integerValue];
		cell.textLabel.text = NSLocalizedString(@"Sales and Trends", nil);
		cell.badgeCount = badge;
		cell.imageName = @"Sales";
        
	} else if (indexPath.row == 1) {
		NSInteger badge = [[self.accounts[indexPath.section] paymentsBadge] integerValue];
		cell.textLabel.text = NSLocalizedString(@"Payments", nil);
		cell.badgeCount = badge;
		cell.imageName = @"Payments";
	} else if (indexPath.row == 2) {
		cell.textLabel.text = NSLocalizedString(@"Customer Reviews", nil);
		cell.imageName = @"Reviews";
		
		ASAccount *account = self.accounts[indexPath.section];
		NSFetchRequest *unreadReviewsRequest = [[NSFetchRequest alloc] init];
		[unreadReviewsRequest setEntity:[NSEntityDescription entityForName:@"Review" inManagedObjectContext:[self managedObjectContext]]];
		[unreadReviewsRequest setPredicate:[NSPredicate predicateWithFormat:@"product.account == %@ AND unread == TRUE", account]];
		cell.badgeCount = [[self managedObjectContext] countForFetchRequest:unreadReviewsRequest error:nil];
	} else if (indexPath.row == 3) {
		cell.textLabel.text = NSLocalizedString(@"Promo Codes", nil);
		cell.imageName = @"PromoCodes";
		cell.badgeCount = 0;
	} else if (indexPath.row == 4) {
		cell.textLabel.text = NSLocalizedString(@"Account", nil);
		cell.imageName = @"Account";
		cell.badgeCount = 0;
	}
	return cell;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	// iPad only
	ASAccount *account = self.accounts[indexPath.row];
	[self editAccount:account];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) return nil;
	
	if ([self.accounts count] == 0) {
		return nil;
	}
	ASAccount *account = self.accounts[section];
	return [[AccountStatusView alloc] initWithFrame:CGRectMake(0, 0, 320, 26) account:account];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	return 26.0;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 44.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
		if (self.delegate) {
			ASAccount *account = self.accounts[indexPath.row];
			[self.delegate accountsViewController:self didSelectAccount:account];
		}
		return;
	}
	ASAccount *account = self.accounts[indexPath.section];
	if (indexPath.row == 0) {
		SalesViewController *salesViewController = [[SalesViewController alloc] initWithAccount:account];
		[self.navigationController pushViewController:salesViewController animated:YES];
	} else if (indexPath.row == 1) {
		PaymentsViewController *paymentsViewController = [[PaymentsViewController alloc] initWithAccount:account];
		[self.navigationController pushViewController:paymentsViewController animated:YES];
	} else if (indexPath.row == 2) {
		ReviewsViewController *reviewsViewController = [[ReviewsViewController alloc] initWithAccount:account];
		[self.navigationController pushViewController:reviewsViewController animated:YES];
	} else if (indexPath.row == 3) {
		PromoCodesViewController *promoCodesViewController = [[PromoCodesViewController alloc] initWithAccount:account];
		[self.navigationController pushViewController:promoCodesViewController animated:YES];
	} else if (indexPath.row == 4) {
		[self editAccount:account];
	}
}

#pragma mark -

- (void)deleteAccount:(NSManagedObject *)account {
	if (account) {
		NSManagedObjectContext *context = self.managedObjectContext;
		[context deleteObject:account];
		[ASProgressHUD hideHUDForView:self.navigationController.view animated:YES];
		[self reloadAccounts];
		[self.navigationController popViewControllerAnimated:YES];
	}
}

- (NSArray *)accountSectionsFor:(ASAccount *)account {
	FieldSpecifier *usernameField = [FieldSpecifier emailFieldWithKey:kAccountUsername title:NSLocalizedString(@"Email", nil) defaultValue:account.username ?: @""];
	FieldSpecifier *passwordField = [FieldSpecifier passwordFieldWithKey:kAccountPassword title:NSLocalizedString(@"Password", nil) defaultValue:account.password ?: @""];
	FieldSpecifier *autoFillWizardButtonField = [FieldSpecifier buttonFieldWithKey:@"AutoFillWizardButton" title:NSLocalizedString(@"Auto-Fill Wizard…", nil)];
	FieldSectionSpecifier *loginSection = [FieldSectionSpecifier sectionWithFields:@[usernameField, passwordField, autoFillWizardButtonField]
																			 title:NSLocalizedString(@"iTunes Connect Login", nil)
																	   description:nil];
	
	FieldSpecifier *providerIDField = [FieldSpecifier numericFieldWithKey:kAccountProviderID title:NSLocalizedString(@"Provider ID", nil) defaultValue:account.providerID ?: @""];
	providerIDField.placeholder = @"XXXXXXXXX";
	FieldSpecifier *selectProviderIDButtonField = [FieldSpecifier buttonFieldWithKey:@"SelectProviderIDButton" title:NSLocalizedString(@"Auto-Fill Provider ID…", nil)];
	FieldSectionSpecifier *providerIDSection = [FieldSectionSpecifier sectionWithFields:@[providerIDField, selectProviderIDButtonField]
																				  title:NSLocalizedString(@"Provider ID", nil)
																			description:NSLocalizedString(@"The provider ID identifies the company you would like to fetch reports for, particularly for accounts linked to more than one company.\n\nNote: If you change the provider ID, you must also refetch or regenerate an access token below.", nil)];
	
	FieldSpecifier *accessTokenField = [FieldSpecifier textFieldWithKey:kAccountAccessToken title:NSLocalizedString(@"Token", nil) defaultValue:account.accessToken ?: @""];
	accessTokenField.placeholder = @"XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX";
	FieldSpecifier *getAccessTokenButtonField = [FieldSpecifier buttonFieldWithKey:@"GetAccessTokenButton" title:NSLocalizedString(@"Auto-Fill Access Token…", nil)];
	FieldSectionSpecifier *accessTokenSection = [FieldSectionSpecifier sectionWithFields:@[accessTokenField, getAccessTokenButtonField]
																				   title:NSLocalizedString(@"Access Token", nil)
																			 description:NSLocalizedString(@"An access token is a unique code that lets you download sales and financial reports with Reporter.\n\nNote: You can generate only one access token at a time per Apple ID. Your access token will automatically expire after 180 days. If you generate a new access token, your previous access token immediately expires.", nil)];
	
	FieldSpecifier *vendorIDField = [FieldSpecifier numericFieldWithKey:kAccountVendorID title:NSLocalizedString(@"Vendor ID", nil) defaultValue:account.vendorID ?: @""];
	vendorIDField.placeholder = @"8XXXXXXX";
	FieldSpecifier *selectVendorIDButtonField = [FieldSpecifier buttonFieldWithKey:@"SelectVendorIDButton" title:NSLocalizedString(@"Auto-Fill Vendor ID…", nil)];
	FieldSectionSpecifier *vendorIDSection = [FieldSectionSpecifier sectionWithFields:@[vendorIDField, selectVendorIDButtonField]
																				title:NSLocalizedString(@"Vendor ID", nil)
																		  description:NSLocalizedString(@"You can find your Vendor ID at the top of the “Payments and Financial Reports” module in iTunes Connect.", nil)];
	
	return @[loginSection, providerIDSection, accessTokenSection, vendorIDSection];
}

- (void)addNewAccount {
	FieldSpecifier *titleField = [FieldSpecifier textFieldWithKey:kAccountTitle title:@"Description" defaultValue:@""];
	titleField.placeholder = NSLocalizedString(@"optional", nil);
	FieldSectionSpecifier *titleSection = [FieldSectionSpecifier sectionWithFields:@[titleField] title:nil description:nil];
	
	NSMutableArray *sections = [[NSMutableArray alloc] initWithArray:[self accountSectionsFor:nil]];
	[sections insertObject:titleSection atIndex:0];
	
	FieldEditorViewController *addAccountViewController = [[FieldEditorViewController alloc] initWithFieldSections:sections title:NSLocalizedString(@"New Account",nil)];
	addAccountViewController.cancelButtonTitle = NSLocalizedString(@"Cancel", nil);
	addAccountViewController.doneButtonTitle = NSLocalizedString(@"Done", nil);
	addAccountViewController.delegate = self;
	addAccountViewController.editorIdentifier = kAddNewAccountEditorIdentifier;
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:addAccountViewController];
	
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
		navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
		
	}
	[self presentViewController:navigationController animated:YES completion:nil];
}

- (void)editAccount:(ASAccount *)account {
	self.selectedAccount = account;
	
	FieldSpecifier *titleField = [FieldSpecifier textFieldWithKey:kAccountTitle title:@"Description" defaultValue:account.title ?: @""];
	titleField.placeholder = NSLocalizedString(@"optional", nil);
	
	FieldSpecifier *loginSubsectionField = [FieldSpecifier subsectionFieldWithSections:[self accountSectionsFor:account] key:@"iTunesConnect" title:NSLocalizedString(@"iTunes Connect Login", nil)];
	FieldSectionSpecifier *titleSection = [FieldSectionSpecifier sectionWithFields:@[titleField, loginSubsectionField] title:nil description:nil];
	
	FieldSpecifier *importButtonField = [FieldSpecifier buttonFieldWithKey:kImportReportsButton title:NSLocalizedString(@"Import Reports...", nil)];
	FieldSpecifier *exportButtonField = [FieldSpecifier buttonFieldWithKey:kExportReportsButton title:NSLocalizedString(@"Export Reports...", nil)];
	FieldSectionSpecifier *importExportSection = [FieldSectionSpecifier sectionWithFields:@[importButtonField, exportButtonField] title:nil description:nil];
	
	NSMutableArray *productFields = [[NSMutableArray alloc] init];
	
	NSArray *allProducts;
	NSString *productSortByValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"ProductSortby"];
	if ([productSortByValue isEqualToString:@"productName"]) {
		// Sort products by name.
		allProducts = [[account.products allObjects] sortedArrayUsingComparator:^NSComparisonResult(Product *product1, Product *product2) {
			return [product1.name caseInsensitiveCompare:product2.name];
		}];
	} else {
		allProducts = [[account.products allObjects] sortedArrayUsingComparator:^NSComparisonResult(Product *product1, Product *product2) {
			NSInteger productID1 = product1.productID.integerValue;
			NSInteger productID2 = product2.productID.integerValue;
			if (productID1 < productID2) {
				return NSOrderedDescending;
			} else if (productID1 > productID2) {
				return NSOrderedAscending;
			}
			return NSOrderedSame;
		}];
	}
	
	for (Product *product in allProducts) {
		NSMutableArray *sections = [[NSMutableArray alloc] init];
		NSMutableArray *fields = [[NSMutableArray alloc] init];
		
		FieldSpecifier *productNameField = [FieldSpecifier textFieldWithKey:[NSString stringWithFormat:@"product.name.%@", product.productID] title:NSLocalizedString(@"Name", nil) defaultValue:product.displayName];
		[fields addObject:productNameField];
		
		FieldSpecifier *hideProductField = [FieldSpecifier switchFieldWithKey:[NSString stringWithFormat:@"product.hidden.%@", product.productID] title:NSLocalizedString(@"Hide in Dashboard", nil) defaultValue:product.hidden.boolValue];
		[fields addObject:hideProductField];
		
		NSString *productFooter = nil;
		if (product.parentSKU.length <= 1) {
			FieldSpecifier *reloadProductInfoField = [FieldSpecifier buttonFieldWithKey:[NSString stringWithFormat:@"product.reload.%@", product.productID] title:NSLocalizedString(@"Reload App Icon...", nil)];
			[fields addObject:reloadProductInfoField];
		} else {
			productFooter = [NSString stringWithFormat:@"Apple ID: %@", product.productID];
		}
		
		FieldSectionSpecifier *productSection = [FieldSectionSpecifier sectionWithFields:fields title:nil description:productFooter];
		[sections addObject:productSection];
		
		if (product.parentSKU.length <= 1) {
			productFooter = [NSString stringWithFormat:@"Apple ID: %@", product.productID];
			
			FieldSpecifier *showInAppStoreField = [FieldSpecifier buttonFieldWithKey:[NSString stringWithFormat:@"product.appstore.%@", product.productID] title:NSLocalizedString(@"Show in App Store...", nil)];
			
			FieldSectionSpecifier *showInAppStoreSection = [FieldSectionSpecifier sectionWithFields:@[showInAppStoreField] title:nil description:productFooter];
			[sections addObject:showInAppStoreSection];
		}
		
		FieldSpecifier *productSectionField = [FieldSpecifier subsectionFieldWithSections:sections key:[NSString stringWithFormat:@"product.section.%@", product.productID] title:[product defaultDisplayName]];
		[productFields addObject:productSectionField];
	}
	
	FieldSectionSpecifier *productsSection = [FieldSectionSpecifier sectionWithFields:productFields title:NSLocalizedString(@"Manage Apps", nil) description:nil];
	FieldSpecifier *manageProductsSectionField = [FieldSpecifier subsectionFieldWithSection:productsSection key:@"ManageProducts"];
	FieldSectionSpecifier *manageProductsSection = [FieldSectionSpecifier sectionWithFields:@[manageProductsSectionField] title:nil description:nil];
	
	if (allProducts.count == 0) {
		productsSection.description = NSLocalizedString(@"This account does not contain any apps yet. Import or download reports first.", nil);
	}
	
	FieldSpecifier *deleteAccountButtonField = [FieldSpecifier buttonFieldWithKey:kDeleteAccountButton title:NSLocalizedString(@"Delete Account...", nil)];
	FieldSectionSpecifier *deleteAccountSection = [FieldSectionSpecifier sectionWithFields:@[deleteAccountButtonField] title:nil description:nil];
	
	FieldEditorViewController *editAccountViewController = [[FieldEditorViewController alloc] initWithFieldSections:@[titleSection, importExportSection, manageProductsSection, deleteAccountSection] title:NSLocalizedString(@"Account Details",nil)];
	editAccountViewController.doneButtonTitle = nil;
	editAccountViewController.delegate = self;
	editAccountViewController.editorIdentifier = kEditAccountEditorIdentifier;
	editAccountViewController.context = account;
	
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
		editAccountViewController.hidesBottomBarWhenPushed = YES;
	}
	
	editAccountViewController.preferredContentSize = CGSizeMake(320, 480);
	
	[self.navigationController pushViewController:editAccountViewController animated:YES];
}

- (void)showSettings {
	// main section
	passcodeLockField = [FieldSpecifier buttonFieldWithKey:kPasscodeLockButton title:NSLocalizedString(@"Passcode Lock", nil)];
	passcodeLockField.shouldDisplayDisclosureIndicator = YES;
	if ([[KKPasscodeLock sharedLock] isPasscodeRequired]) {
		passcodeLockField.defaultValue = @"On";
	} else {
		passcodeLockField.defaultValue = @"Off";
	}
	
	NSString *baseCurrency = [[CurrencyManager sharedManager] baseCurrency];
	NSArray *availableCurrencies = [[CurrencyManager sharedManager] availableCurrencies];
	NSMutableArray *currencyFields = [NSMutableArray array];
	for (NSString *currency in availableCurrencies) {
		FieldSpecifier *currencyField = [FieldSpecifier checkFieldWithKey:[NSString stringWithFormat:@"currency.%@", currency] title:currency defaultValue:[baseCurrency isEqualToString:currency]];
		[currencyFields addObject:currencyField];
	}
	FieldSectionSpecifier *currencySection = [FieldSectionSpecifier sectionWithFields:currencyFields
																				title:NSLocalizedString(@"Currency", nil)
																		  description:nil];
	currencySection.exclusiveSelection = YES;
	FieldSpecifier *currencySectionField = [FieldSpecifier subsectionFieldWithSection:currencySection key:@"currency"];
	FieldSpecifier *updateExchangeRatesButtonField = [FieldSpecifier buttonFieldWithKey:kUpdateExchangeRatesButton title:NSLocalizedString(@"Update Exchange Rates Now", nil)];
	FieldSectionSpecifier *generalSection = [FieldSectionSpecifier sectionWithFields:@[passcodeLockField, currencySectionField, updateExchangeRatesButtonField]
																			   title:NSLocalizedString(@"General", nil)
																	  description:NSLocalizedString(@"Exchange rates will automatically be refreshed periodically.", nil)];
	
	
	FieldSpecifier *downloadPaymentsField = [FieldSpecifier switchFieldWithKey:kSettingDownloadPayments title:NSLocalizedString(@"Download Payments", nil) defaultValue:[[NSUserDefaults standardUserDefaults] boolForKey:kSettingDownloadPayments]];
	FieldSpecifier *deleteCookiesField = [FieldSpecifier switchFieldWithKey:kSettingDeleteCookies title:NSLocalizedString(@"Delete Cookies", nil) defaultValue:[[NSUserDefaults standardUserDefaults] boolForKey:kSettingDeleteCookies]];
	FieldSectionSpecifier *paymentsSection = [FieldSectionSpecifier sectionWithFields:@[downloadPaymentsField, deleteCookiesField]
																				title:NSLocalizedString(@"Payments", nil)
																		  description:NSLocalizedString(@"Delete Cookies forces accounts with Two-Step Verification to re-verify their identity each time that payments are downloaded.", nil)];
	
	// products section
	NSString *productSortByValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"ProductSortby"];
	FieldSpecifier *productSortingByProductIdField = [FieldSpecifier checkFieldWithKey:@"sortby.productId" title:@"Product ID"
																		  defaultValue:[productSortByValue isEqualToString:@"productId"]];
	FieldSpecifier *productSortingByNameField = [FieldSpecifier checkFieldWithKey:@"sortby.productName" title:@"Name"
																	 defaultValue:[productSortByValue isEqualToString:@"productName"]];
	FieldSpecifier *productSortingByColorField = [FieldSpecifier checkFieldWithKey:@"sortby.color" title:@"Color"
																	  defaultValue:[productSortByValue isEqualToString:@"color"]];
	NSMutableArray *productSortingFields = [[NSMutableArray alloc] initWithArray:@[productSortingByProductIdField, productSortingByNameField, productSortingByColorField]];
	
	
	FieldSectionSpecifier *productSortingSection = [FieldSectionSpecifier sectionWithFields:productSortingFields
																					  title:NSLocalizedString(@"Sort By", nil)
																				description:nil];
	productSortingSection.exclusiveSelection = YES;
	FieldSpecifier *productsSectionField = [FieldSpecifier subsectionFieldWithSection:productSortingSection key:@"sortby"];
	FieldSectionSpecifier *productsSection = [FieldSectionSpecifier sectionWithFields:@[productsSectionField]
																				title:NSLocalizedString(@"Products", nil)
																		  description:NSLocalizedString(@"", nil)];
	
	NSArray *sections = @[generalSection, paymentsSection, productsSection];
	settingsViewController = [[FieldEditorViewController alloc] initWithFieldSections:sections title:NSLocalizedString(@"Settings",nil)];
	settingsViewController.doneButtonTitle = NSLocalizedString(@"Done", nil);
	settingsViewController.showDoneButtonOnLeft = YES;
	settingsViewController.delegate = self;
	settingsViewController.editorIdentifier = kSettingsEditorIdentifier;
	
	settingsNavController = [[UINavigationController alloc] initWithRootViewController:settingsViewController];
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
		settingsNavController.modalPresentationStyle = UIModalPresentationFormSheet;
	}
	[self presentViewController:settingsNavController animated:YES completion:nil];
}

- (void)fieldEditor:(FieldEditorViewController *)editor didFinishEditingWithValues:(NSDictionary *)returnValues {
	if ([editor.editorIdentifier isEqualToString:kAddNewAccountEditorIdentifier] || [editor.editorIdentifier isEqualToString:kEditAccountEditorIdentifier]) {
		NSString *username = returnValues[kAccountUsername];
		NSString *password = returnValues[kAccountPassword];
		NSString *providerID = returnValues[kAccountProviderID];
        NSString *accessToken = returnValues[kAccountAccessToken];
        NSString *vendorID = returnValues[kAccountVendorID];
        NSString *title = returnValues[kAccountTitle];
        if ((username.length == 0) && (title.length == 0)) {
            [[UIViewController topViewController] displayAlertWithTitle:NSLocalizedString(@"Missing Information", nil)
                                                                message:NSLocalizedString(@"You need to enter at least a username or a description.\n\nAll fields are required if you want to download reports and payments from iTunes Connect, otherwise you can just enter a description.", nil)];
            return;
        }
        if ((password.length > 0) && (providerID.length == 0)) {
            [[UIViewController topViewController] displayAlertWithTitle:NSLocalizedString(@"Missing Information", nil)
                                                                message:NSLocalizedString(@"You need to enter a provider ID in order to download reports from iTunes Connect.", nil)];
            return;
        }
        if ((password.length > 0) && (accessToken.length == 0)) {
            [[UIViewController topViewController] displayAlertWithTitle:NSLocalizedString(@"Missing Information", nil)
                                                                message:NSLocalizedString(@"You need to enter an access token in order to download reports from iTunes Connect.", nil)];
            return;
        }
        if ((password.length > 0) && (vendorID.length == 0)) {
            [[UIViewController topViewController] displayAlertWithTitle:NSLocalizedString(@"Missing Information", nil)
                                                                message:NSLocalizedString(@"You need to enter a vendor ID. If you don't know your vendor ID, tap \"Auto-Fill Vendor ID\".", nil)];
            return;
        }
        if (password.length == 0) {
            [[UIViewController topViewController] displayAlertWithTitle:NSLocalizedString(@"Notice", nil)
                                                                message:NSLocalizedString(@"Payments will not be downloaded from iTunes Connect without your account password.", nil)];
        }
        if ([editor.editorIdentifier isEqualToString:kAddNewAccountEditorIdentifier]) {
			ASAccount *account = (ASAccount *)[NSEntityDescription insertNewObjectForEntityForName:@"Account" inManagedObjectContext:self.managedObjectContext];
			account.title = title;
			account.username = username;
			account.providerID = providerID;
			account.vendorID = vendorID;
			account.sortIndex = @(time(NULL));
			account.password = password;
			account.accessToken = accessToken;
		}
		else if ([editor.editorIdentifier isEqualToString:kEditAccountEditorIdentifier]) {
			ASAccount *account = (ASAccount *)editor.context;
			[account deletePassword];
			account.username = username;
			account.title = title;
			account.providerID = providerID;
			account.vendorID = vendorID;
			account.password = password;
			account.accessToken = accessToken;
			
			NSMutableDictionary *productsByID = [NSMutableDictionary dictionary];
			for (Product *product in self.selectedAccount.products) {
				[productsByID setObject:product forKey:product.productID];
			}
			for (NSString *key in [returnValues allKeys]) {
				if ([key hasPrefix:@"product.name."]) {
					NSString *productID = [key substringFromIndex:[@"product.name." length]];
					Product *product = productsByID[productID];
					NSString *newName = returnValues[key];
					if (![[product displayName] isEqualToString:newName]) {
						product.customName = newName;
					}
				} else if ([key hasPrefix:@"product.hidden."]) {
					NSString *productID = [key substringFromIndex:[@"product.hidden." length]];
					Product *product = productsByID[productID];
					product.hidden = returnValues[key];
				}
			}
		}
		[self saveContext];
		if ([editor.editorIdentifier isEqualToString:kAddNewAccountEditorIdentifier]) {
			[editor dismissViewControllerAnimated:YES completion:nil];
		}
		self.selectedAccount = nil;
	} else if ([editor.editorIdentifier isEqualToString:kSettingsEditorIdentifier]) {
		for (NSString *key in [returnValues allKeys]) {
			if ([key hasPrefix:@"currency."]) {
				if ([returnValues[key] boolValue]) {
					[[CurrencyManager sharedManager] setBaseCurrency:[[key componentsSeparatedByString:@"."] lastObject]];
				}
			}
			if ([key hasPrefix:@"sortby."]) {
				if ([returnValues[key] boolValue]) {
					[[NSUserDefaults standardUserDefaults] setObject:[[key componentsSeparatedByString:@"."] lastObject] forKey:@"ProductSortby"];
				}
			}
		}
		[[NSUserDefaults standardUserDefaults] setBool:[returnValues[kSettingDownloadPayments] boolValue] forKey:kSettingDownloadPayments];
		[[NSUserDefaults standardUserDefaults] setBool:[returnValues[kSettingDeleteCookies] boolValue] forKey:kSettingDeleteCookies];
		[self dismissViewControllerAnimated:YES completion:nil];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ASViewSettingsDidChangeNotification object:nil];
	}
	[self reloadAccounts];
}

- (void)fieldEditor:(FieldEditorViewController *)editor pressedButtonWithKey:(NSString *)key {
	if ([key isEqualToString:kPasscodeLockButton]) {
		KKPasscodeSettingsViewController *vc = [[KKPasscodeSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
		vc.delegate = self;
		[settingsNavController pushViewController:vc animated:YES];
	} else if ([key isEqualToString:kUpdateExchangeRatesButton]) {
		[[CurrencyManager sharedManager] forceRefresh];
    } else if ([key isEqualToString:kImportReportsButton]) {
        ASAccount *account = (ASAccount *)editor.context;
        if (account.isDownloadingReports) {
            [[UIViewController topViewController] displayAlertWithTitle:nil
                                                                message:NSLocalizedString(@"AppSales is already importing reports for this account. Please wait until the current import has finished.", nil)];
        } else {
            BOOL canStartImport = [ReportImportOperation filesAvailableToImport];
            if (!canStartImport) {
                [[UIViewController topViewController] displayAlertWithTitle:NSLocalizedString(@"No Files Found", nil)
                                                                    message:NSLocalizedString(@"The Documents directory does not contain any .txt files. Please use iTunes File Sharing to transfer report files to your device.", nil)];
            } else {
                UIAlertController *confirmImportAlert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Begin Import?", nil)
                                                                                            message:NSLocalizedString(@"Do you want to start importing all report files in the Documents directory into this account?", nil)
                                                                                     preferredStyle:UIAlertControllerStyleAlert];
                
                [confirmImportAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                                       style:UIAlertActionStyleCancel
                                                                     handler:nil]];
                
                [confirmImportAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Start Import", nil)
                                                                       style:UIAlertActionStyleDefault
                                                                     handler:^(UIAlertAction * _Nonnull action) {
                    
                    [[ReportDownloadCoordinator sharedReportDownloadCoordinator] importReportsIntoAccount:self.selectedAccount];
                    [self.navigationController popViewControllerAnimated:YES];
                }]];
                
                [self presentViewController:confirmImportAlert animated:YES completion:nil];
			}
		}
	} else if ([key isEqualToString:kExportReportsButton]) {
		[self doExport];
	} else if ([key hasPrefix:@"product.appstore."]) {
		NSString *productID = [key substringFromIndex:[@"product.appstore." length]];
		NSString *appStoreURLString = [NSString stringWithFormat:@"https://apps.apple.com/app/id%@", productID];
		// Create product dict to check what kind of app were looking at.
		NSMutableDictionary *productsByID = [NSMutableDictionary dictionary];
		for (Product *product in self.selectedAccount.products) {
			[productsByID setObject:product forKey:product.productID];
		}
		// Check if app is a bundle.
		Product *product = productsByID[productID];
		if ([product.platform.lowercaseString containsString:@"bundle"]) {
			appStoreURLString = [NSString stringWithFormat:@"https://apps.apple.com/app-bundle/id%@", productID];
		}
		UIApplication *application = [UIApplication sharedApplication];
		[application openURL:[NSURL URLWithString:appStoreURLString]];
	} else if ([key hasPrefix:@"product.reload."]) {
		NSString *productID = [key substringFromIndex:[@"product.reload." length]];
		IconManager *iconManager = [IconManager sharedManager];
		[iconManager clearIconForAppID:productID];
	} else if ([key isEqualToString:kDeleteAccountButton]) {
        UIAlertController *confirmImportAlert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Delete Account?", nil)
                                                                                    message:NSLocalizedString(@"Do you really want to delete this account and all of its data?", nil)
                                                                             preferredStyle:UIAlertControllerStyleAlert];
        
        [confirmImportAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                               style:UIAlertActionStyleCancel
                                                             handler:nil]];
        
        [confirmImportAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Delete", nil)
                                                               style:UIAlertActionStyleDestructive
                                                             handler:^(UIAlertAction * _Nonnull action) {
            
            ASProgressHUD *hud = [ASProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
            hud.label.text = NSLocalizedString(@"Deleting Account...", nil);
            
            ASAccount *account = self.selectedAccount;
            [self performSelector:@selector(deleteAccount:) withObject:account afterDelay:0.1];
        }]];
        
        [self presentViewController:confirmImportAlert animated:YES completion:nil];
	} else if ([key isEqualToString:@"AutoFillWizardButton"]) {
		FieldEditorViewController *vc = nil;
		if (self.presentedViewController) {
			UINavigationController *nav = (UINavigationController *)self.presentedViewController;
			vc = (FieldEditorViewController *)nav.viewControllers[0];
		} else {
			vc = (FieldEditorViewController *)[self.navigationController.viewControllers lastObject];
		}
		NSString *username = vc.values[kAccountUsername];
		NSString *password = vc.values[kAccountPassword];
		
		if ((username.length == 0) || (password.length == 0)) {
            
            [[UIViewController topViewController] displayAlertWithTitle:nil
                                                                message:NSLocalizedString(@"Please enter your username and password first.", nil)];
            return;
		}
		[vc dismissKeyboard];
		
		NSDictionary *loginInfo = @{
			kAccountUsername: username,
			kAccountPassword: password
		};
		
		ASProgressHUD *hud = [ASProgressHUD showHUDAddedTo:vc.navigationController.view animated:YES];
		hud.label.text = NSLocalizedString(@"Auto-Fill Wizard…", nil);
		[self autoFillWizardWithLogin:loginInfo];
	} else if ([key isEqualToString:@"SelectProviderIDButton"]) {
		FieldEditorViewController *vc = nil;
		if (self.presentedViewController) {
			UINavigationController *nav = (UINavigationController *)self.presentedViewController;
			vc = (FieldEditorViewController *)nav.viewControllers[0];
		} else {
			vc = (FieldEditorViewController *)[self.navigationController.viewControllers lastObject];
		}
		NSString *username = vc.values[kAccountUsername];
		NSString *password = vc.values[kAccountPassword];

        if ((username.length == 0) || (password.length == 0)) {
            [[UIViewController topViewController] displayAlertWithTitle:nil
                                                                message:NSLocalizedString(@"Please enter your username and password first.", nil)];
			return;
		}
		[vc dismissKeyboard];

		NSDictionary *loginInfo = @{
			kAccountUsername: username,
			kAccountPassword: password
		};

		ASProgressHUD *hud = [ASProgressHUD showHUDAddedTo:vc.navigationController.view animated:YES];
		hud.label.text = NSLocalizedString(@"Fetching Provider ID…", nil);
		[self findProviderIDWithLogin:loginInfo];
	} else if ([key isEqualToString:@"GetAccessTokenButton"]) {
		FieldEditorViewController *vc = nil;
		if (self.presentedViewController) {
			UINavigationController *nav = (UINavigationController *)self.presentedViewController;
			vc = (FieldEditorViewController *)nav.viewControllers[0];
		} else {
			vc = (FieldEditorViewController *)[self.navigationController.viewControllers lastObject];
		}
		NSString *username = vc.values[kAccountUsername];
		NSString *password = vc.values[kAccountPassword];
		NSString *providerID = vc.values[kAccountProviderID];
        
        if ((username.length == 0) || (password.length == 0)) {
            [[UIViewController topViewController] displayAlertWithTitle:nil
                                                                message:NSLocalizedString(@"Please enter your username and password first.", nil)];
            return;
        } else if (providerID.length == 0) {
            [[UIViewController topViewController] displayAlertWithTitle:nil
                                                                message:NSLocalizedString(@"Please fill in your provider ID first.", nil)];
            return;
		}
		[vc dismissKeyboard];
		
		NSDictionary *loginInfo = @{
			kAccountUsername: username,
			kAccountPassword: password,
			kAccountProviderID: providerID
		};
		
		ASProgressHUD *hud = [ASProgressHUD showHUDAddedTo:vc.navigationController.view animated:YES];
		hud.label.text = NSLocalizedString(@"Fetching Access Token…", nil);
		[self getAccessTokenWithLogin:loginInfo];
	} else if ([key isEqualToString:@"SelectVendorIDButton"]) {
		FieldEditorViewController *vc = nil;
		if (self.presentedViewController) {
			UINavigationController *nav = (UINavigationController *)self.presentedViewController;
			vc = (FieldEditorViewController *)nav.viewControllers[0];
		} else {
			vc = (FieldEditorViewController *)[self.navigationController.viewControllers lastObject];
		}
		NSString *username = vc.values[kAccountUsername];
		NSString *password = vc.values[kAccountPassword];
		NSString *providerID = vc.values[kAccountProviderID];
		
		if ((username.length == 0) || (password.length == 0)) {
            [[UIViewController topViewController] displayAlertWithTitle:nil
                                                                message:NSLocalizedString(@"Please enter your username and password first.", nil)];
            return;
        } else if (providerID.length == 0) {
            [[UIViewController topViewController] displayAlertWithTitle:nil
                                                                message:NSLocalizedString(@"Please fill in your provider ID first.", nil)];
            return;
        }
		[vc dismissKeyboard];
		
		NSDictionary *loginInfo = @{
			kAccountUsername: username,
			kAccountPassword: password,
			kAccountProviderID: providerID
		};
		
		ASProgressHUD *hud = [ASProgressHUD showHUDAddedTo:vc.navigationController.view animated:YES];
		hud.label.text = NSLocalizedString(@"Fetching Vendor ID…", nil);
		[self findVendorIDsWithLogin:loginInfo];
	}
}

- (void)doExport {
	ASProgressHUD *hud = [ASProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
	hud.mode = MBProgressHUDModeDeterminateHorizontalBar;
	hud.label.text = NSLocalizedString(@"Exporting", nil);
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
		NSURL *documentsURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
		NSString *exportFolder = [self folderNameForExportingReportsOfAccount:self.selectedAccount];
		NSURL *exportURL = [documentsURL URLByAppendingPathComponent:exportFolder];
		NSURL *exportedReportsZipFileURL = [exportURL URLByAppendingPathExtension:@"zip"];
		
		[[NSFileManager defaultManager] removeItemAtURL:exportedReportsZipFileURL error:nil];
		[[NSFileManager defaultManager] createDirectoryAtURL:exportURL withIntermediateDirectories:YES attributes:nil error:nil];
		
		NSOperationQueue *reportExportQueue = [[NSOperationQueue alloc] init];
		reportExportQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
		reportExportQueue.qualityOfService = NSQualityOfServiceUserInitiated;
		
		__block NSNumber *exportedReports = @(0);
		__block NSUInteger totalReports = self.selectedAccount.dailyReports.count + self.selectedAccount.weeklyReports.count;
		
		void (^exportBlock)(Report *report) = ^(Report *report) {
			NSString *csv = [report valueForKeyPath:@"originalReport.content"];
			NSString *filename = [report valueForKeyPath:@"originalReport.filename"];
			if ([filename hasSuffix:@".gz"]) {
				filename = [filename substringToIndex:filename.length - 3];
			}
			NSURL *reportURL = [exportURL URLByAppendingPathComponent:filename];
			[csv writeToURL:reportURL atomically:YES encoding:NSUTF8StringEncoding error:nil];
			
			@synchronized(exportedReports) {
				exportedReports = @(exportedReports.unsignedIntegerValue + 1);
				dispatch_async(dispatch_get_main_queue(), ^{
					hud.progress = ((CGFloat)exportedReports.unsignedIntegerValue / (CGFloat)totalReports);
				});
			}
		};
		
		[reportExportQueue addOperationWithBlock:^{
			for (Report *dailyReport in self.selectedAccount.dailyReports) {
				[reportExportQueue addOperationWithBlock:^{
					exportBlock(dailyReport);
				}];
			}
		}];
		
		[reportExportQueue addOperationWithBlock:^{
			for (Report *weeklyReport in self.selectedAccount.weeklyReports) {
				[reportExportQueue addOperationWithBlock:^{
					exportBlock(weeklyReport);
				}];
			}
		}];
		
		[reportExportQueue waitUntilAllOperationsAreFinished];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			hud.mode = MBProgressHUDModeIndeterminate;
			hud.label.text = NSLocalizedString(@"Compressing", nil);
		});
		
		ZIPArchive *zipArchive = [[ZIPArchive alloc] initWithFileURL:exportedReportsZipFileURL];
		[zipArchive addDirectoryToArchive:exportURL];
		[zipArchive writeToFile];
		
		[[NSFileManager defaultManager] removeItemAtURL:exportURL error:nil];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[ASProgressHUD hideHUDForView:self.navigationController.view animated:YES];
			
			self.documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:exportedReportsZipFileURL];
			self.documentInteractionController.delegate = self;
			[self.documentInteractionController presentOptionsMenuFromRect:self.navigationController.view.bounds inView:self.navigationController.view animated:YES];
		});
	});
}

- (NSString *)folderNameForExportingReportsOfAccount:(ASAccount *)account {
	NSString *folder = account.title;
	if (!folder || folder.length == 0) {
		folder = account.username;
	}
	if (!folder || folder.length == 0) {
		folder = @"Untitled Account";
	}
	folder = [folder stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
	folder = [folder stringByReplacingOccurrencesOfString:@":" withString:@"-"];
	
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"YYYY-MM-dd"];
	NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
	folder = [folder stringByAppendingFormat:@" %@", dateString];
	return folder;
}

- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller {
	self.documentInteractionController = nil;
}

- (void)fieldEditorDidCancel:(FieldEditorViewController *)editor {
	[editor dismissViewControllerAnimated:YES completion:nil];
}

- (void)didSettingsChanged:(KKPasscodeSettingsViewController *)viewController {
  
  if ([[KKPasscodeLock sharedLock] isPasscodeRequired]) {
	passcodeLockField.defaultValue = @"On";
  } else {
	passcodeLockField.defaultValue = @"Off";
  }
  
  [settingsViewController.tableView reloadData];
}

- (void)iconCleared:(NSNotification *)notification {
	NSString *productID = notification.userInfo[kIconManagerClearedIconNotificationAppID];
	if (productID) {
		// Reload icon.
		[[IconManager sharedManager] iconForAppID:productID];
	}
}

- (void)iconReloadFailed:(NSNotification *)notification {
    NSString *productID = notification.userInfo[kIconManagerReloadFailedIconNotificationAppID];
    if (productID) {
        [self promptForCountryCodeForAppID:productID];
    }
}

- (void)promptForCountryCodeForAppID:(NSString *)appId {
    UIAlertController *prompt = [UIAlertController alertControllerWithTitle:@"Icon not found"
                                                                    message:@"Would you like to try again with a specific country code?"
                                                             preferredStyle:UIAlertControllerStyleAlert];
    
    [prompt addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"2 letter country code";
    }];
    
    [prompt addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                               style:UIAlertActionStyleCancel
                                             handler:nil]];
    
    [prompt addAction:[UIAlertAction actionWithTitle:@"Retry"
                                               style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction * _Nonnull action) {
        UITextField *countryField = prompt.textFields.firstObject;
        if (![countryField.text isEqualToString:@""] && countryField.text.length == 2) {
            
            // Retry with a different country code
            [[IconManager sharedManager] setCountryCode:countryField.text];
            [[IconManager sharedManager] clearIconForAppID:appId];
        }
    }]];
    
    [self presentViewController:prompt animated:YES completion:nil];
}

#pragma mark -

- (void)saveContext {
	NSError *error = nil;
	if (![[self managedObjectContext] save:&error]) { 
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	}
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        return UIInterfaceOrientationMaskAll;
    }
    return UIInterfaceOrientationMaskPortrait;
}

@end
