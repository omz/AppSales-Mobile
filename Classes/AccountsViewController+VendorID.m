//
//  AccountsViewController+VendorID.m
//  AppSales
//
//  Created by Ole Zorn on 24.08.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "AccountsViewController+VendorID.h"
#import "NSDictionary+HTTP.h"
#import "MBProgressHUD.h"

@implementation AccountsViewController (AccountsViewController_VendorID)

- (void)findVendorIDsWithLogin:(NSDictionary *)loginInfo {
	if (vendors == nil) {
		vendors = [[NSMutableDictionary alloc] init];
	} else {
		[vendors removeAllObjects];
	}
	
	LoginManager *loginManager = [[LoginManager alloc] initWithLoginInfo:loginInfo];
	loginManager.shouldDeleteCookies = NO;
	loginManager.delegate = self;
	[loginManager logIn];
}

- (void)loginSucceeded {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
		@autoreleasepool {
			
			NSURL *paymentsPageURL = [NSURL URLWithString:[kITCBaseURL stringByAppendingString:kITCPaymentsPageAction]];
			NSData *paymentsPageData = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:paymentsPageURL] returningResponse:NULL error:NULL];
			
			if (paymentsPageData) {
				NSString *paymentsPage = [[NSString alloc] initWithData:paymentsPageData encoding:NSUTF8StringEncoding];
				
				NSScanner *vendorFormScanner = [NSScanner scannerWithString:paymentsPage];
				[vendorFormScanner scanUpToString:@"<form name=\"mainForm\"" intoString:NULL];
				[vendorFormScanner scanString:@"<form name=\"mainForm\"" intoString:NULL];
				
				if ([vendorFormScanner scanUpToString:@"<div class=\"vendor-id-container\">" intoString:NULL]) {
					[vendorFormScanner scanString:@"<div class=\"vendor-id-container\">" intoString:NULL];
					NSString *vendorIDContainer = nil;
					[vendorFormScanner scanUpToString:@"</div>" intoString:&vendorIDContainer];
					
					if (vendorIDContainer) {
						vendorFormScanner = [NSScanner scannerWithString:vendorIDContainer];
						
						[vendorFormScanner scanUpToString:@"<option" intoString:NULL];
						while ([vendorFormScanner scanString:@"<option" intoString:NULL]) {
							NSString *vendorName = nil;
							NSString *vendorID = nil;
							
							// Parse vendor name.
							[vendorFormScanner scanUpToString:@">" intoString:NULL];
							[vendorFormScanner scanString:@">" intoString:NULL];
							[vendorFormScanner scanUpToString:@" - " intoString:&vendorName];
							
							// Parse vendor ID.
							[vendorFormScanner scanString:@"- " intoString:NULL];
							[vendorFormScanner scanUpToString:@"</option>" intoString:&vendorID];
							
							vendors[vendorID] = vendorName;
							
							[vendorFormScanner scanUpToString:@"<option" intoString:NULL];
						}
						
						[self performSelectorOnMainThread:@selector(finishedLoadingVendors) withObject:nil waitUntilDone:YES];
					} else {
						[self performSelectorOnMainThread:@selector(failedToLoadVendorIDs) withObject:nil waitUntilDone:YES];
					}
				} else {
					[self performSelectorOnMainThread:@selector(failedToLoadVendorIDs) withObject:nil waitUntilDone:YES];
				}
				
				NSScanner *logoutFormScanner = [NSScanner scannerWithString:paymentsPage];
				NSString *signoutFormAction = nil;
				[logoutFormScanner scanUpToString:@"<li role=\"menuitem\" class=\"session-nav-link\">" intoString:NULL];
				[logoutFormScanner scanString:@"<li role=\"menuitem\" class=\"session-nav-link\">" intoString:NULL];
				[logoutFormScanner scanUpToString:@"<a href=\"" intoString:NULL];
				if ([logoutFormScanner scanString:@"<a href=\"" intoString:NULL]) {
					[logoutFormScanner scanUpToString:@"\"" intoString:&signoutFormAction];
					NSURL *logoutURL = [NSURL URLWithString:[kITCBaseURL stringByAppendingString:signoutFormAction]];
					[NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:logoutURL] returningResponse:nil error:nil];
				} else {
					[self performSelectorOnMainThread:@selector(failedToLoadVendorIDs) withObject:nil waitUntilDone:YES];
				}
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
		vc = [[(UINavigationController *)self.presentedViewController viewControllers] objectAtIndex:0];
	} else {
		// Editing existing account.
		vc = self.navigationController.viewControllers.lastObject;
	}
	return vc;
}

- (NSString *)stringFromSynchronousPostRequestWithURL:(NSURL *)URL bodyDictionary:(NSDictionary *)bodyDictionary {
	NSData *data = [self dataFromSynchronousPostRequestWithURL:URL bodyDictionary:bodyDictionary response:NULL];
	if (data) {
		return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	}
	return nil;
}

- (NSData *)dataFromSynchronousPostRequestWithURL:(NSURL *)URL bodyDictionary:(NSDictionary *)bodyDictionary response:(NSHTTPURLResponse **)response {
	NSString *postDictString = [bodyDictionary formatForHTTP];
	NSData *httpBody = [postDictString dataUsingEncoding:NSASCIIStringEncoding];
	NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:URL];
	[urlRequest setHTTPMethod:@"POST"];
	[urlRequest setHTTPBody:httpBody];
	NSData *data = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:response error:NULL];
	return data;
}

@end
