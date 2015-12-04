//
//  ReviewsViewController.h
//  AppSales
//
//  Created by Ole Zorn on 30.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "DashboardViewController.h"
#import "ReviewSummaryView.h"

@interface ReviewsViewController : DashboardViewController <ReviewSummaryViewDataSource, ReviewSummaryViewDelegate> {

	ReviewSummaryView *reviewSummaryView;
	UIBarButtonItem *downloadReviewsButtonItem;
	UIPopoverController *reviewsPopover;
}

@property (nonatomic, strong) ReviewSummaryView *reviewSummaryView;
@property (nonatomic, strong) UIPopoverController *reviewsPopover;

@end
