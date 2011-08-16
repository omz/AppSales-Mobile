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

@implementation AppSalesAppDelegate

@synthesize window = _window;

@synthesize navigationController = _navigationController;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	srandom(time(NULL));

	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self setWindow:_window];
    PTPasscodeViewController *passcodeViewController = [[PTPasscodeViewController alloc] initWithDelegate:self];
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults]; 
    NSString *passcodeset = @"NO";
    NSDictionary *appDefaults = [[NSDictionary alloc] initWithObjectsAndKeys:passcodeset, @"passcodeset",nil];
                                 
    [prefs  registerDefaults:appDefaults]; 
    [appDefaults release];
    NSString *passcoderet = [prefs stringForKey:@"passcodeset"];
    NSLog(@" PASSCODE SET IS? %@",passcoderet);
    UINavigationController *navController = [[UINavigationController alloc]
        initWithRootViewController:passcodeViewController];
    
  //  [self setNavigationController:navController];
	self.window.rootViewController = navController;
  //  [_window addSubview:[navController view]];
    //[_window makeKeyAndVisible];
    
   // [window release];
    //[navController release];
    


	AccountsViewController *rootViewController = [[[AccountsViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
	rootViewController.managedObjectContext = self.managedObjectContext;
	UINavigationController *navigationController = [[[UINavigationController alloc] initWithRootViewController:rootViewController] autorelease];
	navigationController.toolbarHidden = NO;
	
	[self.window makeKeyAndVisible];
    
    
	
	BOOL migrating = [self migrateDataIfNeeded];
	if (migrating) {
		[rootViewController reloadAccounts];
	}
	
	[[CurrencyManager sharedManager] refreshIfNeeded];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reportDownloadFailed:) name:ASReportDownloadFailedNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(promoCodeDownloadFailed:) name:ASPromoCodeDownloadFailedNotification object:nil];
		
	return YES;
}

- (void)didShowPasscodePanel:(PTPasscodeViewController *)passcodeViewController panelView:(UIView*)panelView
{
    [passcodeViewController setTitle:@"AppSales"];
    
    if([panelView tag] == kPasscodePanelOne) {
        [[passcodeViewController titleLabel] setText:@"Enter a passcode"];
    }
    
    if([panelView tag] == kPasscodePanelTwo) {
        [[passcodeViewController titleLabel] setText:@"Re-enter your passcode"];
    }
    
    if([panelView tag] == kPasscodePanelThree) {
        [[passcodeViewController titleLabel] setText:@"Panel 3"];
    }
}

- (BOOL)shouldChangePasscode:(PTPasscodeViewController *)passcodeViewController panelView:(UIView*)panelView passCode:(NSUInteger)passCode lastNumber:(NSInteger)lastNumber;
{
    // Clear summary text
    [[passcodeViewController summaryLabel] setText:@""];
    
    return TRUE;
}

- (BOOL)didEndPasscodeEditing:(PTPasscodeViewController *)passcodeViewController panelView:(UIView*)panelView passCode:(NSUInteger)passCode
{
    
    
    NSLog(@"END PASSCODE - %d", passCode);
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    // getting an NSString
    NSString *passcoderet = [prefs stringForKey:@"passcodeset"];
    
   // NSLog(@"Do we think the passcode has been set:%@",passcoderet);
    
    if ([passcoderet isEqualToString:@"NO"]) {   
        if([panelView tag] == kPasscodePanelOne) {
            _passCode = passCode;
            
            return ![passcodeViewController nextPanel];
        }
        
        if([panelView tag] == kPasscodePanelTwo) {
            _retryPassCode = passCode;
            
            if(_retryPassCode != _passCode) {
                [passcodeViewController prevPanel];
                [[passcodeViewController summaryLabel] setText:@"Passcode did not match. Try again."];
                return FALSE;
            } else {
                NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
                [prefs setInteger:passCode forKey:@"passcode"];
                NSString *passcodeset = @"YES";
                NSLog(@"SETTINGPASSCODESET TO BE YES");
                [prefs setObject:passcodeset forKey:@"passcodeset"];
                [prefs synchronize];

                
                AccountsViewController *rootViewController = [[[AccountsViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
                rootViewController.managedObjectContext = self.managedObjectContext;
                UINavigationController *navigationController = [[[UINavigationController alloc] initWithRootViewController:rootViewController] autorelease];
                navigationController.toolbarHidden = NO;
                self.window.rootViewController = navigationController;
                
            }
            
        }

        
    }

    else {


    if([panelView tag] == kPasscodePanelOne) {
        _passCode = passCode;
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSInteger passtocheck = [prefs integerForKey:@"passcode"];
      //  NSLog(@"Passtocheck = %@",passtocheck);
        if (passCode == passtocheck) {
            NSLog(@"IT WORKS");
            AccountsViewController *rootViewController = [[[AccountsViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
            rootViewController.managedObjectContext = self.managedObjectContext;
            UINavigationController *navigationController = [[[UINavigationController alloc] initWithRootViewController:rootViewController] autorelease];
            navigationController.toolbarHidden = NO;
            self.window.rootViewController = navigationController;
 
        }
        else{

            NSLog(@"YOU FAILED");
                
     [[passcodeViewController summaryLabel] setText:@"Passcode Incorrect."];                    
                
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Security" message:@"This app is meant for the use of the owner only. Press the home button to exit this application"  delegate:self cancelButtonTitle:@"Take Picture" otherButtonTitles: @"Cancel", nil];
            [alert show];
            [alert release];
            


}
    }
    }    
    return TRUE;
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

- (void)applicationWillTerminate:(UIApplication *)application
{
	[self saveContext];
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
	[window release];
	[managedObjectContext release];
	[managedObjectModel release];
	[persistentStoreCoordinator release];
    [_navigationController release];

    [super dealloc];
}


@end
