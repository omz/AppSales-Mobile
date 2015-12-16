//
//  AccountsViewController+VendorID.m
//  AppSales
//
//  Created by Ole Zorn on 24.08.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "AccountsViewController+VendorID.h"
#import "MBProgressHUD.h"

@implementation AccountsViewController (AccountsViewController_VendorID)

- (void)findVendorIDsWithLogin:(NSDictionary *)loginInfo {
	if (vendors == nil) {
		vendors = [[NSMutableDictionary alloc] init];
	} else {
		[vendors removeAllObjects];
	}
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
		LoginManager *loginManager = [[LoginManager alloc] initWithLoginInfo:loginInfo];
		loginManager.shouldDeleteCookies = NO;
		loginManager.delegate = self;
		[loginManager logIn];
	});
}

- (void)loginSucceeded {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
		@autoreleasepool {
			
			NSURL *paymentsPageURL = [NSURL URLWithString:[kITCBaseURL stringByAppendingString:kITCPaymentsPageAction]];
			NSData *paymentsPageData = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:paymentsPageURL] returningResponse:nil error:nil];
			
			if (paymentsPageData) {
				NSString *paymentsPage = [[NSString alloc] initWithData:paymentsPageData encoding:NSUTF8StringEncoding];
				
				NSScanner *vendorFormScanner = [NSScanner scannerWithString:paymentsPage];
				[vendorFormScanner scanUpToString:@"<form name=\"mainForm\"" intoString:nil];
				[vendorFormScanner scanString:@"<form name=\"mainForm\"" intoString:nil];
				
				// The Payments page lists the available vendors only if there is more than one.
				if ([vendorFormScanner scanUpToString:@"<div class=\"vendor-id-container\">" intoString:nil]) {
					[vendorFormScanner scanString:@"<div class=\"vendor-id-container\">" intoString:nil];
					NSString *vendorIDContainer = nil;
					[vendorFormScanner scanUpToString:@"</div>" intoString:&vendorIDContainer];
					
					if (vendorIDContainer) {
						vendorFormScanner = [NSScanner scannerWithString:vendorIDContainer];
						
						[vendorFormScanner scanUpToString:@"<option" intoString:nil];
						while ([vendorFormScanner scanString:@"<option" intoString:nil]) {
							NSString *vendorName = nil;
							NSString *vendorID = nil;
							
							// Parse vendor name.
							[vendorFormScanner scanUpToString:@">" intoString:nil];
							[vendorFormScanner scanString:@">" intoString:nil];
							[vendorFormScanner scanUpToString:@" - " intoString:&vendorName];
							
							// Parse vendor ID.
							[vendorFormScanner scanString:@"- " intoString:nil];
							[vendorFormScanner scanUpToString:@"</option>" intoString:&vendorID];
							
							vendors[vendorID] = vendorName;
							
							[vendorFormScanner scanUpToString:@"<option" intoString:nil];
						}
						
						[self performSelectorOnMainThread:@selector(finishedLoadingVendors) withObject:nil waitUntilDone:YES];
					}
				}
				
				if (vendors.count == 0) {
					// Looks like no vendors were found when parsing the Payments page.
					// This means there's either one vendor or the page structure has changed.
					// Let's try asking the reports API instead.
					NSURL *reportsPageURL = [NSURL URLWithString:kITCReportsAPIURL];
					NSData *reportsPageData = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:reportsPageURL] returningResponse:nil error:nil];
					
					if (reportsPageData) {
						NSDictionary *reportsPage = [NSJSONSerialization JSONObjectWithData:reportsPageData options:0 error:nil];
						
						NSArray *reports = reportsPage[@"reports"];
						if (reports.count > 0) {
							NSArray *reportsVendors = reports[0][@"vendors"];
							for (NSDictionary *vendor in reportsVendors) {
								NSString *vendorID = vendor[@"id"];
								NSString *vendorName = vendor[@"name"];
								vendorName = [vendorName substringToIndex:(vendorName.length - vendorID.length - 3)];
								vendors[vendorID] = vendorName;
							}
							[self performSelectorOnMainThread:@selector(finishedLoadingVendors) withObject:nil waitUntilDone:YES];
						} else {
							[self performSelectorOnMainThread:@selector(failedToLoadVendorIDs) withObject:nil waitUntilDone:YES];
						}
					} else {
						[self performSelectorOnMainThread:@selector(failedToLoadVendorIDs) withObject:nil waitUntilDone:YES];
					}
				}
				
				LoginManager *loginManager = [[LoginManager alloc] initWithLoginInfo:nil];
				loginManager.shouldDeleteCookies = NO;
				[loginManager logOut];
			} else {
				[self performSelectorOnMainThread:@selector(failedToLoadVendorIDs) withObject:nil waitUntilDone:YES];
			}
		}
	});
}

- (void)loginFailed {
	// User canceled the login, so we're unable to fetch the vendor ID.
	[MBProgressHUD hideHUDForView:self.currentViewController.navigationController.view animated:YES];
}

- (void)finishedLoadingVendors {
	switch (vendors.count) {
		case 0: {
			[self failedToLoadVendorIDs];
			break;
		}
		case 1: {
			[self finishedLoadingVendorID:vendors.allKeys.firstObject];
			break;
		}
		default: {
			[self chooseVendor];
			break;
		}
	}
}

- (void)chooseVendor {
	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Select Your Primary Vendor", nil)
																			 message:nil
																	  preferredStyle:UIAlertControllerStyleActionSheet];
	
	for (NSString *vendorID in vendors) {
		NSString *vendorName = vendors[vendorID];
		NSString *buttonTitle = [NSString stringWithFormat:@"%@ (%@)", vendorName, vendorID];
		[alertController addAction:[UIAlertAction actionWithTitle:buttonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
			[self finishedLoadingVendorID:vendorID];
		}]];
	}
	
	[alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
		[MBProgressHUD hideHUDForView:self.currentViewController.navigationController.view animated:YES];
	}]];
	
	[self.currentViewController presentViewController:alertController animated:YES completion:nil];
}

- (void)finishedLoadingVendorID:(NSString *)vendorID {
	FieldEditorViewController *vc = self.currentViewController;
	[MBProgressHUD hideHUDForView:vc.navigationController.view animated:YES];
	[vc.values setObject:vendorID forKey:kAccountVendorID];
	[vc.tableView reloadData];
}

- (void)failedToLoadVendorIDs {
	[MBProgressHUD hideHUDForView:self.currentViewController.navigationController.view animated:YES];
	[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"The vendor ID could not be filled automatically. Please check your username and password or enter your vendor ID manually. You'll find it at the top of the Sales and Trends module on itunesconnect.apple.com.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
}

- (FieldEditorViewController *)currentViewController {
	FieldEditorViewController *vc = nil;
	if (self.presentedViewController) {
		// Adding new account.
		vc = ((UINavigationController *)self.presentedViewController).viewControllers[0];
	} else {
		// Editing existing account.
		vc = self.navigationController.viewControllers.lastObject;
	}
	return vc;
}

@end
