//
// Copyright 2011-2012 Kosher Penguin LLC 
// Created by Adar Porat (https://github.com/aporat) on 1/16/2012.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//		http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "KKPasscodeViewController.h"
#import "KKKeychain.h"
#import "KKPasscodeSettingsViewController.h"
#import "KKPasscodeLock.h"
#import <QuartzCore/QuartzCore.h>
#import <LocalAuthentication/LocalAuthentication.h>
#import "DarkModeCheck.h"

@implementation KKPasscodeViewController

#pragma mark -
#pragma mark UIViewController

- (void)loadView {
	[super loadView];
	
	self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
	
	enterPasscodeTableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
	enterPasscodeTableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	enterPasscodeTableView.delegate = self;
	enterPasscodeTableView.dataSource = self;
	enterPasscodeTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	enterPasscodeTableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
	[self.view addSubview:enterPasscodeTableView];
	
	setPasscodeTableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
	setPasscodeTableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	setPasscodeTableView.delegate = self;
	setPasscodeTableView.dataSource = self;
	setPasscodeTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	setPasscodeTableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
	[self.view addSubview:setPasscodeTableView];
	
	confirmPasscodeTableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
	confirmPasscodeTableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	confirmPasscodeTableView.delegate = self;
	confirmPasscodeTableView.dataSource = self;
	confirmPasscodeTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	confirmPasscodeTableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
	[self.view addSubview:confirmPasscodeTableView];
	
	[self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)]];
}

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	
	CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height ?: 20.0f;
	CGFloat navigationBarHeight = self.navigationController.navigationBar.frame.size.height ?: 44.0f;
	CGFloat topInset = self.topLayoutGuide.length ?: (statusBarHeight + navigationBarHeight);
	
	enterPasscodeTableView.contentInset = UIEdgeInsetsMake(topInset, 0.0f, 0.0f, 0.0f);
	setPasscodeTableView.contentInset = UIEdgeInsetsMake(topInset, 0.0f, 0.0f, 0.0f);
	confirmPasscodeTableView.contentInset = UIEdgeInsetsMake(topInset, 0.0f, 0.0f, 0.0f);
}

- (void)viewDidLoad {
	[super viewDidLoad];	
	
	passcodeLockOn = [[KKKeychain getStringForKey:@"passcode_on"] isEqualToString:@"YES"];
	eraseData = [KKPasscodeLock sharedLock].eraseOption && [[KKKeychain getStringForKey:@"erase_data_on"] isEqualToString:@"YES"];
}

