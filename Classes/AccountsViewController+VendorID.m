//
//  AccountsViewController+VendorID.m
//  AppSales
//
//  Created by Ole Zorn on 24.08.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "AccountsViewController+VendorID.h"
#import "NSDictionary+HTTP.h"

@implementation AccountsViewController (AccountsViewController_VendorID)

- (void)findVendorIDsWithLogin:(NSDictionary *)loginInfo
{
	// TODO: This feature will be re-implemented (and work) in a future commit.
}

- (void)finishedLoadingVendorID:(NSString *)vendorID
{
	if (self.presentedViewController) {
		//Adding new account:
		FieldEditorViewController *vc = [[(UINavigationController *)self.presentedViewController viewControllers] objectAtIndex:0];
		[vc.values setObject:vendorID forKey:kAccountVendorID];
		[vc.tableView reloadData];
	} else {
		//Editing existing account:
		FieldEditorViewController *vc = self.navigationController.viewControllers.lastObject;
		[vc.values setObject:vendorID forKey:kAccountVendorID];
		[vc.tableView reloadData];
	}
}

- (void)failedToLoadVendorIDs
{
	[[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"The vendor ID could not be filled automatically. Please check your username and password or enter your vendor ID manually. You'll find it at the top of the Sales and Trends module on itunesconnect.apple.com.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] autorelease] show];
}

- (NSString *)stringFromSynchronousPostRequestWithURL:(NSURL *)URL bodyDictionary:(NSDictionary *)bodyDictionary
{
	NSData *data = [self dataFromSynchronousPostRequestWithURL:URL bodyDictionary:bodyDictionary response:NULL];
	if (data) {
		return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	}
	return nil;
}

- (NSData *)dataFromSynchronousPostRequestWithURL:(NSURL *)URL bodyDictionary:(NSDictionary *)bodyDictionary response:(NSHTTPURLResponse **)response
{
	NSString *postDictString = [bodyDictionary formatForHTTP];
	NSData *httpBody = [postDictString dataUsingEncoding:NSASCIIStringEncoding];
	NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:URL];
	[urlRequest setHTTPMethod:@"POST"];
	[urlRequest setHTTPBody:httpBody];
	NSData *data = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:response error:NULL];
	return data;
}


@end
