//
//  DashboardViewController.m
//  AppSales
//
//  Created by Ole Zorn on 30.06.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "SalesViewController.h"
#import "ReportDownloadCoordinator.h"
#import "ASAccount.h"
#import "Report.h"
#import "ReportCollection.h"
#import "ReportSummary.h"
#import "Product.h"
#import "CurrencyManager.h"
#import "DashboardAppCell.h"
#import "ColorButton.h"
#import "UIColor+Extensions.h"
#import "ReportDetailViewController.h"
#import "AppleFiscalCalendar.h"

#define kSheetTagDailyGraphOptions		1
#define kSheetTagMonthlyGraphOptions	2
#define kSheetTagAdvancedViewMode		3

@interface SalesViewController ()

- (NSArray *)stackedValuesForReport:(id<ReportSummary>)report;

@end

@implementation SalesViewController

@synthesize sortedDailyReports, sortedWeeklyReports, sortedCalendarMonthReports, sortedFiscalMonthReports, viewMode;
@synthesize graphView, downloadReportsButtonItem;

- (id)initWithAccount:(ASAccount *)anAccount
{
	self = [super initWithAccount:anAccount];
	if (self) {
		previousOrientation = UIInterfaceOrientationPortrait;
		sortedDailyReports = [NSMutableArray new];
		sortedWeeklyReports = [NSMutableArray new];
		sortedCalendarMonthReports = [NSMutableArray new];
		sortedFiscalMonthReports = [NSMutableArray new];
		
		calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
		[calendar setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
		
		[account addObserver:self forKeyPath:@"isDownloadingReports" options:NSKeyValueObservingOptionNew context:nil];
		[account addObserver:self forKeyPath:@"downloadStatus" options:NSKeyValueObservingOptionNew context:nil];
		[account addObserver:self forKeyPath:@"downloadProgress" options:NSKeyValueObservingOptionNew context:nil];
		
		selectedTab = [[NSUserDefaults standardUserDefaults] integerForKey:kSettingDashboardSelectedTab];
		showFiscalMonths = [[NSUserDefaults standardUserDefaults] boolForKey:kSettingShowFiscalMonths];
		showWeeks = [[NSUserDefaults standardUserDefaults] boolForKey:kSettingDashboardShowWeeks];
	}
	return self;
}

- (void)loadView
{
	[super loadView];
	
	self.viewMode = [[NSUserDefaults standardUserDefaults] integerForKey:kSettingDashboardViewMode];
	
	self.graphView = [[[GraphView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 208)] autorelease];
	graphView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	graphView.delegate = self;
	graphView.dataSource = self;
	[graphView setUnit:(viewMode != DashboardViewModeRevenue) ? @"" : [[CurrencyManager sharedManager] baseCurrencyDescription]];
	[graphView.sectionLabelButton addTarget:self action:@selector(showGraphOptions:) forControlEvents:UIControlEventTouchUpInside];
	[graphView setNumberOfBarsPerPage:7];
	[self.topView addSubview:graphView];
	
	NSArray *segments = [NSArray arrayWithObjects:NSLocalizedString(@"Reports", nil), NSLocalizedString(@"Months", nil), nil];
	UISegmentedControl *tabControl = [[[UISegmentedControl alloc] initWithItems:segments] autorelease];
	tabControl.segmentedControlStyle = UISegmentedControlStyleBar;
	[tabControl addTarget:self action:@selector(switchTab:) forControlEvents:UIControlEventValueChanged];
	tabControl.selectedSegmentIndex = selectedTab;
	self.navigationItem.titleView = tabControl;
	
	self.downloadReportsButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh 
																				  target:self 
																				  action:@selector(downloadReports:)] autorelease];
	downloadReportsButtonItem.enabled = !self.account.isDownloadingReports;
	self.navigationItem.rightBarButtonItem = downloadReportsButtonItem;
	if ([self shouldShowStatusBar]) {
		self.statusLabel.text = self.account.downloadStatus;
		self.progressBar.progress = self.account.downloadProgress;
	}
}

