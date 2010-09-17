//
//  PadRootViewController.h
//  AppSalesMobile
//
//  Created by Ole Zorn on 05.04.10.
//  Copyright 2010 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DashboardViewController, ReviewsPaneController, CalculatorView;

@interface PadRootViewController : UIViewController <UIActionSheetDelegate> {

	UIToolbar *toolbar;
	UILabel *statusLabel;
	UIActivityIndicatorView *activityIndicator;
	UIPopoverController *settingsPopover;
	UIPopoverController *importExportPopover;
	UIPopoverController *aboutPopover;
	UIActionSheet *graphTypeSheet;
	UIBarButtonItem *filterItem;
	UIActionSheet *filterSheet;
	
	DashboardViewController *dailyDashboardView;
	DashboardViewController *weeklyDashboardView;
	ReviewsPaneController *reviewsPane;
	
	CalculatorView *calculator;
}

@property (nonatomic, retain) UIToolbar *toolbar;
@property (nonatomic, retain) UILabel *statusLabel;
@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, retain) UIPopoverController *settingsPopover;
@property (nonatomic, retain) UIPopoverController *importExportPopover;
@property (nonatomic, retain) UIPopoverController *aboutPopover;
@property (nonatomic, retain) UIActionSheet *graphTypeSheet;
@property (nonatomic, retain) UIBarButtonItem *filterItem;
@property (nonatomic, retain) UIActionSheet *filterSheet;
@property (nonatomic, retain) DashboardViewController *dailyDashboardView;
@property (nonatomic, retain) DashboardViewController *weeklyDashboardView;
@property (nonatomic, retain) ReviewsPaneController *reviewsPane;

@end
