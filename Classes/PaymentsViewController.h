//
//  PaymentsViewController.h
//  AppSales
//
//  Created by Ole Zorn on 31.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ASAccount;

@interface PaymentsViewController : UIViewController <UIScrollViewDelegate, UIActionSheetDelegate> {
	
	ASAccount *account;
	UIScrollView *scrollView;
	UIPageControl *pageControl;
}

- (id)initWithAccount:(ASAccount *)paymentAccount;

@property (nonatomic, retain) UIScrollView *scrollView;
@property (nonatomic, retain) UIPageControl *pageControl;

@end
