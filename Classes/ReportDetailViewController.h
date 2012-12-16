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

@property (nonatomic, strong) NSArray *countryEntries;
@property (nonatomic, strong) NSArray *productEntries;
@property (nonatomic, strong) id<ReportSummary> selectedReport;
@property (nonatomic, assign) NSUInteger selectedReportIndex;
@property (nonatomic, strong) MapView *mapView;
@property (nonatomic, strong) UIImageView *mapShadowView;
@property (nonatomic, strong) UIImageView *shadowView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIBarButtonItem *prevItem;
@property (nonatomic, strong) UIBarButtonItem *nextItem;
@property (nonatomic, strong) UIImageView *headerView;
@property (nonatomic, strong) UILabel *headerLabel;
@property (nonatomic, strong) AppIconView *headerIconView;
@property (nonatomic, strong) NSString *selectedCountry;
@property (nonatomic, strong) Product *selectedProduct;
@property (nonatomic, strong) UIToolbar *toolbar;

- (id)initWithReports:(NSArray *)reportsArray selectedIndex:(NSInteger)selectedIndex;
- (void)updateNavigationButtons;
- (void)updateHeader;
- (void)reloadData;
- (void)reloadTableView;
- (void)toggleMap:(id)sender;

@end


