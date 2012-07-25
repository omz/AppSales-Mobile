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
	[[KKPasscodeLock sharedLock] setDefaultSettings];
	[[KKPasscodeLock sharedLock] setEraseOption:NO];
	
	srandom(time(NULL));
	self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
	
	NSString *currencyCode = [[NSLocale currentLocale] objectForKey:NSLocaleCurrencyCode];
	if (![[CurrencyManager sharedManager].availableCurrencies containsObject:currencyCode]) {
		currencyCode = @"USD";
	}
	
	NSDictionary *defaults = [NSDictionary dictionaryWithObjectsAndKeys:
							  [NSNumber numberWithBool:YES], kSettingDownloadPayments,
							  currencyCode, @"CurrencyManagerBaseCurrency",
							  nil];
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(promoCodeLicenseAgreementLoaded:) name:@"PromoCodeOperationLoadedLicenseAgreementNotification" object:nil];
	
	BOOL iPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
	if (!iPad) {
		AccountsViewController *rootViewController = [[[AccountsViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
		rootViewController.managedObjectContext = self.managedObjectContext;
		UINavigationController *navigationController = [[[UINavigationController alloc] initWithRootViewController:rootViewController] autorelease];
		navigationController.toolbarHidden = NO;
		self.accountsViewController = rootViewController;
		
		self.window.rootViewController = navigationController;
		[self.window makeKeyAndVisible];
	} else {
		self.accountsViewController = [[[AccountsViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
		self.accountsViewController.managedObjectContext = self.managedObjectContext;
		self.accountsViewController.contentSizeForViewInPopover = CGSizeMake(320, 480);
		self.accountsViewController.delegate = self;
		UINavigationController *accountsNavController = [[[UINavigationController alloc] initWithRootViewController:self.accountsViewController] autorelease];
		accountsNavController.toolbarHidden = NO;
		self.accountsPopover = [[[UIPopoverController alloc] initWithContentViewController:accountsNavController] autorelease];	
		[self loadAccount:nil];
		[self.window makeKeyAndVisible];
	}
	
	BOOL migrating = [self migrateDataIfNeeded];
	if (migrating) {
		[self.accountsViewController reloadAccounts];
	}
	
	[[CurrencyManager sharedManager] refreshIfNeeded];
	
	NSString* productSortByValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"ProductSortby"];
	if (productSortByValue==nil) {
		[[NSUserDefaults standardUserDefaults] setObject:@"productId" forKey:@"ProductSortby"];
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reportDownloadFailed:) name:ASReportDownloadFailedNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(promoCodeDownloadFailed:) name:ASPromoCodeDownloadFailedNotification object:nil];
	
	if ([launchOptions objectForKey:UIApplicationLaunchOptionsURLKey]) {
		[self.accountsViewController performSelector:@selector(downloadReports:) withObject:nil afterDelay:0.0];
	}
	
	[self showPasscodeLockIfNeeded];
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
		NSFetchRequest *accountsFetchRequest = [[[NSFetchRequest alloc] init] autorelease];
		[accountsFetchRequest setEntity:[NSEntityDescription entityForName:@"Account" inManagedObjectContext:self.managedObjectContext]];
		[accountsFetchRequest setSortDescriptors:[NSArray arrayWithObjects:[[[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES] autorelease], [[[NSSortDescriptor alloc] initWithKey:@"username" ascending:YES] autorelease], nil]];
		NSArray *accounts = [self.managedObjectContext executeFetchRequest:accountsFetchRequest error:NULL];
		ASAccount *account = [accounts objectAtIndex:buttonIndex];
		[self loadAccount:account];
	}
}

- (void)loadAccount:(ASAccount *)account
{
	UIBarButtonItem *selectAccountButtonItem1 = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Account", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(selectAccount:)] autorelease];
	UIBarButtonItem *selectAccountButtonItem2 = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Account", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(selectAccount:)] autorelease];
	UIBarButtonItem *selectAccountButtonItem3 = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Account", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(selectAccount:)] autorelease];
	UIBarButtonItem *selectAccountButtonItem4 = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Account", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(selectAccount:)] autorelease];
	
	SalesViewController *salesVC = [[[SalesViewController alloc] initWithAccount:account] autorelease];
	salesVC.navigationItem.leftBarButtonItem = selectAccountButtonItem1;
	UINavigationController *salesNavController = [[[UINavigationController alloc] initWithRootViewController:salesVC] autorelease];
	
	ReviewsViewController *reviewsVC = [[[ReviewsViewController alloc] initWithAccount:account] autorelease];
	reviewsVC.navigationItem.leftBarButtonItem = selectAccountButtonItem2;
	UINavigationController *reviewsNavController = [[[UINavigationController alloc] initWithRootViewController:reviewsVC] autorelease];
	
	PaymentsViewController *paymentsVC = [[[PaymentsViewController alloc] initWithAccount:account] autorelease];
	paymentsVC.navigationItem.leftBarButtonItem = selectAccountButtonItem3;
	UINavigationController *paymentsNavController = [[[UINavigationController alloc] initWithRootViewController:paymentsVC] autorelease];
	
	PromoCodesViewController *promoVC = [[[PromoCodesViewController alloc] initWithAccount:account] autorelease];
	promoVC.navigationItem.leftBarButtonItem = selectAccountButtonItem4;
	UINavigationController *promoNavController = [[[UINavigationController alloc] initWithRootViewController:promoVC] autorelease];
	promoNavController.toolbarHidden = NO;
	promoNavController.toolbar.barStyle = UIBarStyleBlackOpaque;
	
	UITabBarController *tabController = [[[UITabBarController alloc] initWithNibName:nil bundle:nil] autorelease];
	[tabController setViewControllers:[NSArray arrayWithObjects:salesNavController, reviewsNavController, paymentsNavController, promoNavController, nil]];
	
	self.window.rootViewController = tabController;
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
	[self.accountsViewController performSelector:@selector(downloadReports:) withObject:nil afterDelay:0.0];
	return YES;
}

- (BOOL)migrateDataIfNeeded
{
	NSString *documentsDirectory = [self applicationDocumentsDirectory];
	NSString *legacyReportDirectory = [documentsDirectory stringByAppendingPathComponent:@"OriginalReports"];
	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL originalReportsDirectoryFound = [fm fileExistsAtPath:legacyReportDirectory];
	if (!originalReportsDirectoryFound) {
		return NO;
	}	
	NSArray *originalReportFiles = [fm contentsOfDirectoryAtPath:legacyReportDirectory error:NULL];
	if ([originalReportFiles count] == 0) {
		//All files have been migrated, delete all the clutter in the documents directory:
		NSArray *files = [fm contentsOfDirectoryAtPath:documentsDirectory error:NULL];
		for (NSString *file in files) {
			NSString *fullPath = [documentsDirectory stringByAppendingPathComponent:file];
			[fm removeItemAtPath:fullPath error:NULL];
		}
		return NO;
	}
	NSString *oldUsername = [[NSUserDefaults standardUserDefaults] stringForKey:@"iTunesConnectUsername"];
	NSString *oldPassword = nil;
	if (oldUsername) {
		oldPassword = [SSKeychain passwordForService:@"omz:software AppSales Mobile Service" account:oldUsername];
	}
	ASAccount *account = nil;
	if (oldUsername) {
		NSFetchRequest *accountFetchRequest = [[[NSFetchRequest alloc] init] autorelease];
		[accountFetchRequest setEntity:[NSEntityDescription entityForName:@"Account" inManagedObjectContext:[self managedObjectContext]]];
		[accountFetchRequest setPredicate:[NSPredicate predicateWithFormat:@"username == %@", oldUsername]];
		[accountFetchRequest setFetchLimit:1];
		NSArray *matchingAccounts = [[self managedObjectContext] executeFetchRequest:accountFetchRequest error:NULL];
		if ([matchingAccounts count] > 0) {
			account = [matchingAccounts objectAtIndex:0];
		}
	}
	if (!account) {
		account = (ASAccount *)[NSEntityDescription insertNewObjectForEntityForName:@"Account" inManagedObjectContext:[self managedObjectContext]];
		if (oldUsername) account.username = oldUsername;
		if (oldPassword) account.password = oldPassword;
	}
	[self saveContext];
	[[ReportDownloadCoordinator sharedReportDownloadCoordinator] importReportsIntoAccount:account fromDirectory:legacyReportDirectory deleteAfterImport:YES];
	
	[[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Update Notice", nil) 
								 message:NSLocalizedString(@"You have updated from an older version of AppSales. Your sales reports are currently being imported. You can start using the app while the import is running.", nil)
								delegate:nil 
					   cancelButtonTitle:NSLocalizedString(@"OK", nil) 
					   otherButtonTitles:nil] autorelease] show];
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
		
		KKPasscodeViewController *vc = [[[KKPasscodeViewController alloc] initWithNibName:nil bundle:nil] autorelease];
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
				&& [[[(UINavigationController *)self.window.rootViewController.modalViewController viewControllers] objectAtIndex:0] isKindOfClass:[KKPasscodeViewController class]]) {
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
	NSString *licenseAgreement = [[notification userInfo] objectForKey:@"licenseAgreement"];
	PromoCodesLicenseViewController *vc = [[[PromoCodesLicenseViewController alloc] initWithLicenseAgreement:licenseAgreement operation:[notification object]] autorelease];
	UINavigationController *navController = [[[UINavigationController alloc] initWithRootViewController:vc] autorelease];
	[self.window.rootViewController presentModalViewController:navController animated:YES];
}

#pragma mark - Core Data

- (void)saveContext
{
	[self.persistentStoreCoordinator lock];
	NSError *error = nil;
	NSManagedObjectContext *moc = self.managedObjectContext;
	if ([moc hasChanges] && ![moc save:&error]) {
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	}
	[self.persistentStoreCoordinator unlock];
}

#pragma mark - Core Data stack

- (NSManagedObjectContext *)managedObjectContext
{
	if (managedObjectContext != nil) {
		return managedObjectContext;
	}
	NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
	if (coordinator != nil) {
		managedObjectContext = [[NSManagedObjectContext alloc] init];
		[managedObjectContext setPersistentStoreCoordinator:coordinator];
		[managedObjectContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mergeChanges:) name:NSManagedObjectContextDidSaveNotification object:nil];
	}
	return managedObjectContext;
}

- (void)mergeChanges:(NSNotification *)notification
{
	NSManagedObjectContext *moc = [notification object];
	dispatch_async(dispatch_get_main_queue(), ^ {
		if (moc != self.managedObjectContext && moc.persistentStoreCoordinator == self.persistentStoreCoordinator) {
			[self.managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
		};
	});
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (managedObjectModel != nil)
    {
		return managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"AppSales" withExtension:@"momd"];
	managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
	return managedObjectModel;
}


- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }	
	NSURL *storeURL = [[self applicationSupportDirectory] URLByAppendingPathComponent:@"AppSales.sqlite"];
    
	NSError *error = nil;
	persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
							 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, 
							 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
	if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	}
	return persistentStoreCoordinator;
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
	NSString *errorMessage = [[notification userInfo] objectForKey:kASReportDownloadErrorDescription];
	NSString *alertMessage = [NSString stringWithFormat:NSLocalizedString(@"Downloading reports from iTunes Connect failed. Please try again later or check the iTunes Connect website for anything unusual. %@", nil), (errorMessage) ? errorMessage : @""];
	[[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) 
								 message:alertMessage 
								delegate:nil 
					   cancelButtonTitle:NSLocalizedString(@"OK", nil) 
					   otherButtonTitles:nil] autorelease] show];
}

- (void)promoCodeDownloadFailed:(NSNotification *)notification
{
	NSString *errorDescription = [[notification userInfo] objectForKey:kASPromoCodeDownloadFailedErrorDescription];
	NSString *alertMessage = [NSString stringWithFormat:@"An error occured while downloading the promo codes (%@).", errorDescription];
	[[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) 
								 message:alertMessage 
								delegate:nil 
					   cancelButtonTitle:NSLocalizedString(@"OK", nil) 
					   otherButtonTitles:nil] autorelease] show];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[accountsPopover release];
	[window release];
	[managedObjectContext release];
	[managedObjectModel release];
	[persistentStoreCoordinator release];
	[super dealloc];
}


@end
