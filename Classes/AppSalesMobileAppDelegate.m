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
#import "PadRootViewController.h"
#import "UIDevice+iPad.h"

@implementation AppSalesMobileAppDelegate

@synthesize window;
@synthesize rootViewController;


- (void)applicationDidFinishLaunching:(UIApplication *)application 
{
	self.window = [[[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds] autorelease];
	
	if ([[UIDevice currentDevice] isPad]) {
		self.rootViewController = [[[PadRootViewController alloc] initWithNibName:nil bundle:nil] autorelease];
	} else {
		self.rootViewController = [[[UINavigationController alloc] initWithRootViewController:[[[RootViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease]] autorelease];
		[(UINavigationController *)rootViewController setToolbarHidden:NO];
        
        // quickly fade from splash screen to the active app
        UIImageView *splashView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 20, 320, 460)];
        UIImage *image = [UIImage imageNamed:@"Default"];
        NSAssert(image, nil);
        splashView.image = image;
        [rootViewController.view addSubview:splashView]; // retains
        
        [UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:0.2f];
        
        splashView.alpha = 0;
        
		[UIView setAnimationDelegate:splashView];
		[UIView setAnimationDidStopSelector:@selector(removeFromSuperview)]; // releases
		[UIView commitAnimations];
        [splashView release];
	}
	
	[window addSubview:rootViewController.view];
	[window makeKeyAndVisible];
}

- (void)dealloc 
{
	[rootViewController release];
	[window release];
	[super dealloc];
}

@end
