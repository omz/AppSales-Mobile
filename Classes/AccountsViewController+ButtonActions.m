//
//  AccountsViewController+ButtonActions.m
//  AppSales
//
//  Created by Nicolas Gomollon on 8/9/17.
//
//

#import "AccountsViewController+ButtonActions.h"
#import "ASProgressHUD.h"
#import "UIViewController+Alert.h"

@implementation AccountsViewController (AccountsViewController_ButtonActions)

typedef NS_ENUM(NSInteger, AccessTokenAction) {
	AccessTokenActionGet,
	AccessTokenActionGenerate
};

- (void)autoFillWizardWithLogin:(NSDictionary *)loginInfo {
	pressedAccountButton = AccountButtonTypeAutoFillWizard;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
		LoginManager *loginManager = [[LoginManager alloc] initWithLoginInfo:loginInfo];
		loginManager.shouldDeleteCookies = NO;
		loginManager.delegate = self;
		[loginManager logIn];
	});
}

- (void)findProviderIDWithLogin:(NSDictionary *)loginInfo {
	pressedAccountButton = AccountButtonTypeSelectProviderID;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
		LoginManager *loginManager = [[LoginManager alloc] initWithLoginInfo:loginInfo];
		loginManager.shouldDeleteCookies = NO;
		loginManager.delegate = self;
		[loginManager logIn];
	});
}

- (void)getAccessTokenWithLogin:(NSDictionary *)loginInfo {
	pressedAccountButton = AccountButtonTypeGetAccessToken;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
		LoginManager *loginManager = [[LoginManager alloc] initWithLoginInfo:loginInfo];
		loginManager.shouldDeleteCookies = NO;
		loginManager.delegate = self;
		[loginManager logIn];
	});
}

- (void)findVendorIDsWithLogin:(NSDictionary *)loginInfo {
	pressedAccountButton = AccountButtonTypeSelectVendorID;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
		LoginManager *loginManager = [[LoginManager alloc] initWithLoginInfo:loginInfo];
		loginManager.shouldDeleteCookies = NO;
		loginManager.delegate = self;
		[loginManager logIn];
	});
}

- (void)loginSucceeded:(LoginManager *)loginManager {
	[self storeValue:loginManager.providerID forKey:kAccountProviderID];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
		@autoreleasepool {
            switch (self->pressedAccountButton) {
				case AccountButtonTypeAutoFillWizard:
				case AccountButtonTypeGetAccessToken: {
                    [loginManager generateCSRFTokenWithCompletionBlock:^(NSString *csrfToken) {
                        if (csrfToken != nil) {
                            [self chooseAccessToken:loginManager csrfToken:csrfToken action:AccessTokenActionGet successHandler:^(NSString *accessToken) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [self storeValue:accessToken forKey:kAccountAccessToken];
                                    if (self->pressedAccountButton == AccountButtonTypeAutoFillWizard) {
                                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
                                            @autoreleasepool {
                                                [self chooseVendor:loginManager.providerID];
                                            }
                                        });
                                    } else {
                                        [ASProgressHUD hideHUDForView:self.currentViewController.navigationController.view animated:YES];
                                    }
                                });
                            }];
                        } else {
                            [self performSelectorOnMainThread:@selector(failedToGenerateCSRFToken) withObject:nil waitUntilDone:YES];
                        }
                    }];
					break;
				}
				case AccountButtonTypeSelectProviderID: {
					dispatch_async(dispatch_get_main_queue(), ^{
						[ASProgressHUD hideHUDForView:self.currentViewController.navigationController.view animated:YES];
					});
					break;
				}
				case AccountButtonTypeSelectVendorID: {
					[self chooseVendor:loginManager.providerID];
					break;
				}
			}
		}
	});
}

- (void)loginFailed:(LoginManager *)loginManager {
	[ASProgressHUD hideHUDForView:self.currentViewController.navigationController.view animated:YES];
}

- (void)storeValue:(NSString *)value forKey:(NSString *)key {
	FieldEditorViewController *vc = self.currentViewController;
	[vc.values setObject:value forKey:key];
	[vc.tableView reloadData];
}

- (void)failedToGenerateCSRFToken {
	[ASProgressHUD hideHUDForView:self.currentViewController.navigationController.view animated:YES];
    [[UIViewController topViewController] displayAlertWithTitle:NSLocalizedString(@"Error", nil)
                                                        message:NSLocalizedString(@"Could not fetch CSRF token from server. Please try again later.", nil)];
}