- (void)viewWillAppear:(BOOL)animated  {
	[super viewWillAppear:animated];
	
	enterPasscodeTextField = self.newPasscodeTextField;
	setPasscodeTextField = self.newPasscodeTextField;
	confirmPasscodeTextField = self.newPasscodeTextField;
	
	tableViews = [[NSMutableArray alloc] init];
	textFields = [[NSMutableArray alloc] init];
	squares = [[NSMutableArray alloc] init];
	
	if ((self.mode == KKPasscodeModeSet) || (self.mode == KKPasscodeModeChange)) {
		if (passcodeLockOn) {
			enterPasscodeTableView.tableHeaderView = [self passwordHeaderViewForTextField:enterPasscodeTextField];
			[tableViews addObject:enterPasscodeTableView];
			[textFields addObject:enterPasscodeTextField];
			[squares addObject:self.squares];
			UIView *squaresView = [[UIView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width * 0.5 - 71.0 * 4 * 0.5, 0, 71.0 * 4, 53)];
			squaresView.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin);
			for (int i = 0; i < [[squares lastObject] count]; i++) {
				[squaresView addSubview:[squares lastObject][i]];
			}
			[enterPasscodeTableView.tableHeaderView addSubview:squaresView];
		}
		
		setPasscodeTableView.tableHeaderView = [self passwordHeaderViewForTextField:setPasscodeTextField];
		[tableViews addObject:setPasscodeTableView];
		[textFields addObject:setPasscodeTextField];
		[squares addObject:self.squares];
		UIView *squaresView = [[UIView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width * 0.5 - 71.0 * 4 * 0.5, 0, 71.0 * 4, 53)];
		squaresView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
		for (int i = 0; i < [[squares lastObject] count]; i++) {
			[squaresView addSubview:[squares lastObject][i]];
		}
		[setPasscodeTableView.tableHeaderView addSubview:squaresView];
		
		confirmPasscodeTableView.tableHeaderView = [self passwordHeaderViewForTextField:confirmPasscodeTextField];
		[tableViews addObject:confirmPasscodeTableView];
		[textFields addObject:confirmPasscodeTextField];
		[squares addObject:self.squares];
		UIView *squaresConfirmView = [[UIView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width * 0.5 - 71.0 * 4 * 0.5, 0, 71.0 * 4, 53)];
		squaresConfirmView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
		for (int i = 0; i < [[squares lastObject] count]; i++) {
			[squaresConfirmView addSubview:[squares lastObject][i]];
		}
		[confirmPasscodeTableView.tableHeaderView addSubview:squaresConfirmView];
	} else {
		enterPasscodeTableView.tableHeaderView = [self passwordHeaderViewForTextField:enterPasscodeTextField];
		[tableViews addObject:enterPasscodeTableView];
		[textFields addObject:enterPasscodeTextField];
		[squares addObject:self.squares];
		UIView *squaresView = [[UIView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width * 0.5 - 71.0 * 4 * 0.5, 0, 71.0 * 4, 53)];
		squaresView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
		for (int i = 0; i < [[squares lastObject] count]; i++) {
			[squaresView addSubview:[squares lastObject][i]];
		}
		[enterPasscodeTableView.tableHeaderView addSubview:squaresView];
		if (self.startBiometricAuthentication) {
			[self authenticateWithBiometrics];
		}
	}
	
	[self.view addSubview:tableViews[0]];
	
	// Shift any extra table views away.
	for (int i = 1; i < tableViews.count; i++) {
		UITableView *tableView = tableViews[i];
		tableView.frame = CGRectMake(tableView.frame.origin.x + self.view.bounds.size.width, tableView.frame.origin.y, tableView.frame.size.width, tableView.frame.size.height);
		[self.view addSubview:tableView];
	}
	
	[textFields[0] becomeFirstResponder];
	[tableViews[0] reloadData];
	[textFields[tableViews.count - 1] setReturnKeyType:UIReturnKeyDone];
	
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
		if (tableViews.count > 1) {
			[self moveToNextTableView];
			[self moveToPreviousTableView];
		} else {
			UITableView *tv = tableViews[0];
			tv.frame = CGRectMake(tv.frame.origin.x, tv.frame.origin.y, self.view.bounds.size.width, self.view.bounds.size.height);
		}
	}
}

- (void)viewTapped:(UITapGestureRecognizer *)recognizer {
	[textFields[tableIndex] becomeFirstResponder];
}

+ (BOOL)hasBiometricAuthentication {
	return [[[LAContext alloc] init] canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:nil];
}

+ (KKBiometryType)biometryType {
	LAContext *authenticationContext = [[LAContext alloc] init];
	BOOL hasBiometricAuthentication = [authenticationContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:nil];
	if (hasBiometricAuthentication) {
		if (@available(iOS 11.0, *)) {
			return (KKBiometryType)authenticationContext.biometryType;
		} else {
			return KKBiometryTypeTouchID;
		}
	}
	return KKBiometryNone;
}

+ (NSString *)biometryTypeString {
	switch (KKPasscodeViewController.biometryType) {
		case KKBiometryTypeTouchID:
			return @"Touch ID";
		case KKBiometryTypeFaceID:
			return @"Face ID";
		default:
			return @"Biometry";
	}
}

