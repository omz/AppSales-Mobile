//
//  PaymentDetailsViewController.h
//  AppSales
//
//  Created by Duncan Cunningham on 10/10/20.
//  Copyright © 2020 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PaymentDetailsViewController;

@interface PaymentDetailsViewController : UITableViewController {
	NSArray *paymentDetails;
	NSDateFormatter *dateFormatter;
	NSNumberFormatter *numberFormatter;
	id<PaymentDetailsViewController> __weak delegate;
}

@property (nonatomic, weak) id<PaymentDetailsViewController> delegate;

- (instancetype)initWithPaymentDetails:(NSArray *)details;

@end

@protocol PaymentDetailsViewController <NSObject>

- (void)paymentDetailsViewController:(PaymentDetailsViewController *)paymentDetailsViewController didDeletePaymentDetails:(NSManagedObject *)paymentDetails;

@end

NS_ASSUME_NONNULL_END
