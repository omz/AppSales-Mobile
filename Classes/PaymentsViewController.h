//
//  PaymentsViewController.h
//  AppSales
//
//  Created by Ole Zorn on 31.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ASAccount;

@interface PaymentsViewController : UIViewController <UIScrollViewDelegate> {
	ASAccount *account;
	UIScrollView *scrollView;
	UIPageControl *pageControl;
}

- (instancetype)initWithAccount:(ASAccount *)paymentAccount;
- (void)reloadData;

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIPageControl *pageControl;

@end
