//
//  RootViewController.m
//  AppSales
//
//  Created by Ole Zorn on 30.06.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "AccountsViewController.h"
#import "SalesViewController.h"
#import "ReviewsViewController.h"
#import "SSKeychain.h"
#import "ASAccount.h"
#import "Report.h"
#import "Product.h"
#import "CurrencyManager.h"
#import "ReportDownloadCoordinator.h"
#import "MBProgressHUD.h"
#import "ReportImportOperation.h"
#import "PaymentsViewController.h"
#import "BadgedCell.h"
#import "UIImage+Tinting.h"
#import "AboutViewController.h"
#import "AccountStatusView.h"
#import "PromoCodesViewController.h"
#import "PromoCodesLicenseViewController.h"

#define kAddNewAccountEditorIdentifier		@"AddNewAccountEditorIdentifier"
#define kEditAccountEditorIdentifier		@"EditAccountEditorIdentifier"
#define kSettingsEditorIdentifier			@"SettingsEditorIdentifier"
#define kUpdateExchangeRatesButton			@"UpdateExchangeRatesButton"
#define kImportReportsButton				@"ImportReportsButton"
#define kExportReportsButton				@"ExportReportsButton"
#define	kDeleteAccountButton				@"DeleteAccount"
#define kAlertTagConfirmImport				1
#define kAlertTagConfirmExport				2
#define kAlertTagConfirmDelete				3
#define kAccountTitle						@"title"
#define kKeychainServiceIdentifier			@"iTunesConnect"


@implementation AccountsViewController

@synthesize managedObjectContext, accounts, selectedAccount, refreshButtonItem;

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.refreshButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(downloadReports:)] autorelease];
	UIBarButtonItem *settingsButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Settings", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(showSettings)] autorelease];
	UIBarButtonItem *flexSpace = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
	UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
	[infoButton addTarget:self action:@selector(showInfo:) forControlEvents:UIControlEventTouchUpInside];
	UIBarButtonItem *infoButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:infoButton] autorelease];
	
	self.toolbarItems = [NSArray arrayWithObjects:infoButtonItem, flexSpace, settingsButtonItem, nil];
	self.navigationItem.rightBarButtonItem = refreshButtonItem;
	
	self.title = NSLocalizedString(@"AppSales", nil);
	UIBarButtonItem *addButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNewAccount)] autorelease];
	self.navigationItem.leftBarButtonItem = addButton;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextDidChange:) name:NSManagedObjectContextObjectsDidChangeNotification object:[self managedObjectContext]];
	
	[[ReportDownloadCoordinator sharedReportDownloadCoordinator] addObserver:self forKeyPath:@"isBusy" options:NSKeyValueObservingOptionNew context:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(promoCodeLicenseAgreementLoaded:) name:@"PromoCodeOperationLoadedLicenseAgreementNotification" object:nil];
	
	[self reloadAccounts];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualToString:@"isBusy"]) {
		dispatch_async(dispatch_get_main_queue(), ^ {
			self.refreshButtonItem.enabled = ![[ReportDownloadCoordinator sharedReportDownloadCoordinator] isBusy];
		});
	}
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	if (![[ReportDownloadCoordinator sharedReportDownloadCoordinator] isBusy] && [self.accounts count] == 0) {
		[self addNewAccount];
	}
}

- (void)contextDidChange:(NSNotification *)notification
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[self.tableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.1];
}

- (void)reloadAccounts
{
	NSFetchRequest *accountsFetchRequest = [[[NSFetchRequest alloc] init] autorelease];
	[accountsFetchRequest setEntity:[NSEntityDescription entityForName:@"Account" inManagedObjectContext:self.managedObjectContext]];
	[accountsFetchRequest setSortDescriptors:[NSArray arrayWithObjects:[[[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES] autorelease], [[[NSSortDescriptor alloc] initWithKey:@"username" ascending:YES] autorelease], nil]];
	self.accounts = [self.managedObjectContext executeFetchRequest:accountsFetchRequest error:NULL];
	
	[self.tableView reloadData];
}

- (void)downloadReports:(id)sender
{
	for (ASAccount *account in self.accounts) {
		if (account.password && account.password.length > 0) { //Only download reports for accounts with login
			if (!account.vendorID || account.vendorID.length == 0) {
				[[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Vendor ID Missing", nil) 
											 message:[NSString stringWithFormat:NSLocalizedString(@"You have not entered a vendor ID for the account \"%@\". Please go to the account's settings and fill in the missing information.", nil), [account displayName]] 
											delegate:nil 
								   cancelButtonTitle:NSLocalizedString(@"OK", nil) 
								   otherButtonTitles:nil] autorelease] show];
			} else {
				[[ReportDownloadCoordinator sharedReportDownloadCoordinator] downloadReportsForAccount:account];
			}
		}
	}
}