- (BOOL)shouldShowStatusBar
{
	return self.account.isDownloadingReports;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	[self reloadData];
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	self.graphView = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	if (self.interfaceOrientation != previousOrientation) {
		[self willAnimateRotationToInterfaceOrientation:self.interfaceOrientation duration:0.0];
	}
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	self.account.reportsBadge = [NSNumber numberWithInteger:0];
	if ([self.account.managedObjectContext hasChanges]) {
		[self.account.managedObjectContext save:NULL];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(interfaceOrientation) || interfaceOrientation == UIInterfaceOrientationPortrait;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
		self.graphView.frame = self.view.bounds;
		self.topView.frame = self.view.bounds;
		self.productsTableView.alpha = 0.0;
		[self.graphView reloadValuesAnimated:NO];
	} else {
		self.graphView.frame = CGRectMake(0, 0, self.view.bounds.size.width, 208);
		self.topView.frame = CGRectMake(0, 0, self.view.bounds.size.width, 208);
		self.productsTableView.alpha = 1.0;
		[self.graphView reloadValuesAnimated:NO];
	}
	previousOrientation = toInterfaceOrientation;
}

- (NSSet *)entityNamesTriggeringReload
{
	return [NSSet setWithObjects:@"DailyReport", @"WeeklyReport", @"Product", nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualToString:@"isDownloadingReports"]) {
		self.downloadReportsButtonItem.enabled = !self.account.isDownloadingReports;
		[self showOrHideStatusBar];
	} else if ([keyPath isEqualToString:@"downloadStatus"] || [keyPath isEqualToString:@"downloadProgress"]) {
		progressBar.progress = self.account.downloadProgress;
		statusLabel.text = self.account.downloadStatus;
	}
}

- (void)reloadData
{
	[super reloadData];
	[sortedDailyReports removeAllObjects];
	[sortedWeeklyReports removeAllObjects];
	
	NSArray *sortDescriptors = [NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"startDate" ascending:YES] autorelease]];
	NSSet *allDailyReports = self.account.dailyReports;
	[sortedDailyReports addObjectsFromArray:[allDailyReports allObjects]];
	[sortedDailyReports sortUsingDescriptors:sortDescriptors];
	
	NSSet *allWeeklyReports = self.account.weeklyReports;
	[sortedWeeklyReports addObjectsFromArray:[allWeeklyReports allObjects]];
	[sortedWeeklyReports sortUsingDescriptors:sortDescriptors];
	
	// Group daily reports by calendar month:
	NSDateFormatter *monthFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[monthFormatter setDateFormat:@"MMMM yyyy"];
	[sortedCalendarMonthReports removeAllObjects];
	NSDateComponents *prevDateComponents = nil;
	NSMutableArray *reportsInCurrentMonth = nil;
	for (Report *dailyReport in sortedDailyReports) {
		NSDateComponents *dateComponents = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit fromDate:dailyReport.startDate];
		if (!prevDateComponents || (dateComponents.month != prevDateComponents.month || dateComponents.year != prevDateComponents.year)) {
			if (reportsInCurrentMonth) {
				ReportCollection *monthCollection = [[[ReportCollection alloc] initWithReports:reportsInCurrentMonth] autorelease];
				monthCollection.title = [monthFormatter stringFromDate:dailyReport.startDate];
				[sortedCalendarMonthReports addObject:monthCollection];
			}
			reportsInCurrentMonth = [NSMutableArray array];
		}
		[reportsInCurrentMonth addObject:dailyReport];
		prevDateComponents = dateComponents;
	}
	if ([reportsInCurrentMonth count] > 0) {
		ReportCollection *monthCollection = [[[ReportCollection alloc] initWithReports:reportsInCurrentMonth] autorelease];
		monthCollection.title = [monthFormatter stringFromDate:[monthCollection firstReport].startDate];
		[sortedCalendarMonthReports addObject:monthCollection];
	}
	
	// Group daily reports by fiscal month:
	[sortedFiscalMonthReports removeAllObjects];
	NSString *prevFiscalMonthName = nil;
	NSMutableArray *reportsInCurrentFiscalMonth = nil;
	for (Report *dailyReport in sortedDailyReports) {
		NSString *fiscalMonth = [[AppleFiscalCalendar sharedFiscalCalendar] fiscalMonthForDate:dailyReport.startDate];
		if (![fiscalMonth isEqualToString:prevFiscalMonthName]) {
			if (reportsInCurrentFiscalMonth) {
				ReportCollection *fiscalMonthCollection = [[[ReportCollection alloc] initWithReports:reportsInCurrentFiscalMonth] autorelease];
				[sortedFiscalMonthReports addObject:fiscalMonthCollection];
				fiscalMonthCollection.title = fiscalMonth;
			}
			reportsInCurrentFiscalMonth = [NSMutableArray array];
		}
		[reportsInCurrentFiscalMonth addObject:dailyReport];
		prevFiscalMonthName = fiscalMonth;
	}
	if ([reportsInCurrentFiscalMonth count] > 0) {
		ReportCollection *fiscalMonthCollection = [[[ReportCollection alloc] initWithReports:reportsInCurrentFiscalMonth] autorelease];
		[sortedFiscalMonthReports addObject:fiscalMonthCollection];
		fiscalMonthCollection.title = prevFiscalMonthName;
	}
	
	[self.graphView reloadData];
}