- (void)authenticateWithBiometrics {
	BOOL unlockWithBiometricsOn = [[KKKeychain getStringForKey:@"unlock_with_biometrics"] isEqualToString:@"YES"];
	if (!KKPasscodeViewController.hasBiometricAuthentication || !unlockWithBiometricsOn) { return; }
	[[[LAContext alloc] init] evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics localizedReason:NSLocalizedString(@"Authenticate to Unlock AppSales", nil) reply:^(BOOL success, NSError *error) {
		if (error) {
			// There was a problem verifying your identity.
			NSLog(@"WARNING [%@]: %@", KKPasscodeViewController.biometryTypeString, error.localizedDescription);
			return;
		}
		if (success) {
			// Success
			if (self.mode == KKPasscodeModeEnter) {
				dispatch_async(dispatch_get_main_queue(), ^{
					if ([self.delegate respondsToSelector:@selector(didPasscodeEnteredCorrectly:)]) {
						[self.delegate didPasscodeEnteredCorrectly:self];
					}
					[self dismissViewControllerAnimated:YES completion:nil];
				});
			} else if (self.mode == KKPasscodeModeDisabled) {
				if ([KKKeychain setString:@"NO" forKey:@"passcode_on"]) {
					[KKKeychain setString:@"" forKey:@"passcode"];
				}
				dispatch_async(dispatch_get_main_queue(), ^{
					if ([self.delegate respondsToSelector:@selector(didSettingsChanged:)]) {
						[self.delegate performSelector:@selector(didSettingsChanged:) withObject:self];
					}
					
					[self dismissViewControllerAnimated:YES completion:nil];
				});
			}
		}
	}];
}

#pragma mark -
#pragma mark Private

- (UITextField *)newPasscodeTextField {
	UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(29.0, 18.0, 271.0, 24.0)];
	textField.font = [UIFont systemFontOfSize:14];
	textField.text = @"";
	textField.textColor = [UIColor blackColor];
	textField.secureTextEntry = YES;
	textField.delegate = self;
	textField.keyboardAppearance = UIKeyboardAppearanceAlert;
	return textField;
}

- (void)cancelButtonPressed:(id)sender {
	if ([self.delegate respondsToSelector:@selector(didSettingsChanged:)]) {
		[self.delegate performSelector:@selector(didSettingsChanged:) withObject:self];
	}
	
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)incrementAndShowFailedAttemptsLabel {
	enterPasscodeTextField.text = @"";
	for (int i = 0; i < 4; i++) {
        [squares[tableIndex][i] setImage:[DarkModeCheck checkForDarkModeImage:@"passcode_square_empty.png"]];
	}		 
	
	failedAttemptsCount += 1;
	if (failedAttemptsCount == 1) {
		failedAttemptsLabel.text = @"1 Failed Passcode Attempt";
	} else {
		failedAttemptsLabel.text = [NSString stringWithFormat:@"%li Failed Passcode Attempts", (long)failedAttemptsCount];
	}
	CGSize size = [failedAttemptsLabel.text sizeWithAttributes:@{NSFontAttributeName : [UIFont boldSystemFontOfSize:14.0]}];
	failedAttemptsView.frame = CGRectMake((self.view.bounds.size.width - (size.width + 36.0)) / 2, 147.5, size.width + 36.0, size.height + 10.0);
	failedAttemptsLabel.frame = CGRectMake((self.view.bounds.size.width - (size.width + 36.0)) / 2, 147.5, size.width + 36.0, size.height + 10.0);
	
	CAGradientLayer *gradient = [CAGradientLayer layer];
	gradient.frame = failedAttemptsView.bounds;
	gradient.colors = @[(id)[[UIColor colorWithRed:0.714 green:0.043 blue:0.043 alpha:1.0] CGColor],
						(id)[[UIColor colorWithRed:0.761 green:0.192 blue:0.192 alpha:1.0] CGColor]];
	[failedAttemptsView.layer insertSublayer:gradient atIndex:0];
	failedAttemptsView.layer.masksToBounds = YES;
	
	failedAttemptsLabel.hidden = NO;
	failedAttemptsView.hidden = NO;
	
	if (failedAttemptsCount == [KKPasscodeLock sharedLock].attemptsAllowed) {
		
		enterPasscodeTextField.delegate = nil;
		
		if (eraseData) {
			if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
				[UIView beginAnimations:@"fadeIn" context:nil];
				[UIView setAnimationDelay:0.25];
				[UIView setAnimationDuration:0.5];
				
				[UIView commitAnimations];
			}
						
			if ([self.delegate respondsToSelector:@selector(shouldEraseApplicationData:)]) {
				[self.delegate shouldEraseApplicationData:self];
			}
		} else {
			if ([self.delegate respondsToSelector:@selector(didPasscodeEnteredIncorrectly:)]) {
				[self.delegate didPasscodeEnteredIncorrectly:self];
			}
		}
	}
	
}

