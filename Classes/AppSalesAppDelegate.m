//
//  AppSalesAppDelegate.m
//  AppSales
//
//  Created by Ole Zorn on 30.06.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "AppSalesAppDelegate.h"
#import "AccountsViewController.h"
#import "CurrencyManager.h"
#import "ReportDownloadOperation.h"
#import "ReportDownloadCoordinator.h"
#import "PromoCodeOperation.h"
#import "SSKeychain.h"
#import "ASAccount.h"
#import "SalesViewController.h"
#import "ReviewsViewController.h"
#import "PaymentsViewController.h"
#import "PromoCodesViewController.h"
#import "PromoCodesLicenseViewController.h"

@implementation AppSalesAppDelegate

@synthesize window, accountsViewController, accountsPopover;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    NSURL *storeURL = [[self applicationSupportDirectory] URLByAppendingPathComponent:@"AppSales.sqlite"];
    [MagicalRecord setupCoreDataStackWithStoreNamed:storeURL];
    
	[[KKPasscodeLock sharedLock] setDefaultSettings];
	[[KKPasscodeLock sharedLock] setEraseOption:NO];
	
	srandom(time(NULL));
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	
	NSString *currencyCode = [[NSLocale currentLocale] objectForKey:NSLocaleCurrencyCode];
	if (![[CurrencyManager sharedManager].availableCurrencies containsObject:currencyCode]) {
		currencyCode = @"USD";
	}
	
	NSDictionary *defaults = @{kSettingDownloadPayments: @YES,
							  @"CurrencyManagerBaseCurrency": currencyCode};
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(promoCodeLicenseAgreementLoaded:) name:@"PromoCodeOperationLoadedLicenseAgreementNotification" object:nil];
	
	BOOL iPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
	if (!iPad) {
		AccountsViewController *rootViewController = [[AccountsViewController alloc] initWithStyle:UITableViewStyleGrouped];
		rootViewController.managedObjectContext = [NSManagedObjectContext defaultContext];
		UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:rootViewController];
		navigationController.toolbarHidden = NO;
		self.accountsViewController = rootViewController;
		
		self.window.rootViewController = navigationController;
		[self.window makeKeyAndVisible];
	} else {
		self.accountsViewController = [[AccountsViewController alloc] initWithStyle:UITableViewStyleGrouped];
		self.accountsViewController.managedObjectContext = [NSManagedObjectContext defaultContext];
		self.accountsViewController.contentSizeForViewInPopover = CGSizeMake(320, 480);
		self.accountsViewController.delegate = self;
		UINavigationController *accountsNavController = [[UINavigationController alloc] initWithRootViewController:self.accountsViewController];
		accountsNavController.toolbarHidden = NO;
		self.accountsPopover = [[UIPopoverController alloc] initWithContentViewController:accountsNavController];	
		[self loadAccount:nil];
		[self.window makeKeyAndVisible];
	}
	
	[[CurrencyManager sharedManager] refreshIfNeeded];
	
	NSString* productSortByValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"ProductSortby"];
	if (productSortByValue==nil) {
		[[NSUserDefaults standardUserDefaults] setObject:@"productId" forKey:@"ProductSortby"];
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reportDownloadFailed:) name:ASReportDownloadFailedNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(promoCodeDownloadFailed:) name:ASPromoCodeDownloadFailedNotification object:nil];
	
	if (launchOptions[UIApplicationLaunchOptionsURLKey]) {
		[self.accountsViewController performSelector:@selector(downloadReports:) withObject:nil afterDelay:0.0];
	}
	
	[self showPasscodeLockIfNeeded];
	if (iPad) {
		//Restore previously-selected account:
		NSString *accountIDURIString = [[NSUserDefaults standardUserDefaults] stringForKey:kSettingSelectedAccountID];
		if (accountIDURIString) {
			NSManagedObjectID *accountID = [[NSManagedObjectContext defaultContext].persistentStoreCoordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:accountIDURIString]];
			ASAccount *account = (ASAccount *)[[NSManagedObjectContext defaultContext] objectWithID:accountID];
			if (account) {
				[self accountsViewController:nil didSelectAccount:account];
			}
		} else {
			[self selectAccount:nil];
		}
	}
	
	return YES;
}

