//
//  ReviewsPane.h
//  AppSalesMobile
//
//  Created by Ole Zorn on 06.04.10.
//  Copyright 2010 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ReviewsPaneController : UIViewController {
	UIScrollView *scrollView;
	UILabel *statusLabel;
	UIActivityIndicatorView *activityIndicator;
    UIPopoverController *currentPopover; // required to keep popover from autoreleasing
}

@property (nonatomic, retain) UIScrollView *scrollView;
@property (nonatomic, retain) UILabel *statusLabel;
@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;

- (void)reload;

@end