- (void)moveToNextTableView {
	tableIndex += 1;
	UITableView *oldTableView = tableViews[tableIndex - 1];
	UITableView *newTableView = tableViews[tableIndex];
	newTableView.frame = CGRectMake(oldTableView.frame.origin.x + self.view.bounds.size.width, oldTableView.frame.origin.y, oldTableView.frame.size.width, oldTableView.frame.size.height);
	
	for (int i = 0; i < 4; i++) {
		[squares[tableIndex][i] setImage:[DarkModeCheck checkForDarkModeImage:@"passcode_square_empty.png"]];
	}
	
	[UIView beginAnimations:@"" context:nil];
	[UIView setAnimationDuration:0.25];										 
	oldTableView.frame = CGRectMake(oldTableView.frame.origin.x - self.view.bounds.size.width, oldTableView.frame.origin.y, oldTableView.frame.size.width, oldTableView.frame.size.height);
	newTableView.frame = self.view.bounds;
	[UIView commitAnimations];
	
	
	[textFields[tableIndex - 1] resignFirstResponder];
	[textFields[tableIndex] becomeFirstResponder];
}

- (void)moveToPreviousTableView {
	tableIndex -= 1;
	UITableView *oldTableView = tableViews[tableIndex + 1];
	UITableView *newTableView = tableViews[tableIndex];
	newTableView.frame = CGRectMake(oldTableView.frame.origin.x - self.view.bounds.size.width, oldTableView.frame.origin.y, oldTableView.frame.size.width, oldTableView.frame.size.height);
	
	for (int i = 0; i < 4; i++) {
		[squares[tableIndex][i] setImage:[DarkModeCheck checkForDarkModeImage:@"passcode_square_empty.png"]];
	}
	
	[UIView beginAnimations:@"" context:nil];
	[UIView setAnimationDuration:0.25];										 
	oldTableView.frame = CGRectMake(oldTableView.frame.origin.x + self.view.bounds.size.width, oldTableView.frame.origin.y, oldTableView.frame.size.width, oldTableView.frame.size.height);
	newTableView.frame = self.view.bounds;
	[UIView commitAnimations];
	
	[textFields[tableIndex + 1] resignFirstResponder];
	[textFields[tableIndex] becomeFirstResponder];
}

- (void)nextDigitPressed {
	UITextField *textField = textFields[tableIndex];
	
	if (![textField.text isEqualToString:@""]) {
		
		if (self.mode == KKPasscodeModeSet) {
			if ([textField isEqual:setPasscodeTextField]) {
				[self moveToNextTableView];
			} else if ([textField isEqual:confirmPasscodeTextField]) {
				if (![confirmPasscodeTextField.text isEqualToString:setPasscodeTextField.text]) {
					confirmPasscodeTextField.text = @"";
					setPasscodeTextField.text = @"";
					passcodeConfirmationWarningLabel.text = @"Passcodes did not match. Try again.";
					[self moveToPreviousTableView];
				} else {
					if ([KKKeychain setString:setPasscodeTextField.text forKey:@"passcode"]) {
						[KKKeychain setString:@"YES" forKey:@"passcode_on"];
					}
					
					if ([self.delegate respondsToSelector:@selector(didSettingsChanged:)]) {
						[self.delegate performSelector:@selector(didSettingsChanged:) withObject:self];
					}
					
					[self dismissViewControllerAnimated:YES completion:nil];
				}
			}						 
		} else if (self.mode == KKPasscodeModeChange) {
			NSString *passcode = [KKKeychain getStringForKey:@"passcode"];
			if ([textField isEqual:enterPasscodeTextField]) {
				if ([passcode isEqualToString:enterPasscodeTextField.text]) {
					[self moveToNextTableView];
				} else {
					[self incrementAndShowFailedAttemptsLabel];
				}
			} else if ([textField isEqual:setPasscodeTextField]) {
				if ([passcode isEqualToString:setPasscodeTextField.text]) {
					setPasscodeTextField.text = @"";
					passcodeConfirmationWarningLabel.text = @"Enter a different passcode. You cannot re-use the same passcode.";
					passcodeConfirmationWarningLabel.frame = CGRectMake(0.0, 131.5, self.view.bounds.size.width, 60.0);
				} else {
					passcodeConfirmationWarningLabel.text = @"";
					passcodeConfirmationWarningLabel.frame = CGRectMake(0.0, 146.5, self.view.bounds.size.width, 30.0);
					[self moveToNextTableView];
				}
			} else if ([textField isEqual:confirmPasscodeTextField]) {
				if (![confirmPasscodeTextField.text isEqualToString:setPasscodeTextField.text]) {
					confirmPasscodeTextField.text = @"";
					setPasscodeTextField.text = @"";
					passcodeConfirmationWarningLabel.text = @"Passcodes did not match. Try again.";
					[self moveToPreviousTableView];
				} else {
					if ([KKKeychain setString:setPasscodeTextField.text forKey:@"passcode"]) {
						[KKKeychain setString:@"YES" forKey:@"passcode_on"];
					}
					
					if ([self.delegate respondsToSelector:@selector(didSettingsChanged:)]) {
						[self.delegate performSelector:@selector(didSettingsChanged:) withObject:self];
					}
					
					[self dismissViewControllerAnimated:YES completion:nil];
				}
			}
		}
	}		 
}