- (void)setViewMode:(DashboardViewMode)newViewMode
{
	viewMode = newViewMode;
	if (viewMode == DashboardViewModeSales || viewMode == DashboardViewModeRevenue) {
		self.graphView.title = nil;
	} else if (viewMode == DashboardViewModeEducationalSales) {
		self.graphView.title = NSLocalizedString(@"Educational Sales", nil);
	} else if (viewMode == DashboardViewModeGiftPurchases) {
		self.graphView.title = NSLocalizedString(@"Gift Purchases", nil);
	} else if (viewMode == DashboardViewModePromoCodes) {
		self.graphView.title = NSLocalizedString(@"Promo Codes", nil);
	} else if (viewMode == DashboardViewModeUpdates) {
		self.graphView.title = NSLocalizedString(@"Updates", nil);
	}
}

#pragma mark - Actions

- (void)downloadReports:(id)sender
{
	[[ReportDownloadCoordinator sharedReportDownloadCoordinator] downloadReportsForAccount:self.account];
}

- (void)stopDownload:(id)sender
{
	self.stopButtonItem.enabled = NO;
	[[ReportDownloadCoordinator sharedReportDownloadCoordinator] cancelDownloadForAccount:self.account];
}

- (void)switchTab:(UISegmentedControl *)modeControl
{
	selectedTab = modeControl.selectedSegmentIndex;
	[[NSUserDefaults standardUserDefaults] setInteger:selectedTab forKey:kSettingDashboardSelectedTab];
	[self reloadTableView];
	[self.graphView reloadData];
}

- (void)showGraphOptions:(id)sender
{
	UIActionSheet *sheet = nil;
	if (selectedTab == 0) {
		sheet = [[[UIActionSheet alloc] initWithTitle:nil 
											 delegate:self 
									cancelButtonTitle:NSLocalizedString(@"Cancel", nil) 
							   destructiveButtonTitle:nil 
									otherButtonTitles:NSLocalizedString(@"Daily Reports", nil), NSLocalizedString(@"Weekly Reports", nil), nil] autorelease];
		sheet.tag = kSheetTagDailyGraphOptions;
	} else {
		sheet = [[[UIActionSheet alloc] initWithTitle:nil 
											 delegate:self 
									cancelButtonTitle:NSLocalizedString(@"Cancel", nil) 
							   destructiveButtonTitle:nil 
									otherButtonTitles:NSLocalizedString(@"Calendar Months", nil), NSLocalizedString(@"Fiscal Months", nil), nil] autorelease];
		sheet.tag = kSheetTagMonthlyGraphOptions;
	}
	[sheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex != [actionSheet cancelButtonIndex]) {
		if (actionSheet.tag == kSheetTagDailyGraphOptions) {
			if (buttonIndex == 0) {
				showWeeks = NO;
				[self.graphView reloadData];
			} else if (buttonIndex == 1) {
				showWeeks = YES;
				[self.graphView reloadData];
			}
			[[NSUserDefaults standardUserDefaults] setBool:showWeeks forKey:kSettingDashboardShowWeeks];
		} else if (actionSheet.tag == kSheetTagMonthlyGraphOptions) {
			if (buttonIndex == 0) {
				showFiscalMonths = NO;
				[self.graphView reloadData];
			} else if (buttonIndex == 1) {
				showFiscalMonths = YES;
				[self.graphView reloadData];
			}
			[[NSUserDefaults standardUserDefaults] setBool:showFiscalMonths forKey:kSettingShowFiscalMonths];
		} else if (actionSheet.tag == kSheetTagAdvancedViewMode) {
			if (buttonIndex == 0) {
				self.viewMode = DashboardViewModeRevenue;
			} else if (buttonIndex == 1) {
				self.viewMode = DashboardViewModeSales;
			} else if (buttonIndex == 2) {
				self.viewMode = DashboardViewModeUpdates;
			} else if (buttonIndex == 3) {
				self.viewMode = DashboardViewModeEducationalSales;
			} else if (buttonIndex == 4) {
				self.viewMode = DashboardViewModeGiftPurchases;
			} else if (buttonIndex == 5) {
				self.viewMode = DashboardViewModePromoCodes;
			}
			[[NSUserDefaults standardUserDefaults] setInteger:viewMode forKey:kSettingDashboardViewMode];
			if (viewMode != DashboardViewModeRevenue) {
				[self.graphView setUnit:@""];
			} else {
				[self.graphView setUnit:[[CurrencyManager sharedManager] baseCurrencyDescription]];
			}
			[self.graphView reloadValuesAnimated:YES];
			[self reloadTableView];
		}
	}
}