- (void)chooseAccessToken:(LoginManager *)loginManager csrfToken:(NSString *)csrfToken action:(AccessTokenAction)action successHandler:(void (^)(NSString *accessToken))successHandler {
	NSDictionary *resultDict = nil;
	switch (action) {
		case AccessTokenActionGet:
			resultDict = [loginManager getAccessKey:csrfToken];
			break;
		case AccessTokenActionGenerate:
			resultDict = [loginManager resetAccessKey:csrfToken];
			break;
	}
	if (resultDict != nil) {
		// TODO: Save `expiryDate` and `createdDate` for the fetched access token, so as to let the user know when the token will expire.
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		dateFormatter.locale = [NSLocale currentLocale];
		dateFormatter.dateStyle = NSDateFormatterMediumStyle;
		dateFormatter.timeStyle = NSDateFormatterNoStyle;
		NSString *accessToken = resultDict[@"accessKey"];
		NSString *createdDate = [dateFormatter stringFromDate:resultDict[@"createdDate"]];
		NSString *expiryDate = [dateFormatter stringFromDate:resultDict[@"expiryDate"]];
		dispatch_async(dispatch_get_main_queue(), ^{
			UIAlertController *alertController = nil;
			void (^generateAccessTokenBlock)(UIAlertAction *action) = ^(UIAlertAction *action) {
				dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
					@autoreleasepool {
						[self chooseAccessToken:loginManager csrfToken:csrfToken action:AccessTokenActionGenerate successHandler:successHandler];
					}
				});
			};
			if ((accessToken != nil) && ![accessToken isEqual:[NSNull null]] && (accessToken.length > 0)) {
				NSString *message = [NSString stringWithFormat:NSLocalizedString(@"%@\n\nGenerated: %@\nExpires: %@", ""), accessToken, createdDate, expiryDate];
				alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Access Token", nil)
																	  message:message
															   preferredStyle:UIAlertControllerStyleActionSheet];
				
				[alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Continue", "") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
					dispatch_async(dispatch_get_main_queue(), ^{
						successHandler(accessToken);
					});
				}]];
				
				[alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Regenerate…", "") style:UIAlertActionStyleDestructive handler:generateAccessTokenBlock]];
			} else {
				alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Access Token", nil)
																	  message:nil
															   preferredStyle:UIAlertControllerStyleActionSheet];
				
				[alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Generate…", "") style:UIAlertActionStyleDefault handler:generateAccessTokenBlock]];
			}
			
			[alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
				dispatch_async(dispatch_get_main_queue(), ^{
					[ASProgressHUD hideHUDForView:self.currentViewController.navigationController.view animated:YES];
				});
			}]];
			
			[self.currentViewController presentViewController:alertController animated:YES completion:nil];
		});
	} else {
		[self performSelectorOnMainThread:@selector(failedToFetchAccessToken) withObject:nil waitUntilDone:YES];
	}
}

- (void)failedToFetchAccessToken {
    [ASProgressHUD hideHUDForView:self.currentViewController.navigationController.view animated:YES];
    [[UIViewController topViewController] displayAlertWithTitle:NSLocalizedString(@"Error", nil)
                                                        message:NSLocalizedString(@"The access token could not be fetched automatically. Please check your username and password or enter your access token manually. You'll find it in the Sales and Trends module, under the Reports section, by clicking on the (?) beside About Reports on itunesconnect.apple.com.", nil)];
}

- (void)chooseVendor:(NSString *)providerID {
	if (vendors == nil) {
		vendors = [[NSMutableDictionary alloc] init];
	} else {
		[vendors removeAllObjects];
	}
	NSURL *paymentVendorsURL = [NSURL URLWithString:[kITCBaseURL stringByAppendingFormat:kITCPaymentVendorsAction, providerID]];
    [[NSURLSession.sharedSession dataTaskWithRequest:[NSURLRequest requestWithURL:paymentVendorsURL]
                                   completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        NSDictionary *paymentVendors = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSArray *sapVendors = paymentVendors[@"data"];
        if ((sapVendors != nil) && ![sapVendors isEqual:[NSNull null]] && (sapVendors.count > 0)) {
            for (NSDictionary *vendor in sapVendors) {
                NSNumber *vendorID = vendor[@"sapVendorNumber"];
                NSString *vendorName = vendor[@"vendorName"];
                self->vendors[vendorID.description] = vendorName;
            }
            [self performSelectorOnMainThread:@selector(finishedLoadingVendors) withObject:nil waitUntilDone:YES];
        } else {
            [self performSelectorOnMainThread:@selector(failedToLoadVendorIDs) withObject:nil waitUntilDone:YES];
        }
    }] resume];
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
				[ASProgressHUD hideHUDForView:self.currentViewController.navigationController.view animated:YES];
			}]];
			
			[self.currentViewController presentViewController:alertController animated:YES completion:nil];
			break;
		}
	}
}

- (void)finishedLoadingVendorID:(NSString *)vendorID {
	[self storeValue:vendorID forKey:kAccountVendorID];
	[ASProgressHUD hideHUDForView:self.currentViewController.navigationController.view animated:YES];
}

- (void)failedToLoadVendorIDs {
    [ASProgressHUD hideHUDForView:self.currentViewController.navigationController.view animated:YES];
    [[UIViewController topViewController] displayAlertWithTitle:NSLocalizedString(@"Error", nil)
                                                        message:NSLocalizedString(@"The vendor ID could not be filled automatically. Please check your username and password or enter your vendor ID manually. You'll find it at the top of the Sales and Trends module on itunesconnect.apple.com.", nil)];
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
