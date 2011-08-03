//
//  ReportDetailViewController.h
//  AppSales
//
//  Created by Ole Zorn on 21.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Report, Product, MapView, AppIconView;
@protocol ReportSummary;

typedef enum ReportDetailViewMode { 
	ReportDetailViewModeCountries = 0,
	ReportDetailViewModeProducts
} ReportDetailViewMode;

@interface ReportDetailViewController : UIViewController <UITableViewDataSource, UITableViewDelegate> {

	NSArray *reports;
	id<ReportSummary> selectedReport;
	NSUInteger selectedReportIndex;
	
	ReportDetailViewMode viewMode;
	NSArray *countryEntries;
	NSArray *productEntries;
	
	NSString *selectedCountry;
	Product *selectedProduct;
	
	BOOL mapHidden;
	MapView *mapView;
	UIImageView *shadowView;
	UIImageView *mapShadowView;
	UITableView *tableView;
	UIBarButtonItem *prevItem;
	UIBarButtonItem *nextItem;
	
	UIImageView *headerView;
	UILabel *headerLabel;
	AppIconView *headerIconView;
	UIToolbar *toolbar;
	
	NSNumberFormatter *revenueFormatter;
}

@property (nonatomic, retain) NSArray *countryEntries;
@property (nonatomic, retain) NSArray *productEntries;
@property (nonatomic, retain) id<ReportSummary> selectedReport;
@property (nonatomic, assign) NSUInteger selectedReportIndex;
@property (nonatomic, retain) MapView *mapView;
@property (nonatomic, retain) UIImageView *mapShadowView;
@property (nonatomic, retain) UIImageView *shadowView;
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) UIBarButtonItem *prevItem;
@property (nonatomic, retain) UIBarButtonItem *nextItem;
@property (nonatomic, retain) UIImageView *headerView;
@property (nonatomic, retain) UILabel *headerLabel;
@property (nonatomic, retain) AppIconView *headerIconView;
@property (nonatomic, retain) NSString *selectedCountry;
@property (nonatomic, retain) Product *selectedProduct;
@property (nonatomic, retain) UIToolbar *toolbar;

- (id)initWithReports:(NSArray *)reportsArray selectedIndex:(NSInteger)selectedIndex;
- (void)updateNavigationButtons;
- (void)updateHeader;
- (void)reloadData;
- (void)reloadTableView;
- (void)toggleMap:(id)sender;

@end


