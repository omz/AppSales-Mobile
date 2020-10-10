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
#import "SAMKeychain.h"
#import "ASAccount.h"
#import "SalesViewController.h"
#import "ReviewsViewController.h"
#import "PaymentsViewController.h"
#import "PromoCodesViewController.h"
#import "PromoCodesLicenseViewController.h"
#import "UIViewController+Alert.h"

@implementation AppSalesAppDelegate

@synthesize window, accountsViewController, accountsPopover;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	[[KKPasscodeLock sharedLock] setDefaultSettings];
	[[KKPasscodeLock sharedLock] setEraseOption:NO];
	
	srandom((unsigned)time(NULL));
	self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	
	NSString *currencyCode = [[NSLocale currentLocale] objectForKey:NSLocaleCurrencyCode];
	if (![[CurrencyManager sharedManager].availableCurrencies containsObject:currencyCode]) {
		currencyCode = @"USD";
	}
	
	NSDictionary *defaults = @{kSettingDownloadPayments: @(YES),
							   @"CurrencyManagerBaseCurrency": currencyCode};
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(promoCodeLicenseAgreementLoaded:) name:@"PromoCodeOperationLoadedLicenseAgreementNotification" object:nil];
	
	BOOL iPad = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad;
	if (!iPad) {
		AccountsViewController *rootViewController = [[AccountsViewController alloc] initWithStyle:UITableViewStyleGrouped];
		rootViewController.managedObjectContext = self.managedObjectContext;
		UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:rootViewController];
		navigationController.toolbarHidden = NO;
		self.accountsViewController = rootViewController;
		
		self.window.rootViewController = navigationController;
		[self.window makeKeyAndVisible];
	} else {
		self.accountsViewController = [[AccountsViewController alloc] initWithStyle:UITableViewStyleGrouped];
		self.accountsViewController.managedObjectContext = self.managedObjectContext;
		self.accountsViewController.preferredContentSize = CGSizeMake(320, 480);
		self.accountsViewController.delegate = self;
		UINavigationController *accountsNavController = [[UINavigationController alloc] initWithRootViewController:self.accountsViewController];
		accountsNavController.toolbarHidden = NO;
		self.accountsPopover = [[UIPopoverController alloc] initWithContentViewController:accountsNavController];	
		[self loadAccount:nil];
		[self.window makeKeyAndVisible];
	}
	
	BOOL migrating = [self migrateDataIfNeeded];
	if (migrating) {
		[self.accountsViewController reloadAccounts];
	}
	
	[[CurrencyManager sharedManager] refreshIfNeeded];
	
	NSString *productSortByValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"ProductSortby"];
	if (productSortByValue == nil) {
		[[NSUserDefaults standardUserDefaults] setObject:@"productId" forKey:@"ProductSortby"];
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(promoCodeDownloadFailed:) name:ASPromoCodeDownloadFailedNotification object:nil];
	
	if (launchOptions[UIApplicationLaunchOptionsURLKey]) {
		[self.accountsViewController performSelector:@selector(downloadReports:) withObject:nil afterDelay:0.0];
	}
	
	[self showPasscodeLockIfNeededWithBiometrics:YES];
	if (iPad) {
		//Restore previously-selected account:
		NSString *accountIDURIString = [[NSUserDefaults standardUserDefaults] stringForKey:kSettingSelectedAccountID];
		if (accountIDURIString) {
			NSManagedObjectID *accountID = [self.managedObjectContext.persistentStoreCoordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:accountIDURIString]];
			ASAccount *account = (ASAccount *)[self.managedObjectContext objectWithID:accountID];
			if (account) {
				[self accountsViewController:nil didSelectAccount:account];
			}
		} else {
			[self selectAccount:nil];
		}
	}
	
	return YES;
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
	BOOL iPad = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad);
	NSUInteger orientations = iPad ? UIInterfaceOrientationMaskAll : UIInterfaceOrientationMaskAllButUpsideDown;
	
	if (self.window.rootViewController) {
		UIViewController *presentedViewController = [[(UINavigationController *)self.window.rootViewController viewControllers] lastObject];
		orientations = [presentedViewController supportedInterfaceOrientations];
	}
	
	return orientations;
}

