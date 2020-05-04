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

- (void)autoFillWizardWithLogin:(NSDictionary *)loginInfo;
- (void)findProviderIDWithLogin:(NSDictionary *)loginInfo;
- (void)getAccessTokenWithLogin:(NSDictionary *)loginInfo;
- (void)findVendorIDsWithLogin:(NSDictionary *)loginInfo;

@end
