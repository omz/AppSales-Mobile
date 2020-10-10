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

@class LoginManager;

extern NSString *const kITCBaseURL;
extern NSString *const kITCPaymentVendorsAction;
extern NSString *const kITCPaymentVendorsPaymentAction;

@protocol LoginManagerDelegate <NSObject>

@required
- (void)loginSucceeded:(LoginManager *)loginManager;
- (void)loginFailed:(LoginManager *)loginManager;

@end

@interface LoginManager : NSObject <SecurityCodeInputControllerDelegate> {
	ASAccount *account;
	NSDictionary *loginInfo;
	NSMutableArray *availableProviders;
	NSDictionary *provider;
	NSString *providerID;
	NSMutableArray *trustedDevices;
	NSString *appleAuthSessionId;
	NSString *appleAuthScnt;
	NSString *appleAuthTrustedDeviceId;
	SCInputType authType;
	NSDateFormatter *dateFormatter;
}

@property (nonatomic, strong) id<LoginManagerDelegate> delegate;
@property (nonatomic, assign) BOOL shouldDeleteCookies;

- (instancetype)initWithAccount:(ASAccount *)_account;
- (instancetype)initWithLoginInfo:(NSDictionary *)_loginInfo;
- (void)logIn;
- (void)logOut;

- (NSString *)providerID;
- (void)generateCSRFTokenWithCompletionBlock:(void(^)(NSString *csrfToken))completionBlock;
- (NSDictionary *)getAccessKey:(NSString *)csrfToken;
- (NSDictionary *)resetAccessKey:(NSString *)csrfToken;

@end
