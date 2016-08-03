//
//  SecurityCodeInputController.h
//  AppSales
//
//  Created by Nicolas Gomollon on 12/1/15.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol SecurityCodeInputControllerDelegate <NSObject>

@required
- (void)securityCodeInputSubmitted:(NSString *)securityCode;
- (void)securityCodeInputCanceled;

@end

typedef NS_ENUM(NSUInteger, SCInputType) {
	SCInputTypeUnknown = 0,
	SCInputTypeTwoStepVerificationCode = 1,
	SCInputTypeTwoFactorAuthenticationCode = 2
};

@interface SecurityCodeInputController : UITableViewController <UITextFieldDelegate> {
	SCInputType inputType;
	UITextField *securityCodeField;
	
	UIView *digitView;
	UILabel *digit1;
	UILabel *digit2;
	UILabel *digit3;
	UILabel *digit4;
	UILabel *digit5;
	UILabel *digit6;
	NSMutableArray *digits;
	
	NSLayoutConstraint *digitViewCenterYConstraint;
}

@property (nonatomic, strong) id<SecurityCodeInputControllerDelegate> delegate;

- (instancetype)initWithType:(SCInputType)_inputType;
- (void)show;

@end
