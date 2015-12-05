//
//  AccountsViewController+VendorID.h
//  AppSales
//
//  Created by Ole Zorn on 24.08.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "AccountsViewController.h"
#import "LoginManager.h"

@interface AccountsViewController (AccountsViewController_VendorID) <LoginManagerDelegate>

- (void)findVendorIDsWithLogin:(NSDictionary *)loginInfo;

@end