- (void)selectAccount:(id)sender
{
	if (!self.window.rootViewController.modalViewController) {
		[self.accountsPopover presentPopoverFromRect:CGRectMake(50, 50, 1, 1) inView:self.window.rootViewController.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
	}
}

- (void)accountsViewController:(AccountsViewController *)viewController didSelectAccount:(ASAccount *)account
{
	[self.accountsPopover dismissPopoverAnimated:YES];
	[self loadAccount:account];
	
	NSString *accountIDURIString = [[[account objectID] URIRepresentation] absoluteString];
	[[NSUserDefaults standardUserDefaults] setObject:accountIDURIString forKey:kSettingSelectedAccountID];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex != actionSheet.cancelButtonIndex) {
		NSFetchRequest *accountsFetchRequest = [[NSFetchRequest alloc] init];
		[accountsFetchRequest setEntity:[NSEntityDescription entityForName:@"Account" inManagedObjectContext:[NSManagedObjectContext defaultContext]]];
		[accountsFetchRequest setSortDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES], [[NSSortDescriptor alloc] initWithKey:@"username" ascending:YES]]];
		NSArray *accounts = [[NSManagedObjectContext defaultContext] executeFetchRequest:accountsFetchRequest error:NULL];
		ASAccount *account = accounts[buttonIndex];
		[self loadAccount:account];
	}
}

