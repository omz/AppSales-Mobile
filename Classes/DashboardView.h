//
//  DashboardView.h
//  AppSalesMobile
//
//  Created by Ole Zorn on 05.04.10.
//  Copyright 2010 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DashboardGraphView;

@interface DashboardView : UIView <UIPickerViewDelegate, UIPickerViewDataSource, UIActionSheetDelegate> {

	UIPickerView *dateRangePicker;
	NSArray *reports;
	DashboardGraphView *graphView;
	UIPopoverController *reportsPopover;
	
	BOOL shouldAutomaticallyShowNewReports;
	BOOL showsWeeklyReports;
	
	UIButton *viewReportsButton;
	UIButton *calendarButton;
}

@property (nonatomic, retain) UIPickerView *dateRangePicker;
@property (nonatomic, retain) NSArray *reports;
@property (nonatomic, retain) DashboardGraphView *graphView;
@property (nonatomic, retain) UIPopoverController *reportsPopover;
@property (nonatomic, assign) BOOL showsWeeklyReports;
@property (nonatomic, retain) UIButton *viewReportsButton;
@property (nonatomic, retain) UIButton *calendarButton;

- (void)resetDatePicker;
- (void)reloadData;

@end