- (void)doneButtonPressed {	 
	UITextField *textField = textFields[tableIndex];
	
	if (self.mode == KKPasscodeModeEnter) {
		NSString *passcode = [KKKeychain getStringForKey:@"passcode"];
		if ([enterPasscodeTextField.text isEqualToString:passcode]) {
			if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
				[UIView beginAnimations:@"fadeIn" context:nil];
				[UIView setAnimationDelay:0.25];
				[UIView setAnimationDuration:0.5];
				
				[UIView commitAnimations];
			}

			if ([self.delegate respondsToSelector:@selector(didPasscodeEnteredCorrectly:)]) {
				[self.delegate didPasscodeEnteredCorrectly:self];
			}

			[self dismissViewControllerAnimated:YES completion:nil];
		} else { 
			[self incrementAndShowFailedAttemptsLabel];
		}
	} else if (self.mode == KKPasscodeModeSet) {
		if ([textField isEqual:setPasscodeTextField]) {
			[self moveToNextTableView];
		} else if ([textField isEqual:confirmPasscodeTextField]) {
			if (![confirmPasscodeTextField.text isEqualToString:setPasscodeTextField.text]) {
				confirmPasscodeTextField.text = @"";
				setPasscodeTextField.text = @"";
				passcodeConfirmationWarningLabel.text = @"Passcodes did not match. Try again.";
				[self moveToPreviousTableView];
			} else {
				if ([KKKeychain setString:setPasscodeTextField.text forKey:@"passcode"]) {
					[KKKeychain setString:@"YES" forKey:@"passcode_on"];
				}
				
				if ([self.delegate respondsToSelector:@selector(didSettingsChanged:)]) {
					[self.delegate performSelector:@selector(didSettingsChanged:) withObject:self];
				}
				
				[self dismissViewControllerAnimated:YES completion:nil];
			}
		}						 
	} else if (self.mode == KKPasscodeModeChange) {
		NSString *passcode = [KKKeychain getStringForKey:@"passcode"];
		if ([textField isEqual:enterPasscodeTextField]) {
			if ([passcode isEqualToString:enterPasscodeTextField.text]) {
				[self moveToNextTableView];
			} else {
				[self incrementAndShowFailedAttemptsLabel];
			}
		} else if ([textField isEqual:setPasscodeTextField]) {
			if ([passcode isEqualToString:setPasscodeTextField.text]) {
				setPasscodeTextField.text = @"";
				passcodeConfirmationWarningLabel.text = @"Enter a different passcode. Cannot re-use the same passcode.";
				passcodeConfirmationWarningLabel.frame = CGRectMake(0.0, 131.5, self.view.bounds.size.width, 60.0);
			} else {
				passcodeConfirmationWarningLabel.text = @"";
				passcodeConfirmationWarningLabel.frame = CGRectMake(0.0, 146.5, self.view.bounds.size.width, 30.0);
				[self moveToNextTableView];
			}
		} else if ([textField isEqual:confirmPasscodeTextField]) {
			if (![confirmPasscodeTextField.text isEqualToString:setPasscodeTextField.text]) {
				confirmPasscodeTextField.text = @"";
				setPasscodeTextField.text = @"";
				passcodeConfirmationWarningLabel.text = @"Passcodes did not match. Try again.";
				[self moveToPreviousTableView];
			} else {
				if ([KKKeychain setString:setPasscodeTextField.text forKey:@"passcode"]) {
					[KKKeychain setString:@"YES" forKey:@"passcode_on"];
				}
				
				if ([self.delegate respondsToSelector:@selector(didSettingsChanged:)]) {
					[self.delegate performSelector:@selector(didSettingsChanged:) withObject:self];
				}
				
				[self dismissViewControllerAnimated:YES completion:nil];
			}
		}
	} else if (self.mode == KKPasscodeModeDisabled) {
		NSString *passcode = [KKKeychain getStringForKey:@"passcode"];
		if ([enterPasscodeTextField.text isEqualToString:passcode]) {
			if ([KKKeychain setString:@"NO" forKey:@"passcode_on"]) {
				[KKKeychain setString:@"" forKey:@"passcode"];
			}
			
			if ([self.delegate respondsToSelector:@selector(didSettingsChanged:)]) {
				[self.delegate performSelector:@selector(didSettingsChanged:) withObject:self];
			}
			
			[self dismissViewControllerAnimated:YES completion:nil];
		} else { 
			[self incrementAndShowFailedAttemptsLabel];
		}
	}
}

