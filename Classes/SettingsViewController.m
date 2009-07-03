/*
SettingsViewController.m
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

#import "SettingsViewController.h"
#import "CurrencyManager.h"
#import "CurrencySelectionDialog.h"
#import "SFHFKeychainUtils.h"

@implementation SettingsViewController

- (void)dealloc 
{
    [super dealloc];
}

- (void)viewDidLoad 
{
    [super viewDidLoad];
	self.navigationItem.title = NSLocalizedString(@"Settings",nil);
	self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
	explanationsLabel.font = [UIFont systemFontOfSize:12.0];
	explanationsLabel.text = NSLocalizedString(@"Exchange rates are automatically refreshed every 6 hours.\n\nAll information is presented without any warranties.\n\nThe presented market trend reports should not be considered to be your monthly royalty reports.",nil);
	copyrightLabel.font = [UIFont systemFontOfSize:12.0];
	currencySectionLabel.font = [UIFont boldSystemFontOfSize:16.0];
	loginSectionLabel.font = [UIFont boldSystemFontOfSize:16.0];
	lastRefreshLabel.font = [UIFont systemFontOfSize:12.0];
	
	NSString *username = [[NSUserDefaults standardUserDefaults] stringForKey:@"iTunesConnectUsername"];
	if (username) {
		usernameTextField.text = username;
		NSError *error = nil;
		NSString *password = [SFHFKeychainUtils getPasswordForUsername:username
														andServiceName:@"omz:software AppSales Mobile Service"
																 error:&error];
		if (password) passwordTextField.text = password;
	}
	
	[self baseCurrencyChanged]; //set proper currency button title
	[self currencyRatesDidUpdate]; //set proper refresh date in label
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currencyRatesDidUpdate) name:@"CurrencyManagerDidUpdate" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currencyRatesFailedToUpdate) name:@"CurrencyManagerError" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(baseCurrencyChanged) name:@"CurrencyManagerDidChangeBaseCurrency" object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
	if (usernameTextField.text.length) {
		[[NSUserDefaults standardUserDefaults] setObject:usernameTextField.text
												  forKey:@"iTunesConnectUsername"];
		NSError *error = nil;
		if (passwordTextField.text.length)
			[SFHFKeychainUtils storeUsername:usernameTextField.text
								 andPassword:passwordTextField.text
							  forServiceName:@"omz:software AppSales Mobile Service"
							  updateExisting:YES
									   error:&error];
	}
}

#pragma mark Text Field Delegate 
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	return YES;
}

#pragma mark Currencies
- (void)currencyRatesDidUpdate
{
	NSDate *lastRefresh = [[CurrencyManager sharedManager] lastRefresh];
	NSDateFormatter *formatter = [[NSDateFormatter new] autorelease];
	[formatter setTimeStyle:NSDateFormatterShortStyle];
	[formatter setDateStyle:NSDateFormatterMediumStyle];
	NSString *lastRefreshString = [formatter stringFromDate:lastRefresh];
	
	lastRefreshLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Last refresh: %@",nil), lastRefreshString];
}

- (void)currencyRatesFailedToUpdate
{
	UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",nil) message:NSLocalizedString(@"The currency exchange rates could not be refreshed. Please check your internet connection.",nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil] autorelease];
	[alert show];
}

- (void)baseCurrencyChanged
{
	[currencySelectionControl setTitle:[NSString stringWithFormat:NSLocalizedString(@"Select... ( %@ )",nil), [[CurrencyManager sharedManager] baseCurrencyDescription]] forSegmentAtIndex:0];
}

- (IBAction)changeCurrency:(id)sender
{
	CurrencySelectionDialog *currencySelectionDialog = [[CurrencySelectionDialog new] autorelease];
	UINavigationController *navController = [[[UINavigationController alloc] initWithRootViewController:currencySelectionDialog] autorelease];
	[self presentModalViewController:navController animated:YES];
}

- (IBAction)refreshExchangeRates:(id)sender
{
	[[CurrencyManager sharedManager] forceRefresh];
}

@end
