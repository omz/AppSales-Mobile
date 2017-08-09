//
//  AccountsViewController+ButtonActions.m
//  AppSales
//
//  Created by Nicolas Gomollon on 8/9/17.
//
//

#import "AccountsViewController+ButtonActions.h"
#import "MBProgressHUD.h"

@implementation AccountsViewController (AccountsViewController_ButtonActions)

- (void)getAccessTokenWithLogin:(NSDictionary *)loginInfo {
	pressedAccountButton = AccountButtonTypeGetAccessToken;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
		LoginManager *loginManager = [[LoginManager alloc] initWithLoginInfo:loginInfo];
		loginManager.shouldDeleteCookies = NO;
		loginManager.delegate = self;
		[loginManager logIn];
	});
}

- (void)generateAccessTokenWithLogin:(NSDictionary *)loginInfo {
	pressedAccountButton = AccountButtonTypeGenerateAccessToken;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
		LoginManager *loginManager = [[LoginManager alloc] initWithLoginInfo:loginInfo];
		loginManager.shouldDeleteCookies = NO;
		loginManager.delegate = self;
		[loginManager logIn];
	});
}

- (void)findVendorIDsWithLogin:(NSDictionary *)loginInfo {
	if (vendors == nil) {
		vendors = [[NSMutableDictionary alloc] init];
	} else {
		[vendors removeAllObjects];
	}
	
	pressedAccountButton = AccountButtonTypeSelectVendorID;
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
			switch (pressedAccountButton) {
				case AccountButtonTypeGetAccessToken:
				case AccountButtonTypeGenerateAccessToken: {
					LoginManager *loginManager = [[LoginManager alloc] initWithLoginInfo:nil];
					NSString *csrfToken = [loginManager generateCSRFToken];
					if (csrfToken != nil) {
						NSDictionary *resultDict = nil;
						if (pressedAccountButton == AccountButtonTypeGenerateAccessToken) {
							resultDict = [loginManager resetAccessKey:csrfToken];
						} else {
							resultDict = [loginManager getAccessKey:csrfToken];
						}
						if (resultDict != nil) {
							// TODO: Save `expiryDate` and `createdDate` for the fetched access token, so as to let the user know when the token will expire.
							NSString *accessToken = resultDict[@"accessKey"];
							dispatch_async(dispatch_get_main_queue(), ^{
								[self finishedFetchingAccessToken:accessToken];
							});
						} else {
							[self performSelectorOnMainThread:@selector(failedToFetchAccessToken) withObject:nil waitUntilDone:YES];
						}
					} else {
						[self performSelectorOnMainThread:@selector(failedToGenerateCSRFToken) withObject:nil waitUntilDone:YES];
					}
					break;
				}
				case AccountButtonTypeSelectVendorID: {
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
					break;
				}
			}
		}
	});
}

- (void)loginFailed {
	[MBProgressHUD hideHUDForView:self.currentViewController.navigationController.view animated:YES];
}

- (void)finishedFetchingAccessToken:(NSString *)accessToken {
	FieldEditorViewController *vc = self.currentViewController;
	[MBProgressHUD hideHUDForView:vc.navigationController.view animated:YES];
	[vc.values setObject:accessToken forKey:kAccountAccessToken];
	[vc.tableView reloadData];
}

- (void)failedToFetchAccessToken {
	[MBProgressHUD hideHUDForView:self.currentViewController.navigationController.view animated:YES];
	[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"The access token could not be fetched automatically. Please check your username and password or enter your access token manually. You'll find it in the Sales and Trends module, under the Reports section, by clicking on the (?) beside About Reports on itunesconnect.apple.com.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
}

- (void)failedToGenerateCSRFToken {
	[MBProgressHUD hideHUDForView:self.currentViewController.navigationController.view animated:YES];
	[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Could not fetch CSRF token from server. Please try again later.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
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