- (void)showInfo:(id)sender
{
	AboutViewController *aboutViewController = [[[AboutViewController alloc] initWithNibName:nil bundle:nil] autorelease];
	UINavigationController *aboutNavController = [[[UINavigationController alloc] initWithRootViewController:aboutViewController] autorelease];
	aboutNavController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	[self presentModalViewController:aboutNavController animated:YES];
}

- (void)promoCodeLicenseAgreementLoaded:(NSNotification *)notification
{
	NSString *licenseAgreement = [[notification userInfo] objectForKey:@"licenseAgreement"];
	PromoCodesLicenseViewController *vc = [[[PromoCodesLicenseViewController alloc] initWithLicenseAgreement:licenseAgreement operation:[notification object]] autorelease];
	UINavigationController *navController = [[[UINavigationController alloc] initWithRootViewController:vc] autorelease];
	[self presentModalViewController:navController animated:YES];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}


#pragma mark - Table view

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if ([self.accounts count] == 0) {
		return nil;
	}
	ASAccount *account = [self.accounts objectAtIndex:section];
	NSString *title = account.title;
	if (!title || [title isEqualToString:@""]) {
		title = account.username;
	}
	return title;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	if ([self.accounts count] == 0) {
		return 1;
	}
	return [self.accounts count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if ([self.accounts count] == 0) {
		return 0;
	}
	return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *cellIdentifier = @"Cell";
	BadgedCell *cell = (BadgedCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil) {
		cell = [[[BadgedCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier] autorelease];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	if (indexPath.row == 0) {
		NSInteger badge = [[[self.accounts objectAtIndex:indexPath.section] reportsBadge] integerValue];
		cell.textLabel.text = NSLocalizedString(@"Sales and Trends", nil);
		cell.badgeCount = badge;
		cell.imageView.image = [UIImage imageNamed:@"Sales.png"];
		cell.imageView.highlightedImage = [UIImage as_tintedImageNamed:@"Sales.png" color:[UIColor whiteColor]];
	} else if (indexPath.row == 1) {
		NSInteger badge = [[[self.accounts objectAtIndex:indexPath.section] paymentsBadge] integerValue];
		cell.textLabel.text = NSLocalizedString(@"Payments", nil);
		cell.badgeCount = badge;
		cell.imageView.image = [UIImage imageNamed:@"Payments.png"];
		cell.imageView.highlightedImage = [UIImage as_tintedImageNamed:@"Payments.png" color:[UIColor whiteColor]];
	} else if (indexPath.row == 2) {
		cell.textLabel.text = NSLocalizedString(@"Customer Reviews", nil);
		cell.imageView.image = [UIImage imageNamed:@"Reviews.png"];
		cell.imageView.highlightedImage = [UIImage as_tintedImageNamed:@"Reviews.png" color:[UIColor whiteColor]];
		
		ASAccount *account = [self.accounts objectAtIndex:indexPath.section];
		NSFetchRequest *unreadReviewsRequest = [[[NSFetchRequest alloc] init] autorelease];
		[unreadReviewsRequest setEntity:[NSEntityDescription entityForName:@"Review" inManagedObjectContext:[self managedObjectContext]]];
		[unreadReviewsRequest setPredicate:[NSPredicate predicateWithFormat:@"product.account == %@ AND unread == TRUE", account]];
		cell.badgeCount = [[self managedObjectContext] countForFetchRequest:unreadReviewsRequest error:NULL];
	} else if (indexPath.row == 3) {
		cell.textLabel.text = NSLocalizedString(@"Promo Codes", nil);
		cell.imageView.image = [UIImage imageNamed:@"PromoCodes.png"];
		cell.imageView.highlightedImage = [UIImage as_tintedImageNamed:@"PromoCodes.png" color:[UIColor whiteColor]];
		cell.badgeCount = 0;
	} else if (indexPath.row == 4) {
		cell.textLabel.text = NSLocalizedString(@"Account", nil);
		cell.imageView.image = [UIImage imageNamed:@"Account.png"];
		cell.imageView.highlightedImage = [UIImage as_tintedImageNamed:@"Account.png" color:[UIColor whiteColor]];
		cell.badgeCount = 0;
	}	
	return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
	if ([self.accounts count] == 0) {
		return nil;
	}
	ASAccount *account = [self.accounts objectAtIndex:section];
	return [[[AccountStatusView alloc] initWithFrame:CGRectMake(0, 0, 320, 26) account:account] autorelease];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
	return 26.0;
}

/*
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	if ([self.accounts count] == 0) {
		return NSLocalizedString(@"Tap the \u271A button to add an account.", nil);
	}
	return nil;
}
 */

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 44.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	ASAccount *account = [self.accounts objectAtIndex:indexPath.section];
	if (indexPath.row == 0) {
		SalesViewController *salesViewController = [[[SalesViewController alloc] initWithAccount:account] autorelease];
		[self.navigationController pushViewController:salesViewController animated:YES];
	} else if (indexPath.row == 1) {
		PaymentsViewController *paymentsViewController = [[[PaymentsViewController alloc] initWithAccount:account] autorelease];
		[self.navigationController pushViewController:paymentsViewController animated:YES];
	} else if (indexPath.row == 2) {
		ReviewsViewController *reviewsViewController = [[[ReviewsViewController alloc] initWithAccount:account] autorelease];
		[self.navigationController pushViewController:reviewsViewController animated:YES];
	} else if (indexPath.row == 3) {
		PromoCodesViewController *promoCodesViewController = [[[PromoCodesViewController alloc] initWithAccount:account] autorelease];
		[self.navigationController pushViewController:promoCodesViewController animated:YES];
	} else if (indexPath.row == 4) {
		[self editAccount:account];
	}
}

#pragma mark -

- (void)deleteAccount:(NSManagedObject *)account
{
	if (account) {
		NSManagedObjectContext *context = self.managedObjectContext;
		[context deleteObject:account];
		[MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
		[self reloadAccounts];
	}
}

- (void)addNewAccount
{
	FieldSpecifier *titleField = [FieldSpecifier textFieldWithKey:kAccountTitle title:@"Description" defaultValue:@""];
	titleField.placeholder = NSLocalizedString(@"optional", nil);
	FieldSectionSpecifier *titleSection = [FieldSectionSpecifier sectionWithFields:[NSArray arrayWithObject:titleField] title:nil description:nil];
	
	FieldSpecifier *usernameField = [FieldSpecifier emailFieldWithKey:kAccountUsername title:NSLocalizedString(@"Email", nil) defaultValue:@""];
	FieldSpecifier *passwordField = [FieldSpecifier passwordFieldWithKey:kAccountPassword title:NSLocalizedString(@"Password", nil) defaultValue:@""];
	FieldSpecifier *vendorIDField = [FieldSpecifier numericFieldWithKey:kAccountVendorID title:NSLocalizedString(@"Vendor ID", nil) defaultValue:@""];
	vendorIDField.placeholder = @"8XXXXXXX";
	FieldSpecifier *selectVendorIDButtonField = [FieldSpecifier buttonFieldWithKey:@"SelectVendorIDButton" title:NSLocalizedString(@"Auto-Fill Vendor ID...", nil)];
	
	FieldSectionSpecifier *loginSection = [FieldSectionSpecifier sectionWithFields:[NSArray arrayWithObjects:usernameField, passwordField, vendorIDField, selectVendorIDButtonField, nil] 
																			 title:NSLocalizedString(@"iTunes Connect Login", nil) 
																	   description:NSLocalizedString(@"You can import reports via iTunes File Sharing without entering your login.", nil)];
	
	NSArray *sections = [NSArray arrayWithObjects:titleSection, loginSection, nil];
	FieldEditorViewController *addAccountViewController = [[[FieldEditorViewController alloc] initWithFieldSections:sections title:NSLocalizedString(@"New Account",nil)] autorelease];
	addAccountViewController.cancelButtonTitle = NSLocalizedString(@"Cancel", nil);
	addAccountViewController.doneButtonTitle = NSLocalizedString(@"Done", nil);
	addAccountViewController.delegate = self;
	addAccountViewController.editorIdentifier = kAddNewAccountEditorIdentifier;
	UINavigationController *navigationController = [[[UINavigationController alloc] initWithRootViewController:addAccountViewController] autorelease];
	
	[self presentModalViewController:navigationController animated:YES];
}

- (void)editAccount:(ASAccount *)account
{
	self.selectedAccount = account;
	NSString *username = account.username;
	NSString *password = account.password;
	NSString *title = account.title;
	NSString *vendorID = account.vendorID;
	
	FieldSpecifier *titleField = [FieldSpecifier textFieldWithKey:kAccountTitle title:@"Description" defaultValue:title];
	titleField.placeholder = NSLocalizedString(@"optional", nil);
	
	FieldSpecifier *usernameField = [FieldSpecifier emailFieldWithKey:kAccountUsername title:NSLocalizedString(@"Username", nil) defaultValue:username];
	FieldSpecifier *passwordField = [FieldSpecifier passwordFieldWithKey:kAccountPassword title:NSLocalizedString(@"Password", nil) defaultValue:password];
	FieldSpecifier *vendorIDField = [FieldSpecifier numericFieldWithKey:kAccountVendorID title:NSLocalizedString(@"Vendor ID", nil) defaultValue:vendorID];
	FieldSpecifier *selectVendorIDButtonField = [FieldSpecifier buttonFieldWithKey:@"SelectVendorIDButton" title:NSLocalizedString(@"Auto-Fill Vendor ID...", nil)];
	
	vendorIDField.placeholder = @"8XXXXXXX";
	FieldSectionSpecifier *loginSection = [FieldSectionSpecifier sectionWithFields:[NSArray arrayWithObjects:usernameField, passwordField, vendorIDField, selectVendorIDButtonField, nil] 
																			 title:NSLocalizedString(@"iTunes Connect Login", nil) 
																	   description:nil];
	FieldSpecifier *loginSubsectionField = [FieldSpecifier subsectionFieldWithSection:loginSection key:@"iTunesConnect"];
	FieldSectionSpecifier *titleSection = [FieldSectionSpecifier sectionWithFields:[NSArray arrayWithObjects:titleField, loginSubsectionField, nil] title:nil description:nil];
	
	FieldSpecifier *importButtonField = [FieldSpecifier buttonFieldWithKey:kImportReportsButton title:NSLocalizedString(@"Import Reports...", nil)];
	FieldSpecifier *exportButtonField = [FieldSpecifier buttonFieldWithKey:kExportReportsButton title:NSLocalizedString(@"Export Reports...", nil)];
	FieldSectionSpecifier *importExportSection = [FieldSectionSpecifier sectionWithFields:[NSArray arrayWithObjects:importButtonField, exportButtonField, nil] 
																					title:nil 
																			  description:nil /*NSLocalizedString(@"Use iTunes file sharing to import report files from your computer.",nil)*/];
	
	NSMutableArray *productFields = [NSMutableArray array];
	NSArray *allProducts = [[account.products allObjects] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"productID" ascending:NO] autorelease]]];
	
	for (Product *product in allProducts) {
		FieldSpecifier *productNameField = [FieldSpecifier textFieldWithKey:[NSString stringWithFormat:@"product.name.%@", product.productID] title:NSLocalizedString(@"Name", nil) defaultValue:[product displayName]];
		FieldSpecifier *hideProductField = [FieldSpecifier switchFieldWithKey:[NSString stringWithFormat:@"product.hidden.%@", product.productID] title:NSLocalizedString(@"Hide in Dashboard", nil) defaultValue:[product.hidden boolValue]];
		FieldSectionSpecifier *productSection = [FieldSectionSpecifier sectionWithFields:[NSArray arrayWithObjects:productNameField, hideProductField, nil] title:nil description:nil];
		FieldSpecifier *showInAppStoreField = [FieldSpecifier buttonFieldWithKey:[NSString stringWithFormat:@"product.appstore.%@", product.productID] title:NSLocalizedString(@"Show in App Store...", nil)];
		NSString *productFooter = [NSString stringWithFormat:@"Current version: %@\nApple ID: %@", ((product.currentVersion) ? product.currentVersion : @"N/A"), product.productID];
		FieldSectionSpecifier *showInAppStoreSection = [FieldSectionSpecifier sectionWithFields:[NSArray arrayWithObject:showInAppStoreField] title:nil description:productFooter];
		FieldSpecifier *productSectionField = [FieldSpecifier subsectionFieldWithSections:[NSArray arrayWithObjects:productSection, showInAppStoreSection, nil] key:[NSString stringWithFormat:@"product.section.%@", product.productID] title:[product defaultDisplayName]];
		[productFields addObject:productSectionField];
	}
	FieldSectionSpecifier *productsSection = [FieldSectionSpecifier sectionWithFields:productFields title:NSLocalizedString(@"Manage Apps", nil) description:nil];
	FieldSpecifier *manageProductsSectionField = [FieldSpecifier subsectionFieldWithSection:productsSection key:@"ManageProducts"];
	FieldSectionSpecifier *manageProductsSection = [FieldSectionSpecifier sectionWithFields:[NSArray arrayWithObject:manageProductsSectionField] title:nil description:nil];
	if ([allProducts count] == 0) {
		productsSection.description = NSLocalizedString(@"This account does not contain any apps yet. Import or download reports first.", nil);
	}
	
	FieldSpecifier *deleteAccountButtonField = [FieldSpecifier buttonFieldWithKey:kDeleteAccountButton title:NSLocalizedString(@"Delete Account...", nil)];
	FieldSectionSpecifier *deleteAccountSection = [FieldSectionSpecifier sectionWithFields:[NSArray arrayWithObject:deleteAccountButtonField] title:nil description:nil];
	
	NSArray *sections = [NSArray arrayWithObjects:titleSection, importExportSection, manageProductsSection, deleteAccountSection, nil];
	FieldEditorViewController *editAccountViewController = [[[FieldEditorViewController alloc] initWithFieldSections:sections title:NSLocalizedString(@"Account Details",nil)] autorelease];
	editAccountViewController.doneButtonTitle = nil;
	editAccountViewController.delegate = self;
	editAccountViewController.editorIdentifier = kEditAccountEditorIdentifier;
	editAccountViewController.context = account;
	editAccountViewController.hidesBottomBarWhenPushed = YES;
	
	[self.navigationController pushViewController:editAccountViewController animated:YES];
}

