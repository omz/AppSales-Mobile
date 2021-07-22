//
//  SalesViewController.h
//  AppSales
//
//  Created by Ole Zorn on 30.06.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GraphView.h"
#import "DashboardViewController.h"

@class ASAccount, Report, Product;
@protocol ReportSummary;

typedef NS_ENUM(NSInteger, DashboardViewMode) {
	DashboardViewModeRevenue = 0,
	DashboardViewModeSales,
	DashboardViewModeUpdates,
	DashboardViewModeRedownloads,
	DashboardViewModeEducationalSales,
	DashboardViewModeGiftPurchases,
	DashboardViewModePromoCodes,
	DashboardViewModeTotalRevenue,
	DashboardViewModeTotalSales
};

@interface SalesViewController : DashboardViewController <GraphViewDelegate, GraphViewDataSource> {
	NSCalendar *calendar;
	NSDateFormatter *dateFormatter;
	NSNumberFormatter *numberFormatter;
	
	UIInterfaceOrientation previousOrientation;
	DashboardViewMode viewMode;
	BOOL showNumberOfSales;
	BOOL showFiscalMonths;
	BOOL showWeeks;
	NSInteger selectedTab;
	
	GraphView *graphView;
	
	NSMutableArray *sortedDailyReports;
	NSMutableArray *sortedWeeklyReports;
	NSMutableArray *sortedCalendarMonthReports;
	NSMutableArray *sortedFiscalMonthReports;
	
	UIBarButtonItem *downloadReportsButtonItem;
	
	UIPopoverController *selectedReportPopover;
}

@property (nonatomic, strong) NSMutableArray *sortedDailyReports;
@property (nonatomic, strong) NSMutableArray *sortedWeeklyReports;
@property (nonatomic, strong) NSMutableArray *sortedCalendarMonthReports;
@property (nonatomic, strong) NSMutableArray *sortedFiscalMonthReports;
@property (nonatomic, assign) DashboardViewMode viewMode;
@property (nonatomic, strong) GraphView *graphView;
@property (nonatomic, strong) UIBarButtonItem *downloadReportsButtonItem;
@property (nonatomic, strong) UIPopoverController *selectedReportPopover;

@end
