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

/*
 Write here your security code. If it is empty then no prompt will be shown.
*/
#define MY_SECURITY_CODE @"1234"

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

	if ([MY_SECURITY_CODE length]>0) {
		window.hidden=YES;
		securityPrompt=nil;
	}
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	securityPrompt=nil;
	if (buttonIndex==0) {
		UITextField *textField=(UITextField*)[alertView viewWithTag:99];
		if ([textField.text isEqualToString:MY_SECURITY_CODE])
			window.hidden=NO;
		else
			[self showSecurityAlert];
	}
}

- (void)handleEndOnExit:(id)sender {
	if (securityPrompt)
		[securityPrompt dismissWithClickedButtonIndex:0 animated:YES];
}

- (void)showSecurityAlert {
	UITextField *textField;
	securityPrompt = [[UIAlertView alloc] initWithTitle:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"]
										 message:@"Please enter the security code\n\n\n"
										delegate:self
							   cancelButtonTitle:nil
							   otherButtonTitles:@"Enter",nil];

	textField = [[UITextField alloc] initWithFrame:CGRectMake(12.0, 75.0, 260.0, 25.0)];
	textField.tag=99;
	textField.keyboardType=UIKeyboardTypeNumberPad;
	[textField addTarget:self action:@selector(handleEndOnExit:)
		forControlEvents:UIControlEventEditingDidEndOnExit];
	[textField setBackgroundColor:[UIColor whiteColor]];
	[textField setSecureTextEntry:YES];
	[securityPrompt addSubview:textField];

	if ([[[UIDevice currentDevice] systemVersion] floatValue]<4.0)
		[securityPrompt setTransform:CGAffineTransformMakeTranslation(0.0, 110.0)];
	[securityPrompt show];
    [securityPrompt release];

	// set cursor and show keyboard
	[textField becomeFirstResponder];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	if ([MY_SECURITY_CODE length]>0)
		[self showSecurityAlert];
}

- (void)applicationWillResignActive:(UIApplication *)application {
	if ([MY_SECURITY_CODE length]>0) {
		if (securityPrompt) {
			[securityPrompt dismissWithClickedButtonIndex:1 animated:NO];
		}
		window.hidden=YES;
	}
}

- (void)dealloc 
{
	[rootViewController release];
	[window release];
	[super dealloc];
}

@end
