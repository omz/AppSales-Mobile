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

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, KKPasscodeMode) {
	KKPasscodeModeEnter = 0,
	KKPasscodeModeSet = 1,
	KKPasscodeModeDisabled = 2,
	KKPasscodeModeChange = 3
};

@class KKPasscodeViewController;

@protocol KKPasscodeViewControllerDelegate <NSObject>

@optional
- (void)didPasscodeEnteredCorrectly:(KKPasscodeViewController *)viewController;
- (void)didPasscodeEnteredIncorrectly:(KKPasscodeViewController *)viewController;
- (void)shouldEraseApplicationData:(KKPasscodeViewController *)viewController;
- (void)didSettingsChanged:(KKPasscodeViewController *)viewController;

@end

@interface KKPasscodeViewController : UIViewController <UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource> {
	UILabel *passcodeConfirmationWarningLabel;
	UIView *failedAttemptsView;
	UILabel *failedAttemptsLabel;
	NSInteger failedAttemptsCount;
	
	NSUInteger tableIndex;
	NSMutableArray *tableViews;
	NSMutableArray *textFields;
	NSMutableArray *squares;
	
	UITableView *enterPasscodeTableView;
	UITextField *enterPasscodeTextField;
	NSArray *enterPasscodeSquareImageViews;
	
	UITableView *setPasscodeTableView;
	UITextField *setPasscodeTextField;
	NSArray *setPasscodeSquareImageViews;
	
	UITableView *confirmPasscodeTableView;
	UITextField *confirmPasscodeTextField;
	NSArray *confirmPasscodeSquareImageViews;
	
	BOOL passcodeLockOn;
	BOOL eraseData;
}

@property (nonatomic, weak) id <KKPasscodeViewControllerDelegate> delegate; 
@property (nonatomic, assign) KKPasscodeMode mode;
@property (nonatomic, assign) BOOL startTouchID;

+ (BOOL)hasTouchID;
- (void)authenticateWithTouchID;

@end