- (void)showSettings
{
  // main section
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
	FieldSectionSpecifier *mainSection = [FieldSectionSpecifier sectionWithFields:[NSArray arrayWithObjects:currencySectionField, updateExchangeRatesButtonField, nil] 
																			title:NSLocalizedString(@"General", nil) 
																	  description:NSLocalizedString(@"Exchange rates will automatically be refreshed periodically.", nil)];


  
  // products section
  NSString* productSortByValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"ProductSortby"];
  FieldSpecifier *productSortingByProductIdField = [FieldSpecifier checkFieldWithKey:@"sortby.productId" title:@"Product ID" 
                                                                        defaultValue:[productSortByValue isEqualToString:@"productId"]];
  FieldSpecifier *productSortingByColorField = [FieldSpecifier checkFieldWithKey:@"sortby.color" title:@"Color" 
                                                                    defaultValue:[productSortByValue isEqualToString:@"color"]];
  NSMutableArray *productSortingFields = [NSArray arrayWithObjects:productSortingByProductIdField, productSortingByColorField, nil];


  FieldSectionSpecifier *productSortingSection = [FieldSectionSpecifier sectionWithFields:productSortingFields
                                                                              title:NSLocalizedString(@"Sort By", nil)
                                                                        description:nil];
  productSortingSection.exclusiveSelection = YES;
  FieldSpecifier *productsSectionField = [FieldSpecifier subsectionFieldWithSection:productSortingSection key:@"sortby"];
  FieldSectionSpecifier *productsSection = [FieldSectionSpecifier sectionWithFields:[NSArray arrayWithObjects:productsSectionField, nil] 
                                                                              title:NSLocalizedString(@"Products", nil) 
                                                                        description:NSLocalizedString(@"", nil)];
  
	NSArray *sections = [NSArray arrayWithObjects:mainSection, productsSection, nil];
	FieldEditorViewController *settingsViewController = [[[FieldEditorViewController alloc] initWithFieldSections:sections title:NSLocalizedString(@"Settings",nil)] autorelease];
	settingsViewController.doneButtonTitle = NSLocalizedString(@"Done", nil);
	settingsViewController.delegate = self;
	settingsViewController.editorIdentifier = kSettingsEditorIdentifier;
	
	UINavigationController *settingsNavController = [[[UINavigationController alloc] initWithRootViewController:settingsViewController] autorelease];
	[self presentModalViewController:settingsNavController animated:YES];
}