- (UIView *)passwordHeaderViewForTextField:(UITextField *)textField {
	textField.keyboardType = UIKeyboardTypeNumberPad;
	
	textField.hidden = YES;
	[self.view addSubview:textField];
	
	UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.bounds.size.width, 70.0)];
	UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 27.5, self.view.bounds.size.width, 30.0)];
    
    if (@available(iOS 13.0, *)) {
        headerLabel.textColor = [UIColor secondaryLabelColor];
    } else {
        headerLabel.textColor = [UIColor colorWithRed:0.298 green:0.337 blue:0.424 alpha:1.0];
    }
	headerLabel.backgroundColor = [UIColor clearColor];
	headerLabel.textAlignment = NSTextAlignmentCenter;
	headerLabel.font = [UIFont boldSystemFontOfSize:17.0];
	
	if ([textField isEqual:setPasscodeTextField]) {
		passcodeConfirmationWarningLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 146.5, self.view.bounds.size.width, 30.0)];
		passcodeConfirmationWarningLabel.textColor = [UIColor colorWithRed:0.298 green:0.337 blue:0.424 alpha:1.0];
		passcodeConfirmationWarningLabel.backgroundColor = [UIColor clearColor];
		passcodeConfirmationWarningLabel.textAlignment = NSTextAlignmentCenter;
		passcodeConfirmationWarningLabel.font = [UIFont systemFontOfSize:14.0];
		passcodeConfirmationWarningLabel.text = @"";
		passcodeConfirmationWarningLabel.numberOfLines = 0;
		passcodeConfirmationWarningLabel.lineBreakMode = NSLineBreakByWordWrapping;
		[headerView addSubview:passcodeConfirmationWarningLabel];
	}
	
	if ([textField isEqual:enterPasscodeTextField]) {
		NSString *text = @"1 Failed Passcode Attempt";
		CGSize size = [text sizeWithAttributes:@{NSFontAttributeName : [UIFont boldSystemFontOfSize:14.0]}];
		failedAttemptsView = [[UIView alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - (size.width + 36.0)) / 2, 147.5, size.width + 36.0, size.height + 10.0)];
		failedAttemptsLabel = [[UILabel alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - (size.width + 36.0)) / 2, 147.5, size.width + 36.0, size.height + 10.0)];
		failedAttemptsLabel.backgroundColor = [UIColor clearColor];
		failedAttemptsLabel.textColor = [UIColor whiteColor];
		failedAttemptsLabel.text = text;
		failedAttemptsLabel.font = [UIFont boldSystemFontOfSize:14.0];
		failedAttemptsLabel.textAlignment = NSTextAlignmentCenter;
		failedAttemptsView.layer.cornerRadius = 14;
		failedAttemptsView.layer.borderWidth = 1.0;
		failedAttemptsView.layer.borderColor = [[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.25] CGColor];
		
		failedAttemptsLabel.hidden = YES;
		failedAttemptsView.hidden = YES;
		
		CAGradientLayer *gradient = [CAGradientLayer layer];
		gradient.frame = failedAttemptsView.bounds;
		gradient.colors = @[(id)[[UIColor colorWithRed:0.714 green:0.043 blue:0.043 alpha:1.0] CGColor],
							(id)[[UIColor colorWithRed:0.761 green:0.192 blue:0.192 alpha:1.0] CGColor]];
		[failedAttemptsView.layer insertSublayer:gradient atIndex:1];
		failedAttemptsView.layer.masksToBounds = YES;
		
		[headerView addSubview:failedAttemptsView];
		[headerView addSubview:failedAttemptsLabel];
		
	}
	
	if (self.mode == KKPasscodeModeSet) {
		self.navigationItem.title = @"Set Passcode";
		UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed:)];
		self.navigationItem.leftBarButtonItem = cancel;
		
		
		if ([textField isEqual:enterPasscodeTextField]) {
			headerLabel.text = @"Enter your passcode";
		} else if ([textField isEqual:setPasscodeTextField]) {
			headerLabel.text = @"Enter a passcode";
			UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed:)];
			self.navigationItem.leftBarButtonItem = cancel;
			
		} else if ([textField isEqual:confirmPasscodeTextField]) {
			headerLabel.text = @"Re-enter your passcode";
		}
	} else if (self.mode == KKPasscodeModeDisabled) {
		self.navigationItem.title = @"Turn off Passcode";
		UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed:)];
		self.navigationItem.leftBarButtonItem = cancel;
		
		headerLabel.text = @"Enter your passcode";
	} else if (self.mode == KKPasscodeModeChange) {
		self.navigationItem.title = @"Change Passcode";
		UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed:)];
		self.navigationItem.leftBarButtonItem = cancel;
		
		if ([textField isEqual:enterPasscodeTextField]) {
			headerLabel.text = @"Enter your old passcode";
		} else if ([textField isEqual:setPasscodeTextField]) {
			headerLabel.text = @"Enter your new passcode";
		} else {
			headerLabel.text = @"Re-enter your new passcode";
		}
	} else {
		self.navigationItem.title = @"Enter Passcode";
		headerLabel.text = @"Enter your passcode";
	}
	headerLabel.autoresizingMask = (UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin);
	
	[headerView addSubview:headerLabel];
	
	return headerView;
}

