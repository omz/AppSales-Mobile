//
//  ReviewsController.h
//  AppSalesMobile
//
//  Created by Ole Zorn on 12.09.09.
//  Copyright 2009 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ReviewsController : UITableViewController {
	NSArray *sortedApps;
	UILabel *statusLabel;
	UIActivityIndicatorView *activityIndicator;
}

- (void)reload;
- (void)markAllAsRead:(id)sender;

@end