- (void)switchGraphMode:(id)sender
{
	if (viewMode != DashboardViewModeRevenue) {
		self.viewMode = DashboardViewModeRevenue;
	} else {
		self.viewMode = DashboardViewModeSales;
	}
	[[NSUserDefaults standardUserDefaults] setInteger:viewMode forKey:kSettingDashboardViewMode];
	if (viewMode != DashboardViewModeRevenue) {
		[self.graphView setUnit:@""];
	} else {
		[self.graphView setUnit:[[CurrencyManager sharedManager] baseCurrencyDescription]];
	}
	[self.graphView reloadValuesAnimated:YES];
	[self reloadTableView];
}


#pragma mark - Graph view data source

- (NSArray *)colorsForGraphView:(GraphView *)graphView
{
	NSMutableArray *colors = [NSMutableArray array];
	for (Product *product in self.products) {
		if ([product.hidden boolValue]) {
			[colors addObject:[UIColor lightGrayColor]];
		} else {
			[colors addObject:product.color];
		}
	}
	return colors;
}

- (NSUInteger)numberOfBarsInGraphView:(GraphView *)graphView
{
	if (selectedTab == 0) {
		return [((showWeeks) ? self.sortedWeeklyReports : self.sortedDailyReports) count];
	} else if (selectedTab == 1) {
		if (showFiscalMonths) {
			return [self.sortedFiscalMonthReports count];
		} else {
			return [self.sortedCalendarMonthReports count];
		}
	}
	return 0;
}

- (NSArray *)graphView:(GraphView *)graphView valuesForBarAtIndex:(NSUInteger)index
{
	if (selectedTab == 0) {
		return [self stackedValuesForReport:[((showWeeks) ? self.sortedWeeklyReports : self.sortedDailyReports) objectAtIndex:index]];
	} else if (selectedTab == 1) {
		if (showFiscalMonths) {
			return [self stackedValuesForReport:[self.sortedFiscalMonthReports objectAtIndex:index]];
		} else {
			return [self stackedValuesForReport:[self.sortedCalendarMonthReports objectAtIndex:index]];
		}
	}
	return [NSArray array];
}

