//
//  AccountStatusView.h
//  AppSales
//
//  Created by Ole Zorn on 03.08.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Account;

@interface AccountStatusView : UIView {
	
	Account *account;
	UIActivityIndicatorView *activityIndicator;
	UILabel *statusLabel;
}

- (id)initWithFrame:(CGRect)frame account:(Account *)anAccount;
- (void)updateStatus;

@end
