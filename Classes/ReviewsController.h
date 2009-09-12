//
//  ReviewsController.h
//  AppSalesMobile
//
//  Created by Ole Zorn on 12.09.09.
//  Copyright 2009 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ReviewsController : UITableViewController <UIActionSheetDelegate> {

	NSArray *sortedApps;
	UILabel *statusLabel;
	UIActivityIndicatorView *activityIndicator;
}

@property (nonatomic, retain) NSArray *sortedApps;
@property (nonatomic, retain) UILabel *statusLabel;
@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;

- (void)reload;

@end
