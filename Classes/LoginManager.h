//
//  LoginManager.h
//  AppSales
//
//  Created by Nicolas Gomollon on 12/1/15.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ASAccount.h"
#import "SecurityCodeInputController.h"

extern NSString *const kITCBaseURL;
extern NSString *const kITCUserDetailAction;
extern NSString *const kITCPaymentVendorsAction;
extern NSString *const kITCPaymentVendorsPaymentAction;

static NSString *NSStringPercentEscaped(NSString *string) {
	return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)string, NULL, CFSTR("!*'();:@&=+$,/?%#[]"), kCFStringEncodingUTF8));
}

@protocol LoginManagerDelegate <NSObject>

@required
- (void)loginSucceeded;
- (void)loginFailed;

@end

@interface LoginManager : NSObject <SecurityCodeInputControllerDelegate> {
	ASAccount *account;
	NSDictionary *loginInfo;
	NSMutableArray *trustedDevices;
	NSString *appleAuthSessionId;
	NSString *appleAuthScnt;
	NSString *appleAuthTrustedDeviceId;
	UIActionSheet *verifyActionSheet;
	SCInputType authType;
}

@property (nonatomic, strong) id<LoginManagerDelegate> delegate;
@property (nonatomic, assign) BOOL shouldDeleteCookies;

- (instancetype)initWithAccount:(ASAccount *)_account;
- (instancetype)initWithLoginInfo:(NSDictionary *)_loginInfo;
- (void)logIn;
- (void)logOut;

@end
