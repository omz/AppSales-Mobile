//
//  StatisticsViewController.h
//  AppSalesMobile
//
//  Created by Ole Zorn on 15.02.09.
//  Copyright 2009 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TrendGraphView;
@class RegionsGraphView;

@interface StatisticsViewController : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource, UIAlertViewDelegate, UIScrollViewDelegate> {
	UIScrollView *scrollView;
	UIPageControl *pageControl;
	TrendGraphView *allAppsTrendView;
	RegionsGraphView *regionsGraphView;
	NSMutableArray *trendViewsForApps;
	NSArray *selectedDays;
	UIPickerView *datePicker;
	NSArray *days;
	UIBarButtonItem *graphModeButton;
	
	// To be used when scrolls originate from the UIPageControl
	BOOL pageControlUsed;
}

@property (retain) NSArray *days;
@property (retain) NSArray *selectedDays;
@property (retain) TrendGraphView *allAppsTrendView;
@property (retain) RegionsGraphView *regionsGraphView;
@property (retain) NSMutableArray *trendViewsForApps;
@property (retain) UIScrollView *scrollView;
@property (nonatomic, retain) UIPageControl *pageControl;
@property (retain) UIPickerView *datePicker;

- (void)reloadDays;
- (void)reload;
- (void)updateGraphModeButton;

@end
