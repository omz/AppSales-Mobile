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

@interface SecurityCodeInputController : UITableViewController <UITextFieldDelegate> {
	UITextField *securityCodeField;
	
	UIView *digitView;
	UILabel *digit1;
	UILabel *digit2;
	UILabel *digit3;
	UILabel *digit4;
	NSMutableArray *digits;
	
	NSLayoutConstraint *digitViewCenterYConstraint;
}

@property (nonatomic, strong) id<SecurityCodeInputControllerDelegate> delegate;

- (void)show;

@end
