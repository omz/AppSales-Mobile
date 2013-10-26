//
//  AccountsViewController+VendorID.m
//  AppSales
//
//  Created by Ole Zorn on 24.08.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "AccountsViewController+VendorID.h"
#import "NSDictionary+HTTP.h"
#import "RegexKitLite.h"

@implementation AccountsViewController (AccountsViewController_VendorID)

- (void)findVendorIDsWithLogin:(NSDictionary *)loginInfo
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	NSString *username = [loginInfo objectForKey:kAccountUsername];
	NSString *password = [loginInfo objectForKey:kAccountPassword];
	
	NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	NSArray *cookies = [cookieStorage cookiesForURL:[NSURL URLWithString:@"https://itunesconnect.apple.com"]];
	for (NSHTTPCookie *cookie in cookies) {
		[cookieStorage deleteCookie:cookie];
	}
	
	cookies = [cookieStorage cookiesForURL:[NSURL URLWithString:@"https://reportingitc.apple.com"]];    
	for (NSHTTPCookie *cookie in cookies) {
		[cookieStorage deleteCookie:cookie];
	}
	
	NSString *ittsBaseURL = @"https://itunesconnect.apple.com";
	NSString *ittsLoginPageAction = @"/WebObjects/iTunesConnect.woa";
	NSString *signoutSentinel = @"menu-item sign-out";
	
	NSURL *loginURL = [NSURL URLWithString:[ittsBaseURL stringByAppendingString:ittsLoginPageAction]];
	NSHTTPURLResponse *loginPageResponse = nil;
	NSError *loginPageError = nil;
	NSData *loginPageData = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:loginURL] returningResponse:&loginPageResponse error:&loginPageError];
	NSString *loginPage = [[[NSString alloc] initWithData:loginPageData encoding:NSUTF8StringEncoding] autorelease];
	
	if ([loginPage rangeOfString:signoutSentinel].location == NSNotFound) {
		// find the login action
		NSScanner *loginPageScanner = [NSScanner scannerWithString:loginPage];
		[loginPageScanner scanUpToString:@"action=\"" intoString:nil];
		if (![loginPageScanner scanString:@"action=\"" intoString:nil]) {
			[self performSelectorOnMainThread:@selector(failedToLoadVendorIDs) withObject:nil waitUntilDone:YES];
			[pool release];
			return;
		}
		NSString *loginAction = nil;
		[loginPageScanner scanUpToString:@"\"" intoString:&loginAction];
		
		NSDictionary *postDict = [NSDictionary dictionaryWithObjectsAndKeys:
								  username, @"theAccountName",
								  password, @"theAccountPW", 
								  @"39", @"1.Continue.x", // coordinates of submit button on screen.  any values seem to work
								  @"7", @"1.Continue.y",
								  nil];
		loginPage = [self stringFromSynchronousPostRequestWithURL:[NSURL URLWithString:[ittsBaseURL stringByAppendingString:loginAction]] bodyDictionary:postDict];
		
		if (loginPage == nil || [loginPage rangeOfString:signoutSentinel].location == NSNotFound) {
			[self performSelectorOnMainThread:@selector(failedToLoadVendorIDs) withObject:nil waitUntilDone:YES];
			[pool release];
			return;
		}
	}
	
	NSError *error = nil;
	NSString *salesAction = @"https://reportingitc.apple.com";
	NSString *salesRedirectPage = [NSString stringWithContentsOfURL:[NSURL URLWithString:salesAction] usedEncoding:NULL error:&error];
	
    if (error) {
		[self performSelectorOnMainThread:@selector(failedToLoadVendorIDs) withObject:nil waitUntilDone:YES];
		[pool release];
		return;
	}
	
	NSScanner *salesRedirectScanner = [NSScanner scannerWithString:salesRedirectPage];
	NSString *viewState = [salesRedirectPage stringByMatching:@"\"javax.faces.ViewState\" value=\"(.*?)\"" capture:1];
	[salesRedirectScanner scanUpToString:@"script id=\"defaultVendorPage:" intoString:nil];
	if (![salesRedirectScanner scanString:@"script id=\"defaultVendorPage:" intoString:nil]) {
		[self performSelectorOnMainThread:@selector(failedToLoadVendorIDs) withObject:nil waitUntilDone:YES];
		[pool release];
		return;
	}
	NSString *defaultVendorPage = nil;
	[salesRedirectScanner scanUpToString:@"\"" intoString:&defaultVendorPage];
	
	// click though from the dashboard to the sales page
    NSDictionary *reportPostData = [NSDictionary dictionaryWithObjectsAndKeys:
									[defaultVendorPage stringByReplacingOccurrencesOfString:@"_2" withString:@"_0"], @"AJAXREQUEST",
									viewState, @"javax.faces.ViewState",
									defaultVendorPage, @"defaultVendorPage",
									[@"defaultVendorPage:" stringByAppendingString:defaultVendorPage],[@"defaultVendorPage:" stringByAppendingString:defaultVendorPage],
									nil];
	
	[self dataFromSynchronousPostRequestWithURL:[NSURL URLWithString:@"https://reportingitc.apple.com/vendor_default.faces"] bodyDictionary:reportPostData response:NULL];
	
	NSString *salesPage = [NSString stringWithContentsOfURL:[NSURL URLWithString:@"https://reportingitc.apple.com/sales.faces"] usedEncoding:NULL error:NULL];
	NSString *defaultVendorID = [salesPage stringByMatching:@">.*?\\s?(8[0-9]{7})" capture:1];
	if (!defaultVendorID) {
		[self performSelectorOnMainThread:@selector(failedToLoadVendorIDs) withObject:nil waitUntilDone:YES];
	} else {
		[self performSelectorOnMainThread:@selector(finishedLoadingVendorID:) withObject:defaultVendorID waitUntilDone:YES];
	}
	
	[pool release];
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
