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

#import "KKPasscodeSettingsViewController.h"
#import "KKKeychain.h"
#import "KKPasscodeViewController.h"
#import "KKPasscodeLock.h"
#import "DarkModeCheck.h"

@implementation KKPasscodeSettingsViewController

#pragma mark -
#pragma mark UIViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	self.navigationItem.title = @"Passcode Lock";
	
	unlockWithBiometricsSwitch = [[UISwitch alloc] init];
	[unlockWithBiometricsSwitch addTarget:self action:@selector(unlockWithBiometricsSwitchChanged:) forControlEvents:UIControlEventValueChanged];
	
	eraseDataSwitch = [[UISwitch alloc] init];
	[eraseDataSwitch addTarget:self action:@selector(eraseDataSwitchChanged:) forControlEvents:UIControlEventValueChanged];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	passcodeLockOn = [[KKKeychain getStringForKey:@"passcode_on"] isEqualToString:@"YES"];
	unlockWithBiometricsOn = [[KKKeychain getStringForKey:@"unlock_with_biometrics"] isEqualToString:@"YES"];
	unlockWithBiometricsSwitch.on = unlockWithBiometricsOn;
	eraseDataOn = [[KKKeychain getStringForKey:@"erase_data_on"] isEqualToString:@"YES"];
	eraseDataSwitch.on = eraseDataOn;
}

#pragma mark -

- (void)eraseDataSwitchChanged:(id)sender {
    if (eraseDataSwitch.on) {
        NSString *title = [NSString stringWithFormat:@"All data in this app will be erased after %lu failed passcode attempts.", (unsigned long)[[KKPasscodeLock sharedLock] attemptsAllowed]];
        
        UIAlertController *sheet = [UIAlertController alertControllerWithTitle:title
                                                                       message:nil
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
        
        [sheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                  style:UIAlertActionStyleCancel
                                                handler:^(UIAlertAction * _Nonnull action) {
            self->eraseDataOn = NO;
            [KKKeychain setString:@"NO" forKey:@"erase_data_on"];
            [self->eraseDataSwitch setOn:self->eraseDataOn animated:YES];
        }]];
        
        [sheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Enable", nil)
                                                  style:UIAlertActionStyleDestructive
                                                handler:^(UIAlertAction * _Nonnull action) {
            self->eraseDataOn = YES;
            [KKKeychain setString:@"YES" forKey:@"erase_data_on"];
            [self->eraseDataSwitch setOn:self->eraseDataOn animated:YES];
        }]];
        
        [self presentViewController:sheet animated:YES completion:nil];
    } else {
        eraseDataOn = NO;
        [KKKeychain setString:@"NO" forKey:@"erase_data_on"];
    }
}

