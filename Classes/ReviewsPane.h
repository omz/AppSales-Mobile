//
//  ReviewsPane.h
//  AppSalesMobile
//
//  Created by Ole Zorn on 06.04.10.
//  Copyright 2010 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ReviewsPane : UIView <UIActionSheetDelegate> {

	UIScrollView *scrollView;
	UILabel *statusLabel;
	UIActivityIndicatorView *activityIndicator;
	
	UIPopoverController *reviewsPopover;
}

@property (nonatomic, retain) UIScrollView *scrollView;
@property (nonatomic, retain) UILabel *statusLabel;
@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, retain) UIPopoverController *reviewsPopover;

- (void)reload;

@end
