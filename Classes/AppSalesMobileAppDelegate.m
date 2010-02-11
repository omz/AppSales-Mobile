/*
 AppSalesMobileAppDelegate.m
 AppSalesMobile
 
 * Copyright (c) 2008, omz:software
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the <organization> nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY omz:software ''AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL <copyright holder> BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "AppSalesMobileAppDelegate.h"
#import "RootViewController.h"
#import "Day.h"
#import "ReportManager.h"
//#import "ReviewManager.h"

@implementation AppSalesMobileAppDelegate

//- (void) hackOnMain {
//	if ([ReviewManager sharedManager].numberOfApps) {
//		[[ReviewManager sharedManager] downloadReviews];
//	}
//}
//- (void) hackOnBackground {
//	[self performSelectorOnMainThread:@selector(hackOnMain) withObject:nil waitUntilDone:NO];
//}
//[self performSelector:@selector(hackOnBackground) withObject:nil afterDelay:0.1];

- (void) finishLoadingUI {
	NSAssert([NSThread isMainThread], nil);
	[loadingLabel removeFromSuperview];
	[loadingLabel release];
	loadingLabel = nil;
	
	RootViewController *rootViewController = [[[RootViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
	navigationController = [[UINavigationController alloc] initWithRootViewController:rootViewController];
	navigationController.toolbarHidden = NO;
	[window addSubview:navigationController.view];
}

- (void) loadSavedFiles {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[[ReportManager sharedManager] loadSavedFiles];
	[self performSelectorOnMainThread:@selector(finishLoadingUI) withObject:nil waitUntilDone:NO];
	[pool release];
}

- (void)applicationDidFinishLaunching:(UIApplication *)application  {
	window = [[UIWindow alloc] initWithFrame:CGRectMake(0,0,320,480)];
	
	loadingLabel = [[UILabel alloc] initWithFrame:window.frame];
	loadingLabel.text = NSLocalizedString(@"Loading...", nil);
	loadingLabel.textAlignment = UITextAlignmentCenter;
	loadingLabel.textColor = [UIColor whiteColor];
	loadingLabel.backgroundColor = nil;
	loadingLabel.alpha = 0;
	[window addSubview:loadingLabel];
	[window makeKeyAndVisible];
	
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDelay:1]; // only show if it's taking a moment to load
	[UIView setAnimationDuration:0.3];
	loadingLabel.alpha = 1;
	[UIView commitAnimations];
	[self performSelectorInBackground:@selector(loadSavedFiles) withObject:nil];
}


- (void)applicationWillTerminate:(UIApplication *)application {
	
}


- (void)dealloc {
	[navigationController release];
	[window release];
	[super dealloc];
}

@end
