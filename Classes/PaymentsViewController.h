//
//  PaymentsViewController.h
//  AppSales
//
//  Created by Ole Zorn on 31.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Account;

@interface PaymentsViewController : UIViewController <UIScrollViewDelegate> {
	
	Account *account;
	UIScrollView *scrollView;
	UIPageControl *pageControl;
}

- (id)initWithAccount:(Account *)paymentAccount;

@property (nonatomic, retain) UIScrollView *scrollView;
@property (nonatomic, retain) UIPageControl *pageControl;

@end