- (void)loadAccount:(ASAccount *)account
{
	UIBarButtonItem *selectAccountButtonItem1 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Account", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(selectAccount:)];
	UIBarButtonItem *selectAccountButtonItem2 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Account", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(selectAccount:)];
	UIBarButtonItem *selectAccountButtonItem3 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Account", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(selectAccount:)];
	UIBarButtonItem *selectAccountButtonItem4 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Account", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(selectAccount:)];
	
	SalesViewController *salesVC = [[SalesViewController alloc] initWithAccount:account];
	salesVC.navigationItem.leftBarButtonItem = selectAccountButtonItem1;
	UINavigationController *salesNavController = [[UINavigationController alloc] initWithRootViewController:salesVC];
	
	ReviewsViewController *reviewsVC = [[ReviewsViewController alloc] initWithAccount:account];
	reviewsVC.navigationItem.leftBarButtonItem = selectAccountButtonItem2;
	UINavigationController *reviewsNavController = [[UINavigationController alloc] initWithRootViewController:reviewsVC];
	
	PaymentsViewController *paymentsVC = [[PaymentsViewController alloc] initWithAccount:account];
	paymentsVC.navigationItem.leftBarButtonItem = selectAccountButtonItem3;
	UINavigationController *paymentsNavController = [[UINavigationController alloc] initWithRootViewController:paymentsVC];
	
	PromoCodesViewController *promoVC = [[PromoCodesViewController alloc] initWithAccount:account];
	promoVC.navigationItem.leftBarButtonItem = selectAccountButtonItem4;
	UINavigationController *promoNavController = [[UINavigationController alloc] initWithRootViewController:promoVC];
	promoNavController.toolbarHidden = NO;
	promoNavController.toolbar.barStyle = UIBarStyleBlackOpaque;
	
	UITabBarController *tabController = [[UITabBarController alloc] initWithNibName:nil bundle:nil];
	[tabController setViewControllers:@[salesNavController, reviewsNavController, paymentsNavController, promoNavController]];
	
	self.window.rootViewController = tabController;
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
	[self.accountsViewController performSelector:@selector(downloadReports:) withObject:nil afterDelay:0.0];
	return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	[self saveContext];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	[[CurrencyManager sharedManager] refreshIfNeeded];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	[[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	[self showPasscodeLockIfNeeded];
}

- (void)showPasscodeLockIfNeeded
{
	if ([[KKPasscodeLock sharedLock] isPasscodeRequired]) {
		
		KKPasscodeViewController *vc = [[KKPasscodeViewController alloc] initWithNibName:nil bundle:nil];
		vc.mode = KKPasscodeModeEnter;
		vc.delegate = self;
		
		UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			nav.modalPresentationStyle = UIModalPresentationFullScreen;
			nav.navigationBar.barStyle = UIBarStyleBlack;
			nav.navigationBar.opaque = NO;
		} else {
			nav.navigationBar.tintColor = accountsViewController.navigationController.navigationBar.tintColor;
			nav.navigationBar.translucent = accountsViewController.navigationController.navigationBar.translucent;
			nav.navigationBar.opaque = accountsViewController.navigationController.navigationBar.opaque;
			nav.navigationBar.barStyle = accountsViewController.navigationController.navigationBar.barStyle;    
		}
		UIViewController *viewControllerForPresentingPasscode = nil;
		if (self.window.rootViewController.modalViewController) {
			if ([self.window.rootViewController.modalViewController isKindOfClass:[UINavigationController class]] 
				&& [[(UINavigationController *)self.window.rootViewController.modalViewController viewControllers][0] isKindOfClass:[KKPasscodeViewController class]]) {
				//The passcode dialog is already shown...
				return;
			}
			//We're in the settings or add account dialog...
			viewControllerForPresentingPasscode = self.window.rootViewController.modalViewController;
		} else {
			viewControllerForPresentingPasscode = self.window.rootViewController;
		}
		if (self.accountsPopover.popoverVisible) {
			[self.accountsPopover dismissPopoverAnimated:NO];
		}
		[[NSNotificationCenter defaultCenter] postNotificationName:ASWillShowPasscodeLockNotification object:self];
		[viewControllerForPresentingPasscode presentModalViewController:nav animated:NO];
	}
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	[self saveContext];
}

- (void)promoCodeLicenseAgreementLoaded:(NSNotification *)notification
{
	NSString *licenseAgreement = [notification userInfo][@"licenseAgreement"];
	PromoCodesLicenseViewController *vc = [[PromoCodesLicenseViewController alloc] initWithLicenseAgreement:licenseAgreement operation:[notification object]];
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
	[self.window.rootViewController presentModalViewController:navController animated:YES];
}

#pragma mark - Core Data

- (void)saveContext
{
    [[NSManagedObjectContext defaultContext] save];
    [[NSManagedObjectContext defaultContext] saveNestedContexts];
}

- (NSString *)applicationDocumentsDirectory
{
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

- (NSURL *)applicationSupportDirectory
{
	NSURL *appSupportDirectory = [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
	[[NSFileManager defaultManager] createDirectoryAtPath:[appSupportDirectory path] withIntermediateDirectories:YES attributes:nil error:NULL];
	return appSupportDirectory;
}

- (void)reportDownloadFailed:(NSNotification *)notification
{
	NSString *errorMessage = [notification userInfo][kASReportDownloadErrorDescription];
	NSString *alertMessage = [NSString stringWithFormat:NSLocalizedString(@"Downloading reports from iTunes Connect failed. Please try again later or check the iTunes Connect website for anything unusual. %@", nil), (errorMessage) ? errorMessage : @""];
	[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) 
								 message:alertMessage 
								delegate:nil 
					   cancelButtonTitle:NSLocalizedString(@"OK", nil) 
					   otherButtonTitles:nil] show];
}

- (void)promoCodeDownloadFailed:(NSNotification *)notification
{
	NSString *errorDescription = [notification userInfo][kASPromoCodeDownloadFailedErrorDescription];
	NSString *alertMessage = [NSString stringWithFormat:@"An error occured while downloading the promo codes (%@).", errorDescription];
	[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) 
								 message:alertMessage 
								delegate:nil 
					   cancelButtonTitle:NSLocalizedString(@"OK", nil) 
					   otherButtonTitles:nil] show];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
