//
//  RootViewController.h
//  PTPasscodeViewControllerDemo
//
//  Created by Lasha Dolidze on 7/7/10.
//  Copyright Picktek LLC 2010. All rights reserved.
//  Distributed under GPL license v 2.x or later	 	
//  http://www.gnu.org/licenses/gpl-2.0.html
//

#import <UIKit/UIKit.h>

#define kPasscodePanelCount        3

#define kPasscodePanelWidth        320.0
#define kPasscodePanelHeight       240.0

#define kPasscodeEntryWidth        60.0
#define kPasscodeEntryHeight       60.0

#define kPasscodePanelTitleTag     10
#define kPasscodePanelSummaryTag   11

#define kPasscodeFakeTextField     12

#define kPasscodePanelOne           0.0
#define kPasscodePanelTwo          -320.0
#define kPasscodePanelThree        -640.0


@protocol PTPasscodeViewControllerDelegate;


@interface PTPasscodeViewController : UIViewController <UITextFieldDelegate> {
    
    UIView *_scrollView;
    UIView *currentPanel;
    
    id<PTPasscodeViewControllerDelegate> _delegate;
    
}
@property (nonatomic, readonly) UILabel *titleLabel;
@property (nonatomic, readonly) UILabel *summaryLabel;

@property (nonatomic, readonly) UIView *currentPanel;
@property (nonatomic,assign) id<PTPasscodeViewControllerDelegate> delegate;

-(id)initWithDelegate:(id)delegate;
- (void)clearPanel;
-(BOOL)prevPanel;
-(BOOL)nextPanel;
@end


@protocol PTPasscodeViewControllerDelegate <NSObject>
@optional
- (BOOL)shouldChangePasscode:(PTPasscodeViewController *)passcodeViewController panelView:(UIView*)panelView passCode:(NSUInteger)passCode lastNumber:(NSInteger)lastNumber;
- (void)didShowPasscodePanel:(PTPasscodeViewController *)passcodeViewController panelView:(UIView*)panelView;
- (BOOL)didEndPasscodeEditing:(PTPasscodeViewController *)passcodeViewController panelView:(UIView*)panelView passCode:(NSUInteger)passCode;

@end