- (NSString *)graphView:(GraphView *)graphView labelForXAxisAtIndex:(NSUInteger)index
{
	if (selectedTab == 0) {
		Report *report = [((showWeeks) ? self.sortedWeeklyReports : self.sortedDailyReports) objectAtIndex:index];
		if (showWeeks) {
			NSDateComponents *dateComponents = [calendar components:NSWeekdayOrdinalCalendarUnit fromDate:report.startDate];
			NSInteger weekdayOrdinal = [dateComponents weekdayOrdinal];
			return [NSString stringWithFormat:@"W%i", weekdayOrdinal];
		} else {
			NSDateComponents *dateComponents = [calendar components:NSDayCalendarUnit fromDate:report.startDate];
			NSInteger day = [dateComponents day];
			return [NSString stringWithFormat:@"%i", day];
		}
	} else {
		NSDateFormatter *monthFormatter = [[[NSDateFormatter alloc] init] autorelease];
		[monthFormatter setDateFormat:@"MMM"];
		if (showFiscalMonths) {
			NSDate *date = [[self.sortedFiscalMonthReports objectAtIndex:index] startDate];
			NSDate *representativeDateForFiscalMonth = [[AppleFiscalCalendar sharedFiscalCalendar] representativeDateForFiscalMonthOfDate:date];
			return [monthFormatter stringFromDate:representativeDateForFiscalMonth];
		} else {
			id<ReportSummary> report = [self.sortedCalendarMonthReports objectAtIndex:index];
			return [monthFormatter stringFromDate:report.startDate];
		}
	}
}

- (UIColor *)graphView:(GraphView *)graphView labelColorForXAxisAtIndex:(NSUInteger)index
{
	if (selectedTab == 0) {
		id<ReportSummary> report = [((showWeeks) ? self.sortedWeeklyReports : self.sortedDailyReports) objectAtIndex:index];
		NSDateComponents *dateComponents = [calendar components:NSDayCalendarUnit | NSWeekdayCalendarUnit fromDate:report.startDate];
		NSInteger weekday = [dateComponents weekday];
		if (weekday == 1) {
			return [UIColor colorWithRed:0.843 green:0.278 blue:0.282 alpha:1.0];
		}
	}
	return [UIColor darkGrayColor];
}

- (NSString *)graphView:(GraphView *)graphView labelForBarAtIndex:(NSUInteger)index
{
	id<ReportSummary> report = nil;
	if (selectedTab == 0) {
		report = [((showWeeks) ? self.sortedWeeklyReports : self.sortedDailyReports) objectAtIndex:index];
	} else {
		if (showFiscalMonths) {
			report = [self.sortedFiscalMonthReports objectAtIndex:index];
		} else {
			report = [self.sortedCalendarMonthReports objectAtIndex:index];
		}
	}
	if (viewMode == DashboardViewModeRevenue) {
		float revenue = [report totalRevenueInBaseCurrencyForProductWithID:self.selectedProduct.productID];
		NSString *labelText = [NSString stringWithFormat:@"%@%i", [[CurrencyManager sharedManager] baseCurrencyDescription], (int)roundf(revenue)];
		return labelText;
	} else {
		int value = 0;
		if (viewMode == DashboardViewModeSales) {
			value = [report totalNumberOfPaidDownloadsForProductWithID:self.selectedProduct.productID];
		} else if (viewMode == DashboardViewModeUpdates) {
			value = [report totalNumberOfUpdatesForProductWithID:self.selectedProduct.productID];
		} else if (viewMode == DashboardViewModeEducationalSales) {
			value = [report totalNumberOfEducationalSalesForProductWithID:self.selectedProduct.productID];
		} else if (viewMode == DashboardViewModeGiftPurchases) {
			value = [report totalNumberOfGiftPurchasesForProductWithID:self.selectedProduct.productID];
		} else if (viewMode == DashboardViewModePromoCodes) {
			value = [report totalNumberOfPromoCodeTransactionsForProductWithID:self.selectedProduct.productID];
		}
		NSString *labelText = [NSString stringWithFormat:@"%i", value];
		return labelText;
	}
}

- (NSString *)graphView:(GraphView *)graphView labelForSectionAtIndex:(NSUInteger)index
{
	if (selectedTab == 0) {
		if ([((showWeeks) ? self.sortedWeeklyReports : self.sortedDailyReports) count] > 0) {
			Report *report = [((showWeeks) ? self.sortedWeeklyReports : self.sortedDailyReports) objectAtIndex:index];
			NSDateFormatter *monthFormatter = [[[NSDateFormatter alloc] init] autorelease];
			[monthFormatter setDateFormat:@"MMM '´'yy"];
			return [monthFormatter stringFromDate:report.startDate];
		} else {
			return @"N/A";
		}
	} else {
		if ([self.sortedCalendarMonthReports count] > 0) {
			id<ReportSummary> report = [self.sortedCalendarMonthReports objectAtIndex:index];
			NSDateFormatter *yearFormatter = [[[NSDateFormatter alloc] init] autorelease];
			[yearFormatter setDateFormat:@"yyyy"];
			NSString *yearString = [yearFormatter stringFromDate:report.startDate];
			if (showFiscalMonths) {
				return [NSString stringWithFormat:@" %@", yearString];
			} else {
				return yearString;
			}
		} else {
			return @"N/A";
		}
	}
}