- (void)selectAccount:(id)sender {
	if (!self.window.rootViewController.presentedViewController) {
		[self.accountsPopover presentPopoverFromRect:CGRectMake(50, 50, 1, 1) inView:self.window.rootViewController.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
	}
}

- (void)accountsViewController:(AccountsViewController *)viewController didSelectAccount:(ASAccount *)account {
	[self.accountsPopover dismissPopoverAnimated:YES];
	[self loadAccount:account];
	
	NSString *accountIDURIString = [[[account objectID] URIRepresentation] absoluteString];
	[[NSUserDefaults standardUserDefaults] setObject:accountIDURIString forKey:kSettingSelectedAccountID];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex != actionSheet.cancelButtonIndex) {
		NSFetchRequest *accountsFetchRequest = [[NSFetchRequest alloc] init];
		[accountsFetchRequest setEntity:[NSEntityDescription entityForName:@"Account" inManagedObjectContext:self.managedObjectContext]];
		[accountsFetchRequest setSortDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES], [[NSSortDescriptor alloc] initWithKey:@"username" ascending:YES]]];
		NSArray *accounts = [self.managedObjectContext executeFetchRequest:accountsFetchRequest error:nil];
		ASAccount *account = accounts[buttonIndex];
		[self loadAccount:account];
	}
}

- (void)loadAccount:(ASAccount *)account {
	UIBarButtonItem *selectAccountButtonItem1 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Account", nil) style:UIBarButtonItemStylePlain target:self action:@selector(selectAccount:)];
	UIBarButtonItem *selectAccountButtonItem2 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Account", nil) style:UIBarButtonItemStylePlain target:self action:@selector(selectAccount:)];
	UIBarButtonItem *selectAccountButtonItem3 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Account", nil) style:UIBarButtonItemStylePlain target:self action:@selector(selectAccount:)];
	UIBarButtonItem *selectAccountButtonItem4 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Account", nil) style:UIBarButtonItemStylePlain target:self action:@selector(selectAccount:)];
	
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
	
	UITabBarController *tabController = [[UITabBarController alloc] init];
	[tabController setViewControllers:@[salesNavController, reviewsNavController, paymentsNavController, promoNavController]];
	
	self.window.rootViewController = tabController;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    [self.accountsViewController performSelector:@selector(downloadReports:) withObject:nil afterDelay:0.0];
    return YES;
}

- (BOOL)migrateDataIfNeeded {
	NSString *documentsDirectory = [self applicationDocumentsDirectory];
	NSString *legacyReportDirectory = [documentsDirectory stringByAppendingPathComponent:@"OriginalReports"];
	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL originalReportsDirectoryFound = [fm fileExistsAtPath:legacyReportDirectory];
	if (!originalReportsDirectoryFound) {
		return NO;
	}	
	NSArray *originalReportFiles = [fm contentsOfDirectoryAtPath:legacyReportDirectory error:nil];
	if ([originalReportFiles count] == 0) {
		//All files have been migrated, delete all the clutter in the documents directory:
		NSArray *files = [fm contentsOfDirectoryAtPath:documentsDirectory error:nil];
		for (NSString *file in files) {
			NSString *fullPath = [documentsDirectory stringByAppendingPathComponent:file];
			[fm removeItemAtPath:fullPath error:nil];
		}
		return NO;
	}
	NSString *oldUsername = [[NSUserDefaults standardUserDefaults] stringForKey:@"iTunesConnectUsername"];
	NSString *oldPassword = nil;
	if (oldUsername) {
		oldPassword = [SAMKeychain passwordForService:@"omz:software AppSales Mobile Service" account:oldUsername];
	}
	ASAccount *account = nil;
	if (oldUsername) {
		NSFetchRequest *accountFetchRequest = [[NSFetchRequest alloc] init];
		[accountFetchRequest setEntity:[NSEntityDescription entityForName:@"Account" inManagedObjectContext:[self managedObjectContext]]];
		[accountFetchRequest setPredicate:[NSPredicate predicateWithFormat:@"username == %@", oldUsername]];
		[accountFetchRequest setFetchLimit:1];
		NSArray *matchingAccounts = [[self managedObjectContext] executeFetchRequest:accountFetchRequest error:nil];
		if ([matchingAccounts count] > 0) {
			account = matchingAccounts[0];
		}
	}
	if (!account) {
		account = (ASAccount *)[NSEntityDescription insertNewObjectForEntityForName:@"Account" inManagedObjectContext:[self managedObjectContext]];
		if (oldUsername) account.username = oldUsername;
		if (oldPassword) account.password = oldPassword;
	}
	[self saveContext];
	[[ReportDownloadCoordinator sharedReportDownloadCoordinator] importReportsIntoAccount:account fromDirectory:legacyReportDirectory deleteAfterImport:YES];
	
    [UIViewController displayAlertWithTitle:NSLocalizedString(@"Update Notice", nil)
                                    message:NSLocalizedString(@"You have updated from an older version of AppSales. Your sales reports are currently being imported. You can start using the app while the import is running.", nil)];
	return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
	[self saveContext];
	[self showPasscodeLockIfNeededWithBiometrics:NO];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
	[[CurrencyManager sharedManager] refreshIfNeeded];
	[self showPasscodeLockIfNeededWithBiometrics:YES];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	[[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

- (void)showPasscodeLockIfNeededWithBiometrics:(BOOL)useBiometrics {
	if ([[KKPasscodeLock sharedLock] isPasscodeRequired]) {
		if (passcodeVC) {
			if (useBiometrics) {
				[passcodeVC authenticateWithBiometrics];
			}
			return;
		}
		
		if (self.accountsPopover.popoverVisible) {
			[self.accountsPopover dismissPopoverAnimated:NO];
		}
		
		passcodeVC = [[KKPasscodeViewController alloc] init];
		passcodeVC.mode = KKPasscodeModeEnter;
		passcodeVC.startBiometricAuthentication = useBiometrics;
		passcodeVC.delegate = self;
		
		UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:passcodeVC];
		nav.modalPresentationStyle = UIModalPresentationFullScreen;
		if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
			nav.navigationBar.barStyle = UIBarStyleBlack;
			nav.navigationBar.opaque = NO;
		} else {
			nav.navigationBar.tintColor = accountsViewController.navigationController.navigationBar.tintColor;
			nav.navigationBar.translucent = accountsViewController.navigationController.navigationBar.translucent;
			nav.navigationBar.opaque = accountsViewController.navigationController.navigationBar.opaque;
			nav.navigationBar.barStyle = accountsViewController.navigationController.navigationBar.barStyle;
		}
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ASWillShowPasscodeLockNotification object:self];
		
		[self.window.rootViewController.presentedViewController ?: self.window.rootViewController presentViewController:nav animated:NO completion:nil];
	}
}

