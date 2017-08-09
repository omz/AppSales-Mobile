//
//  AccountsViewController+ButtonActions.h
//  AppSales
//
//  Created by Nicolas Gomollon on 8/9/17.
//
//

#import "AccountsViewController.h"
#import "LoginManager.h"

@interface AccountsViewController (AccountsViewController_ButtonActions) <LoginManagerDelegate>

- (void)getAccessTokenWithLogin:(NSDictionary *)loginInfo;
- (void)generateAccessTokenWithLogin:(NSDictionary *)loginInfo;
- (void)findVendorIDsWithLogin:(NSDictionary *)loginInfo;

@end