- (NSArray *)stackedValuesForReport:(id<ReportSummary>)report
{
	NSMutableArray *stackedValues = [NSMutableArray array];
	for (Product *product in self.products) {
		NSString *productID = product.productID;
		if (!self.selectedProduct || self.selectedProduct == product) {
			float valueForProduct = 0.0;
			if (viewMode == DashboardViewModeRevenue) {
				valueForProduct = [report totalRevenueInBaseCurrencyForProductWithID:productID];
			} else {
				if (viewMode == DashboardViewModeSales) {
					valueForProduct = (float)[report totalNumberOfPaidDownloadsForProductWithID:productID];
				} else if (viewMode == DashboardViewModeUpdates) {
					valueForProduct = (float)[report totalNumberOfUpdatesForProductWithID:productID];
				} else if (viewMode == DashboardViewModeEducationalSales) {
					valueForProduct = (float)[report totalNumberOfEducationalSalesForProductWithID:productID];
				} else if (viewMode == DashboardViewModeGiftPurchases) {
					valueForProduct = (float)[report totalNumberOfGiftPurchasesForProductWithID:productID];
				} else if (viewMode == DashboardViewModePromoCodes) {
					valueForProduct = (float)[report totalNumberOfPromoCodeTransactionsForProductWithID:productID];
				}
			}
			[stackedValues addObject:[NSNumber numberWithFloat:valueForProduct]];
		} else {
			[stackedValues addObject:[NSNumber numberWithFloat:0.0]];
		}
	}
	return stackedValues;
}

#pragma mark - Graph view delegate

- (void)graphView:(GraphView *)view didSelectBarAtIndex:(NSUInteger)index
{
	NSArray *reports = nil;
	if (selectedTab == 0) {
		reports = ((showWeeks) ? self.sortedWeeklyReports : self.sortedDailyReports);
	} else if (selectedTab == 1) {
		if (showFiscalMonths) {
			reports = self.sortedFiscalMonthReports;
		} else {
			reports = self.sortedCalendarMonthReports;
		}
	}
	ReportDetailViewController *vc = [[[ReportDetailViewController alloc] initWithReports:reports selectedIndex:index] autorelease];
	vc.selectedProduct = self.selectedProduct;
	[self.navigationController pushViewController:vc animated:YES];
}

- (BOOL)graphView:(GraphView *)view canDeleteBarAtIndex:(NSUInteger)index
{
	//Only allow deletion of actual reports, not monthly summaries:
	return selectedTab == 0;
}

- (void)graphView:(GraphView *)view deleteBarAtIndex:(NSUInteger)index
{
	Report *report = nil;
	if (showWeeks) {
		report = [[[self.sortedWeeklyReports objectAtIndex:index] retain] autorelease];
		[self.sortedWeeklyReports removeObject:report];
	} else {
		report = [[[self.sortedDailyReports objectAtIndex:index] retain] autorelease];
		[self.sortedDailyReports removeObject:report];
	}
	
	NSManagedObjectContext *moc = [report managedObjectContext];
	[moc deleteObject:report];
	[moc save:NULL];
}

#pragma mark - Table view data source

