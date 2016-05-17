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
			
			NSURL *userDetailURL = [NSURL URLWithString:[kITCBaseURL stringByAppendingString:kITCUserDetailAction]];
			NSData *userDetailData = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:userDetailURL] returningResponse:nil error:nil];
			NSDictionary *userDetail = [NSJSONSerialization JSONObjectWithData:userDetailData options:0 error:nil];
			NSString *contentProviderId = userDetail[@"data"][@"contentProviderId"];
			
			if (contentProviderId.length > 0) {
				NSURL *paymentVendorsURL = [NSURL URLWithString:[kITCBaseURL stringByAppendingFormat:kITCPaymentVendorsAction, contentProviderId]];
				NSData *paymentVendorsData = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:paymentVendorsURL] returningResponse:nil error:nil];
				NSDictionary *paymentVendors = [NSJSONSerialization JSONObjectWithData:paymentVendorsData options:0 error:nil];
				NSArray *sapVendors = paymentVendors[@"data"];
				
				if (sapVendors.count > 0) {
					for (NSDictionary *vendor in sapVendors) {
						NSNumber *vendorID = vendor[@"sapVendorNumber"];
						NSString *vendorName = vendor[@"vendorName"];
						vendors[vendorID.description] = vendorName;
					}
					[self performSelectorOnMainThread:@selector(finishedLoadingVendors) withObject:nil waitUntilDone:YES];
				} else {
					[self performSelectorOnMainThread:@selector(failedToLoadVendorIDs) withObject:nil waitUntilDone:YES];
				}
			} else {
				[self performSelectorOnMainThread:@selector(failedToLoadVendorIDs) withObject:nil waitUntilDone:YES];
			}
			
			LoginManager *loginManager = [[LoginManager alloc] initWithLoginInfo:nil];
			loginManager.shouldDeleteCookies = NO;
			[loginManager logOut];
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