- (void)fieldEditor:(FieldEditorViewController *)editor didFinishEditingWithValues:(NSDictionary *)returnValues
{
	if ([editor.editorIdentifier isEqualToString:kAddNewAccountEditorIdentifier] || [editor.editorIdentifier isEqualToString:kEditAccountEditorIdentifier]) {
		NSString *username = [returnValues objectForKey:kAccountUsername];
		NSString *password = [returnValues objectForKey:kAccountPassword];
		NSString *vendorID = [returnValues objectForKey:kAccountVendorID];
		NSString *title = [returnValues objectForKey:kAccountTitle];
		if ((!username || [username isEqualToString:@""]) && (!title || [title isEqualToString:@""])) {
			[[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Missing Information", nil) message:NSLocalizedString(@"You need to enter at least a username or a description.\n\nIf you want to download reports from iTunes Connect, you need to enter your username and password, otherwise you can just enter a description.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] autorelease] show];
			return;
		}
		if ([editor.editorIdentifier isEqualToString:kAddNewAccountEditorIdentifier]) {
			if (password && (!vendorID || vendorID.length == 0)) {
				[[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Missing Information", nil) message:NSLocalizedString(@"You need to enter a vendor ID. If you don't know your vendor ID, tap \"Auto-Fill Vendor ID\".", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] autorelease] show];
				return;
			}
			ASAccount *account = (ASAccount *)[NSEntityDescription insertNewObjectForEntityForName:@"Account" inManagedObjectContext:self.managedObjectContext];
			account.title = title;
			account.username = username;
			account.vendorID = vendorID;
			account.sortIndex = [NSNumber numberWithLong:time(NULL)];
			[account setPassword:password];
		}
		else if ([editor.editorIdentifier isEqualToString:kEditAccountEditorIdentifier]) {
			ASAccount *account = (ASAccount *)editor.context;
			[account deletePassword];
			account.username = username;
			account.title = title;
			account.vendorID = vendorID;
			[account setPassword:password];
			
			NSMutableDictionary *productsByID = [NSMutableDictionary dictionary];
			for (Product *product in self.selectedAccount.products) {
				[productsByID setObject:product forKey:product.productID];
			}
			for (NSString *key in [returnValues allKeys]) {
				if ([key hasPrefix:@"product.name."]) {
					NSString *productID = [key substringFromIndex:[@"product.name." length]];
					Product *product = [productsByID objectForKey:productID];
					NSString *newName = [returnValues objectForKey:key];
					if (![[product displayName] isEqualToString:newName]) {
						product.customName = newName;
					}
				} else if ([key hasPrefix:@"product.hidden."]) {
					NSString *productID = [key substringFromIndex:[@"product.hidden." length]];
					Product *product = [productsByID objectForKey:productID];
					product.hidden = [returnValues objectForKey:key];
				}
			}
		}
		[self saveContext];
		if ([editor.editorIdentifier isEqualToString:kAddNewAccountEditorIdentifier]) {
			[editor dismissModalViewControllerAnimated:YES];
		}
		self.selectedAccount = nil;
	} else if ([editor.editorIdentifier isEqualToString:kSettingsEditorIdentifier]) {
		for (NSString *key in [returnValues allKeys]) {
			if ([key hasPrefix:@"currency."]) {
				if ([[returnValues objectForKey:key] boolValue]) {
					[[CurrencyManager sharedManager] setBaseCurrency:[[key componentsSeparatedByString:@"."] lastObject]];
				}
			}
      
      if ([key hasPrefix:@"sortby."]) {
				if ([[returnValues objectForKey:key] boolValue]) {
          [[NSUserDefaults standardUserDefaults] setObject:[[key componentsSeparatedByString:@"."] lastObject] forKey:@"ProductSortby"];
				}
			}
      
		}
		[self dismissModalViewControllerAnimated:YES];
	}
	[self reloadAccounts];
}

- (void)fieldEditor:(FieldEditorViewController *)editor pressedButtonWithKey:(NSString *)key
{
	if ([key isEqualToString:kUpdateExchangeRatesButton]) {
		[[CurrencyManager sharedManager] forceRefresh];
	} else if ([key isEqualToString:kImportReportsButton]) {
		ASAccount *account = (ASAccount *)editor.context;
		if (account.isDownloadingReports) {
			[[[[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"AppSales is already importing reports for this account. Please wait until the current import has finished.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] autorelease] show];
		} else {
			BOOL canStartImport = [ReportImportOperation filesAvailableToImport];
			if (!canStartImport) {
				[[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No Files Found", nil) message:NSLocalizedString(@"The Documents directory does not contain any .txt files. Please use iTunes File Sharing to transfer report files to your device.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] autorelease] show];
			} else {
				UIAlertView *confirmImportAlert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Begin Import?", nil) 
																			  message:NSLocalizedString(@"Do you want to start importing all report files in the Documents directory into this account?", nil) 
																			 delegate:self 
																	cancelButtonTitle:NSLocalizedString(@"Cancel", nil) 
																	otherButtonTitles:NSLocalizedString(@"Start Import", nil), nil] autorelease];
				confirmImportAlert.tag = kAlertTagConfirmImport;
				[confirmImportAlert show];
			}
		}
	} else if ([key isEqualToString:kExportReportsButton]) {
		NSString *folderName = [self folderNameForExportingReportsOfAccount:self.selectedAccount];
		UIAlertView *confirmExportAlert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Export Reports?", nil) 
																	  message:[NSString stringWithFormat:NSLocalizedString(@"The original report files for this account will be exported to the folder \"%@\" in your Documents. You can access the exported files using iTunes File Sharing.", nil), folderName] 
																	 delegate:self 
															cancelButtonTitle:NSLocalizedString(@"Cancel", nil) 
															otherButtonTitles:NSLocalizedString(@"Continue", nil), nil] autorelease];
		confirmExportAlert.tag = kAlertTagConfirmExport;
		[confirmExportAlert show];
	} else if ([key hasPrefix:@"product.appstore."]) {
		NSString *productID = [key substringFromIndex:[@"product.appstore." length]];
		NSString *appStoreURLString = [NSString stringWithFormat:@"http://itunes.apple.com/app/id%@", productID];
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:appStoreURLString]];
	} else if ([key isEqualToString:kDeleteAccountButton]) {
		UIAlertView *confirmDeleteAlert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Delete Account?", nil) 
																	  message:NSLocalizedString(@"Do you really want to delete this account and all of its data?", nil) 
																	 delegate:self 
															cancelButtonTitle:NSLocalizedString(@"Cancel", nil) 
															otherButtonTitles:NSLocalizedString(@"Delete", nil), nil] autorelease];
		confirmDeleteAlert.tag = kAlertTagConfirmDelete;
		[confirmDeleteAlert show];
	} else if ([key isEqualToString:@"SelectVendorIDButton"]) {
		FieldEditorViewController *vc = nil;
		if (self.modalViewController) {
			UINavigationController *nav = (UINavigationController *)self.modalViewController;
			vc = (FieldEditorViewController *)[[nav viewControllers] objectAtIndex:0];
		} else {
			vc = (FieldEditorViewController *)[self.navigationController.viewControllers lastObject];
		}
		NSString *username = [vc.values objectForKey:kAccountUsername];
		NSString *password = [vc.values objectForKey:kAccountPassword];
		[vc dismissKeyboard];
		
		if (!username || username.length == 0 || !password || password.length == 0) {
			[[[[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"Please enter your username and password first.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] autorelease] show];
			return;
		}
		
		NSDictionary *loginInfo = [NSDictionary dictionaryWithObjectsAndKeys:password, kAccountPassword, username, kAccountUsername, nil];
		
		MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:vc.navigationController.view animated:YES];
		hud.labelText = NSLocalizedString(@"Checking Vendor ID...", nil);
		[hud showWhileExecuting:@selector(findVendorIDsWithLogin:) onTarget:self withObject:loginInfo animated:YES];
	}
}

- (NSString *)folderNameForExportingReportsOfAccount:(ASAccount *)account
{
	NSString *folder = account.title;
	if (!folder || folder.length == 0) {
		folder = account.username;
	}
	if (!folder || folder.length == 0) {
		folder = @"Untitled Account";
	}
	folder = [folder stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
	folder = [folder stringByReplacingOccurrencesOfString:@":" withString:@"-"];
	NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
	NSString *path = [docPath stringByAppendingPathComponent:folder];
	
	NSString *destPath = path;
	BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:destPath];
	int i = 1;
	while (exists) {
		destPath = [path stringByAppendingFormat:@" %i", i];
		exists = [[NSFileManager defaultManager] fileExistsAtPath:destPath];
		i++;
	}
	return [destPath lastPathComponent];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (alertView.tag == kAlertTagConfirmImport) {
		if (buttonIndex != [alertView cancelButtonIndex]) {
			[[ReportDownloadCoordinator sharedReportDownloadCoordinator] importReportsIntoAccount:self.selectedAccount];
			[self.navigationController popViewControllerAnimated:YES];
		}
	} else if (alertView.tag == kAlertTagConfirmExport) {
		if (buttonIndex != [alertView cancelButtonIndex]) {
			NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
			NSString *exportFolder = [self folderNameForExportingReportsOfAccount:self.selectedAccount];
			NSString *exportPath = [docPath stringByAppendingPathComponent:exportFolder];
			
			MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
			hud.labelText = NSLocalizedString(@"Exporting...", nil);
			double delayInSeconds = 0.25;
			dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
			dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
				[[NSFileManager defaultManager] createDirectoryAtPath:exportPath withIntermediateDirectories:YES attributes:nil error:NULL];
				
				void (^exportBlock)(Report *report) = ^ (Report *report) { 
					NSString *csv = [report valueForKeyPath:@"originalReport.content"];
					NSString *filename = [report valueForKeyPath:@"originalReport.filename"];
					if ([filename hasSuffix:@".gz"]) {
						filename = [filename substringToIndex:filename.length - 3];
					}
					NSString *reportPath = [exportPath stringByAppendingPathComponent:filename];
					[csv writeToFile:reportPath atomically:YES encoding:NSUTF8StringEncoding error:NULL];
				};
				for (Report *dailyReport in self.selectedAccount.dailyReports) {
					exportBlock(dailyReport);
				}
				for (Report *weeklyReport in self.selectedAccount.weeklyReports) {
					exportBlock(weeklyReport);
				}
				[MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
			});
		}
	} else if (alertView.tag == kAlertTagConfirmDelete) {
		if (buttonIndex != [alertView cancelButtonIndex]) {
			MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
			[hud setLabelText:NSLocalizedString(@"Deleting Account...", nil)];
			
			ASAccount *account = [[self.selectedAccount retain] autorelease];
			[self.navigationController popViewControllerAnimated:YES];
			[self performSelector:@selector(deleteAccount:) withObject:account afterDelay:0.1];
		}
	}
}

- (void)fieldEditorDidCancel:(FieldEditorViewController *)editor
{
	[editor dismissModalViewControllerAnimated:YES];
}

#pragma mark -

- (void)saveContext
{
	NSError *error = nil;
	if (![[self managedObjectContext] save:&error]) { 
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	}
}

- (void)dealloc
{
	[refreshButtonItem release];
	[accounts release];
	[selectedAccount release];
	[managedObjectContext release];
    [super dealloc];
}


@end