- (NSArray *)squares {
	NSMutableArray *squareViews = [NSMutableArray array];
	
	CGFloat squareX = 0.0;
	
	for (int i = 0; i < 4; i++) {
		UIImageView *square = [[UIImageView alloc] initWithImage:[DarkModeCheck checkForDarkModeImage:@"passcode_square_empty.png"]];
		square.frame = CGRectMake(squareX, 74.0, 61.0, 53.0);
		[squareViews addObject:square];
		squareX += 71.0;
	}
	return [NSArray arrayWithArray:squareViews];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return 1;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *CellIdentifier = @"Cell";
	
	UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	}
	
	if ([aTableView isEqual:enterPasscodeTableView]) {
		cell.accessoryView = enterPasscodeTextField;
	} else if ([aTableView isEqual:setPasscodeTableView]) {
		cell.accessoryView = setPasscodeTextField;
	} else if ([aTableView isEqual:confirmPasscodeTableView]) {
		cell.accessoryView = confirmPasscodeTextField;
	}
	
	return cell;
}


#pragma mark -
#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if ([textField isEqual:textFields.lastObject]) {
		[self doneButtonPressed];
	} else {
		[self nextDigitPressed];
	}
	return NO;
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	NSString *result = [textField.text stringByReplacingCharactersInRange:range withString:string];
	textField.text = result;
	
	for (int i = 0; i < 4; i++) {
		UIImageView *square = squares[tableIndex][i];
		if (i < [result length]) {
			square.image = [DarkModeCheck checkForDarkModeImage:@"passcode_square_filled.png"];
		} else {
			square.image = [DarkModeCheck checkForDarkModeImage:@"passcode_square_empty.png"];
		}
	}
	
	if ([result length] == 4) {
		
		if (self.mode == KKPasscodeModeDisabled) {
			NSString *passcode = [KKKeychain getStringForKey:@"passcode"];
			if ([enterPasscodeTextField.text isEqualToString:passcode]) {
				if ([KKKeychain setString:@"NO" forKey:@"passcode_on"]) {
					[KKKeychain setString:@"" forKey:@"passcode"];
				}
				
				if ([self.delegate respondsToSelector:@selector(didSettingsChanged:)]) {
					[self.delegate performSelector:@selector(didSettingsChanged:) withObject:self];
				}
				
				[self dismissViewControllerAnimated:YES completion:nil];
			} else { 
				[self incrementAndShowFailedAttemptsLabel];
			}
		} else if (self.mode == KKPasscodeModeEnter) {
			NSString *passcode = [KKKeychain getStringForKey:@"passcode"];
			if ([enterPasscodeTextField.text isEqualToString:passcode]) {
				if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
					[UIView beginAnimations:@"fadeIn" context:nil];
					[UIView setAnimationDelay:0.25];
					[UIView setAnimationDuration:0.5];
					
					[UIView commitAnimations];
				}
				if ([self.delegate respondsToSelector:@selector(didPasscodeEnteredCorrectly:)]) {
					[self.delegate performSelector:@selector(didPasscodeEnteredCorrectly:) withObject:self];
				}
				
				[self dismissViewControllerAnimated:YES completion:nil];
			} else { 
				[self incrementAndShowFailedAttemptsLabel];
			}
		} else if (self.mode == KKPasscodeModeChange) {
			NSString *passcode = [KKKeychain getStringForKey:@"passcode"];
			if ([textField isEqual:enterPasscodeTextField]) {
				if ([passcode isEqualToString:enterPasscodeTextField.text]) {
					[self moveToNextTableView];
				} else {
					[self incrementAndShowFailedAttemptsLabel];
				}
			} else if ([textField isEqual:setPasscodeTextField]) {
				if ([passcode isEqualToString:setPasscodeTextField.text]) {
					setPasscodeTextField.text = @"";
					for (int i = 0; i < 4; i++) {
						[squares[tableIndex][i] setImage:[DarkModeCheck checkForDarkModeImage:@"passcode_square_empty.png"]];
					}		 
					passcodeConfirmationWarningLabel.text = @"Enter a different passcode. Cannot re-use the same passcode.";
					passcodeConfirmationWarningLabel.frame = CGRectMake(0.0, 131.5, self.view.bounds.size.width, 60.0);
				} else {
					passcodeConfirmationWarningLabel.text = @"";
					passcodeConfirmationWarningLabel.frame = CGRectMake(0.0, 146.5, self.view.bounds.size.width, 30.0);
					[self moveToNextTableView];
				}
			} else if ([textField isEqual:confirmPasscodeTextField]) {
				if (![confirmPasscodeTextField.text isEqualToString:setPasscodeTextField.text]) {
					confirmPasscodeTextField.text = @"";
					setPasscodeTextField.text = @"";
					passcodeConfirmationWarningLabel.text = @"Passcodes did not match. Try again.";
					[self moveToPreviousTableView];
				} else {
					if ([KKKeychain setString:setPasscodeTextField.text forKey:@"passcode"]) {
						[KKKeychain setString:@"YES" forKey:@"passcode_on"];
					}
					
					if ([self.delegate respondsToSelector:@selector(didSettingsChanged:)]) {
						[self.delegate performSelector:@selector(didSettingsChanged:) withObject:self];
					}
					
					[self dismissViewControllerAnimated:YES completion:nil];
				}
			}
		} else if ([textField isEqual:setPasscodeTextField]) {
			[self moveToNextTableView];
		} else if ([textField isEqual:confirmPasscodeTextField]) {
			if (![confirmPasscodeTextField.text isEqualToString:setPasscodeTextField.text]) {
				confirmPasscodeTextField.text = @"";
				setPasscodeTextField.text = @"";
				passcodeConfirmationWarningLabel.text = @"Passcodes did not match. Try again.";
				[self moveToPreviousTableView];
			} else {
				if ([KKKeychain setString:setPasscodeTextField.text forKey:@"passcode"]) {
					[KKKeychain setString:@"YES" forKey:@"passcode_on"];
				}
				if ([self.delegate respondsToSelector:@selector(didSettingsChanged:)]) {
					[self.delegate performSelector:@selector(didSettingsChanged:) withObject:self];
				}
				[self dismissViewControllerAnimated:YES completion:nil];
			}
		}
	}
	return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        return UIInterfaceOrientationMaskAll;
    }
    return UIInterfaceOrientationMaskPortrait;
}

@end
