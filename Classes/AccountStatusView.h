//
//  AccountStatusView.h
//  AppSales
//
//  Created by Ole Zorn on 03.08.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ASAccount;

@interface AccountStatusView : UIView {
	
	ASAccount *account;
	UIActivityIndicatorView *activityIndicator;
	UILabel *statusLabel;
}

- (id)initWithFrame:(CGRect)frame account:(ASAccount *)anAccount;
- (void)updateStatus;

@end