- (void)unlockWithBiometricsSwitchChanged:(id)sender {
	unlockWithBiometricsOn = unlockWithBiometricsSwitch.on;
	[KKKeychain setString:(unlockWithBiometricsSwitch.on ? @"YES" : @"NO") forKey:@"unlock_with_biometrics"];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1 + KKPasscodeViewController.hasBiometricAuthentication + [KKPasscodeLock sharedLock].eraseOption;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSInteger numberOfRows = 0;
	if (section == 0) {
		numberOfRows = 2;
	} else {
		numberOfRows = 1;
	}
	return numberOfRows;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	if (section == (1 + KKPasscodeViewController.hasBiometricAuthentication)) {
		return [NSString stringWithFormat:@"Erase all data in this app after %lu failed passcode attempts.", (unsigned long)[[KKPasscodeLock sharedLock] attemptsAllowed]];;
	}
	return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"Cell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
	}
	
	if (indexPath.section == 0) {
		if (indexPath.row == 0) {
			if (passcodeLockOn) {
				cell.textLabel.text = @"Turn Passcode Off";
			} else {
				cell.textLabel.text = @"Turn Passcode On";
			}
            if (@available(iOS 13.0, *)) {
                cell.textLabel.textColor = [UIColor labelColor];
            } else {
                cell.textLabel.textColor = [UIColor blackColor];
            }
			cell.textLabel.textAlignment = NSTextAlignmentCenter;
			cell.accessoryView = nil;
			cell.selectionStyle = UITableViewCellSelectionStyleDefault;
		} else if (indexPath.row == 1) {
			cell.textLabel.text = @"Change Passcode";
			if (passcodeLockOn) {
				if (@available(iOS 13.0, *)) {
                    cell.textLabel.textColor = [UIColor labelColor];
                } else {
                    cell.textLabel.textColor = [UIColor blackColor];
                }
				cell.selectionStyle = UITableViewCellSelectionStyleDefault;
			} else {
				if (@available(iOS 13.0, *)) {
                    cell.textLabel.textColor = [UIColor secondaryLabelColor];
                } else {
                    cell.textLabel.textColor = [UIColor grayColor];
                }
				cell.selectionStyle = UITableViewCellSelectionStyleNone;
			}
			cell.textLabel.textAlignment = NSTextAlignmentCenter;
			cell.accessoryView = nil;
		}
	} else if (indexPath.section == KKPasscodeViewController.hasBiometricAuthentication) {
		cell.textLabel.text = [NSString stringWithFormat:@"Unlock with %@", KKPasscodeViewController.biometryTypeString];
		cell.textLabel.textAlignment = NSTextAlignmentLeft;
		cell.accessoryView = unlockWithBiometricsSwitch;
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		unlockWithBiometricsSwitch.enabled = passcodeLockOn;
		if (passcodeLockOn) {
			if (@available(iOS 13.0, *)) {
                cell.textLabel.textColor = [UIColor labelColor];
            } else {
                cell.textLabel.textColor = [UIColor blackColor];
            }
		} else {
			if (@available(iOS 13.0, *)) {
                cell.textLabel.textColor = [UIColor labelColor];
            } else {
                cell.textLabel.textColor = [UIColor grayColor];
            }
		}
	} else if (indexPath.section == (1 + KKPasscodeViewController.hasBiometricAuthentication)) {
		cell.textLabel.text = @"Erase Data";
		cell.textLabel.textAlignment = NSTextAlignmentLeft;
		cell.accessoryView = eraseDataSwitch;
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		eraseDataSwitch.enabled = passcodeLockOn;
		if (passcodeLockOn) {
            if (@available(iOS 13.0, *)) {
                cell.textLabel.textColor = [UIColor labelColor];
            } else {
                cell.textLabel.textColor = [UIColor blackColor];
            }
        } else {
            if (@available(iOS 13.0, *)) {
                cell.textLabel.textColor = [UIColor labelColor];
            } else {
                cell.textLabel.textColor = [UIColor grayColor];
            }
        }
	}
	
	return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0) {
		if (indexPath.row == 0) {
			KKPasscodeViewController *vc = [[KKPasscodeViewController alloc] init];
			vc.delegate = self;
			
			if (passcodeLockOn) {
				vc.mode = KKPasscodeModeDisabled;
				vc.startBiometricAuthentication = YES;
			} else {
				vc.mode = KKPasscodeModeSet;
			}
			
			UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
		 
			if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
				nav.modalPresentationStyle = UIModalPresentationFormSheet;
				nav.navigationBar.barStyle = UIBarStyleBlack;
				nav.navigationBar.opaque = NO;
			} else {
				nav.navigationBar.tintColor = self.navigationController.navigationBar.tintColor;
				nav.navigationBar.translucent = self.navigationController.navigationBar.translucent;
				nav.navigationBar.opaque = self.navigationController.navigationBar.opaque;
				nav.navigationBar.barStyle = self.navigationController.navigationBar.barStyle;
			}
			
			[self.navigationController presentViewController:nav animated:YES completion:nil];
		} else if (indexPath.row == passcodeLockOn) {
			KKPasscodeViewController *vc = [[KKPasscodeViewController alloc] init];
			vc.delegate = self;
			
			vc.mode = KKPasscodeModeChange;
			
			UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
			
			
			if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
				nav.modalPresentationStyle = UIModalPresentationFormSheet;
				nav.navigationBar.barStyle = UIBarStyleBlack;
				nav.navigationBar.opaque = NO;
			} else {
				nav.navigationBar.tintColor = self.navigationController.navigationBar.tintColor;
				nav.navigationBar.translucent = self.navigationController.navigationBar.translucent;
				nav.navigationBar.opaque = self.navigationController.navigationBar.opaque;
				nav.navigationBar.barStyle = self.navigationController.navigationBar.barStyle;
			}
			
			[self.navigationController presentViewController:nav animated:YES completion:nil];
		}
	}
}

- (void)didSettingsChanged:(KKPasscodeViewController *)viewController  {
	passcodeLockOn = [[KKKeychain getStringForKey:@"passcode_on"] isEqualToString:@"YES"];
	unlockWithBiometricsOn = [[KKKeychain getStringForKey:@"unlock_with_biometrics"] isEqualToString:@"YES"];
	unlockWithBiometricsSwitch.on = unlockWithBiometricsOn;
	eraseDataOn = [[KKKeychain getStringForKey:@"erase_data_on"] isEqualToString:@"YES"];
	eraseDataSwitch.on = eraseDataOn;
	
	[self.tableView reloadData];
	
	if ([_delegate respondsToSelector:@selector(didSettingsChanged:)]) {
		[_delegate performSelector:@selector(didSettingsChanged:) withObject:self];
	}
	
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        return UIInterfaceOrientationMaskAll;
    }
    return UIInterfaceOrientationMaskPortrait;
}

@end