- (UIView *)accessoryViewForRowAtIndexPath:(NSIndexPath *)indexPath
{
	Product *product = nil;
	if (indexPath.row != 0) {
		product = [self.visibleProducts objectAtIndex:indexPath.row - 1];
	}
	if (selectedTab == 0 || selectedTab == 1) {
		UIButton *latestValueButton = [UIButton buttonWithType:UIButtonTypeCustom];
		latestValueButton.frame = CGRectMake(0, 0, 64, 28);
		latestValueButton.titleLabel.font = [UIFont boldSystemFontOfSize:16.0];
		latestValueButton.titleLabel.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.5];
		latestValueButton.titleLabel.shadowOffset = CGSizeMake(0, -1);
		[latestValueButton setBackgroundImage:[UIImage imageNamed:@"LatestValueButton.png"] forState:UIControlStateNormal];
		[latestValueButton setBackgroundImage:[UIImage imageNamed:@"LatestValueButton.png"] forState:UIControlStateHighlighted];
		
		UILongPressGestureRecognizer *longPressRecognizer = [[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(selectAdvancedViewMode:)] autorelease];
		[latestValueButton addGestureRecognizer:longPressRecognizer];
		
		id<ReportSummary> latestReport = nil;
		if (selectedTab == 0) {
			latestReport = [((showWeeks) ? self.sortedWeeklyReports : self.sortedDailyReports) lastObject];
		} else {
			if (showFiscalMonths) {
				latestReport = [self.sortedFiscalMonthReports lastObject];
			} else {
				latestReport = [self.sortedCalendarMonthReports lastObject];
			}
		}
		
		if (viewMode == DashboardViewModeRevenue) {
			NSString *label = [NSString stringWithFormat:@"%@%i", 
							   [[CurrencyManager sharedManager] baseCurrencyDescription], 
							   (int)roundf([latestReport totalRevenueInBaseCurrencyForProductWithID:product.productID])];
			[latestValueButton setTitle:label forState:UIControlStateNormal];
		} else {
			int latestNumber = 0;
			if (viewMode == DashboardViewModeSales) {
				latestNumber = [latestReport totalNumberOfPaidDownloadsForProductWithID:product.productID];
			} else if (viewMode == DashboardViewModeUpdates) {
				latestNumber = [latestReport totalNumberOfUpdatesForProductWithID:product.productID];
			} else if (viewMode == DashboardViewModeEducationalSales) {
				latestNumber = [latestReport totalNumberOfEducationalSalesForProductWithID:product.productID];
			} else if (viewMode == DashboardViewModeGiftPurchases) {
				latestNumber = [latestReport totalNumberOfGiftPurchasesForProductWithID:product.productID];
			} else if (viewMode == DashboardViewModePromoCodes) {
				latestNumber = [latestReport totalNumberOfPromoCodeTransactionsForProductWithID:product.productID];
			}
			NSString *label = [NSString stringWithFormat:@"%i", latestNumber];
			[latestValueButton setTitle:label forState:UIControlStateNormal];
		}
		[latestValueButton addTarget:self action:@selector(switchGraphMode:) forControlEvents:UIControlEventTouchUpInside];
		return latestValueButton;
	}
	return nil;
}

- (void)selectAdvancedViewMode:(UILongPressGestureRecognizer *)gestureRecognizer
{
	if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
		UIActionSheet *sheet = [[[UIActionSheet alloc] initWithTitle:nil 
															delegate:self 
												   cancelButtonTitle:NSLocalizedString(@"Cancel", nil) 
											  destructiveButtonTitle:nil 
												   otherButtonTitles:
								 NSLocalizedString(@"Revenue", nil), 
								 NSLocalizedString(@"Sales", nil), 
								 NSLocalizedString(@"Updates", nil), 
								 NSLocalizedString(@"Educational Sales", nil), 
								 NSLocalizedString(@"Gift Purchases", nil), 
								 NSLocalizedString(@"Promo Codes", nil), nil] autorelease];
		sheet.tag = kSheetTagAdvancedViewMode;
		[sheet showInView:self.navigationController.view];
	}
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[super tableView:tableView didSelectRowAtIndexPath:indexPath];
	[self.graphView reloadValuesAnimated:YES];
}

#pragma mark -

- (void)dealloc
{
	[account removeObserver:self forKeyPath:@"isDownloadingReports"];
	[account removeObserver:self forKeyPath:@"downloadProgress"];
	[account removeObserver:self forKeyPath:@"downloadStatus"];
	
	[sortedDailyReports release];
	[sortedWeeklyReports release];
	[graphView release];
	[calendar release];
	[downloadReportsButtonItem release];
	[super dealloc];
}

@end
