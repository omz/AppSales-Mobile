//
//  PaymentsViewController.h
//  AppSales
//
//  Created by Ole Zorn on 31.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PaymentDetailsViewController.h"
#import "YearView.h"

@class ASAccount;
@protocol PaymentViewControllerDelegate;

@interface PaymentsViewController : UIViewController <UIScrollViewDelegate, UIActionSheetDelegate, YearViewDelegate, PaymentDetailsViewController> {
	ASAccount *account;
	NSMutableDictionary *paymentsByYear;
	UIScrollView *scrollView;
	UIPageControl *pageControl;
	NSDateFormatter *dateFormatter;
	id<PaymentViewControllerDelegate> __weak delegate;
}

- (instancetype)initWithAccount:(ASAccount *)paymentAccount;
- (void)reloadData;

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic, weak) id<PaymentViewControllerDelegate> delegate;

@end

@protocol PaymentViewControllerDelegate <NSObject>

- (void)paymentViewController:(PaymentsViewController *)paymentViewController didDeletePaymentDetail:(NSManagedObject *)paymentDetail;

@end