- (void)didPasscodeEnteredCorrectly:(KKPasscodeViewController *)viewController {
	passcodeVC = nil;
}

- (void)applicationWillTerminate:(UIApplication *)application {
	[self saveContext];
}

- (void)promoCodeLicenseAgreementLoaded:(NSNotification *)notification {
	NSString *licenseAgreement = notification.userInfo[@"licenseAgreement"];
	PromoCodesLicenseViewController *vc = [[PromoCodesLicenseViewController alloc] initWithLicenseAgreement:licenseAgreement operation:[notification object]];
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
	[self.window.rootViewController presentViewController:navController animated:YES completion:nil];
}

#pragma mark - Core Data

- (void)saveContext {
	[self.persistentStoreCoordinator performBlockAndWait:^{
		NSError *error = nil;
		NSManagedObjectContext *moc = self.managedObjectContext;
		if ([moc hasChanges] && ![moc save:&error]) {
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			abort();
		}
	}];
}

#pragma mark - Core Data stack

- (NSManagedObjectContext *)managedObjectContext {
	if (managedObjectContext != nil) {
		return managedObjectContext;
	}
	NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
	if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
		[managedObjectContext setPersistentStoreCoordinator:coordinator];
		[managedObjectContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mergeChanges:) name:NSManagedObjectContextDidSaveNotification object:nil];
	}
	return managedObjectContext;
}

- (void)mergeChanges:(NSNotification *)notification {
	NSManagedObjectContext *moc = [notification object];
	dispatch_async(dispatch_get_main_queue(), ^{
		if (moc != self.managedObjectContext && moc.persistentStoreCoordinator == self.persistentStoreCoordinator) {
			[self.managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
		};
	});
}

- (NSManagedObjectModel *)managedObjectModel {
	if (managedObjectModel != nil) {
		return managedObjectModel;
	}
	NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"AppSales" withExtension:@"momd"];
	managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
	return managedObjectModel;
}


- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	if (persistentStoreCoordinator != nil) {
		return persistentStoreCoordinator;
	}	
	NSURL *storeURL = [[self applicationSupportDirectory] URLByAppendingPathComponent:@"AppSales.sqlite"];
	
	NSError *error = nil;
	persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
	NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption: @(YES),
							  NSInferMappingModelAutomaticallyOption: @(YES)};
	if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	}
	return persistentStoreCoordinator;
}


- (NSString *)applicationDocumentsDirectory {
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

- (NSURL *)applicationSupportDirectory {
	NSURL *appSupportDirectory = [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
	[[NSFileManager defaultManager] createDirectoryAtPath:[appSupportDirectory path] withIntermediateDirectories:YES attributes:nil error:nil];
	return appSupportDirectory;
}

- (void)promoCodeDownloadFailed:(NSNotification *)notification {
	NSString *errorDescription = notification.userInfo[kASPromoCodeDownloadFailedErrorDescription];
	NSString *alertMessage = [NSString stringWithFormat:@"An error occured while downloading the promo codes (%@).", errorDescription];
    [UIViewController displayAlertWithTitle:NSLocalizedString(@"Error", nil)
                                    message:alertMessage];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
