//
//  SalesViewController.m
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
#import "AccountsViewController.h"
#import "UIViewController+Alert.h"

@interface SalesViewController ()

- (NSArray *)stackedValuesForReport:(id<ReportSummary>)report;

@end

@implementation SalesViewController

@synthesize sortedDailyReports, sortedWeeklyReports, sortedCalendarMonthReports, sortedFiscalMonthReports, viewMode;
@synthesize graphView, downloadReportsButtonItem;
@synthesize selectedReportPopover;

- (instancetype)initWithAccount:(ASAccount *)anAccount {
	self = [super initWithAccount:anAccount];
	if (self) {
		self.title = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) ? NSLocalizedString(@"Sales", nil) : [account displayName];
		self.tabBarItem.image = [UIImage imageNamed:@"Sales"];
		
		sortedDailyReports = [NSMutableArray new];
		sortedWeeklyReports = [NSMutableArray new];
		sortedCalendarMonthReports = [NSMutableArray new];
		sortedFiscalMonthReports = [NSMutableArray new];
		
		calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
		[calendar setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
		
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
		
		numberFormatter = [[NSNumberFormatter alloc] init];
		numberFormatter.locale = [NSLocale currentLocale];
		numberFormatter.formatterBehavior = NSNumberFormatterBehavior10_4;
		numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
		numberFormatter.maximumFractionDigits = 0;
		numberFormatter.minimumFractionDigits = 0;
		
		[account addObserver:self forKeyPath:@"isDownloadingReports" options:NSKeyValueObservingOptionNew context:nil];
		[account addObserver:self forKeyPath:@"downloadStatus" options:NSKeyValueObservingOptionNew context:nil];
		[account addObserver:self forKeyPath:@"downloadProgress" options:NSKeyValueObservingOptionNew context:nil];
		
		selectedTab = [[NSUserDefaults standardUserDefaults] integerForKey:kSettingDashboardSelectedTab];
		showFiscalMonths = [[NSUserDefaults standardUserDefaults] boolForKey:kSettingShowFiscalMonths];
		showWeeks = [[NSUserDefaults standardUserDefaults] boolForKey:kSettingDashboardShowWeeks];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:DashboardViewControllerSelectedProductsDidChangeNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:ASViewSettingsDidChangeNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowPasscodeLock:) name:ASWillShowPasscodeLockNotification object:nil];

		[self performSelector:@selector(setEdgesForExtendedLayout:) withObject:@(0)];
	}
	return self;
}

- (void)willShowPasscodeLock:(NSNotification *)notification {
	[super willShowPasscodeLock:notification];
	if (self.selectedReportPopover.popoverVisible) {
		[self.selectedReportPopover dismissPopoverAnimated:NO];
	}
}

- (void)loadView {
	[super loadView];
	self.edgesForExtendedLayout = UIRectEdgeNone;
	
	self.viewMode = [[NSUserDefaults standardUserDefaults] integerForKey:kSettingDashboardViewMode];
	if ((self.viewMode == DashboardViewModeTotalRevenue) || (self.viewMode == DashboardViewModeTotalSales)) {
		self.viewMode = DashboardViewModeRevenue;
	}
	
	BOOL iPad = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad);
	
	CGFloat graphHeight = iPad ? 450.0 : self.view.bounds.size.height * 0.5;
	self.graphView = [[GraphView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, graphHeight)];
	graphView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	graphView.delegate = self;
	graphView.dataSource = self;
	[graphView setUnit:((viewMode == DashboardViewModeRevenue) || (viewMode == DashboardViewModeTotalRevenue)) ? [CurrencyManager sharedManager].baseCurrencyDescription : @""];
	if (!iPad) {
		[graphView.sectionLabelButton addTarget:self action:@selector(showGraphOptions:) forControlEvents:UIControlEventTouchUpInside];	
	} else {
		graphView.sectionLabelButton.enabled = NO;
	}
	[graphView setNumberOfBarsPerPage:iPad ? 14 : 7];
	[self.topView addSubview:graphView];
	
	UIView *leftView = [[UIView alloc] initWithFrame:CGRectZero];
	leftView.backgroundColor = [UIColor colorWithWhite:0.9f alpha:1.0f];
	leftView.translatesAutoresizingMaskIntoConstraints = NO;
	[self.topView addSubview:leftView];
	[NSLayoutConstraint activateConstraints:@[[leftView.topAnchor constraintEqualToAnchor:self.topView.topAnchor],
											  [leftView.bottomAnchor constraintEqualToAnchor:self.topView.bottomAnchor],
											  [leftView.leftAnchor constraintEqualToAnchor:self.topView.leftAnchor],
											  [leftView.rightAnchor constraintEqualToAnchor:self.graphView.leftAnchor],
											  ]];
	
	UIView *rightView = [[UIView alloc] initWithFrame:CGRectZero];
	rightView.backgroundColor = [UIColor colorWithWhite:0.9f alpha:1.0f];
	rightView.translatesAutoresizingMaskIntoConstraints = NO;
	[self.topView addSubview:rightView];
	[NSLayoutConstraint activateConstraints:@[[rightView.topAnchor constraintEqualToAnchor:self.topView.topAnchor],
											  [rightView.bottomAnchor constraintEqualToAnchor:self.topView.bottomAnchor],
											  [rightView.leftAnchor constraintEqualToAnchor:self.graphView.rightAnchor],
											  [rightView.rightAnchor constraintEqualToAnchor:self.topView.rightAnchor],
											  ]];
	
	NSArray *segments;
	if (iPad) {
		segments = @[NSLocalizedString(@"Daily Reports", nil), NSLocalizedString(@"Weekly Reports", nil), NSLocalizedString(@"Calendar Months", nil), NSLocalizedString(@"Fiscal Months", nil)];
	} else {
		segments = @[NSLocalizedString(@"Reports", nil), NSLocalizedString(@"Months", nil)];
	}
	UISegmentedControl *tabControl = [[UISegmentedControl alloc] initWithItems:segments];
	[tabControl addTarget:self action:@selector(switchTab:) forControlEvents:UIControlEventValueChanged];
	
	if (iPad) {
		if (selectedTab == 0 && showWeeks) {
			tabControl.selectedSegmentIndex = 1;
		} else if (selectedTab == 0 && !showWeeks) {
			tabControl.selectedSegmentIndex = 0;
		} else if (showFiscalMonths) {
			tabControl.selectedSegmentIndex = 3;
		} else {
			tabControl.selectedSegmentIndex = 2;
		}
	} else {
		tabControl.selectedSegmentIndex = selectedTab;
	}
	
	self.navigationItem.titleView = tabControl;
	
	self.downloadReportsButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh 
																				  target:self 
																				  action:@selector(downloadReports:)];
	downloadReportsButtonItem.enabled = !self.account.isDownloadingReports;
	self.navigationItem.rightBarButtonItem = downloadReportsButtonItem;
	if ([self shouldShowStatusBar]) {
		self.statusLabel.text = self.account.downloadStatus;
		self.progressBar.progress = self.account.downloadProgress;
	}
}

- (BOOL)shouldShowStatusBar {
	return self.account.isDownloadingReports;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	previousOrientation = [UIApplication sharedApplication].statusBarOrientation;
	[self reloadData];
	
	UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", nil) style:UIBarButtonItemStylePlain target:self action:nil];
	self.navigationItem.backBarButtonItem = backButton;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) != UIInterfaceOrientationIsLandscape(previousOrientation)) {
		[self adjustInterfaceForOrientation:[UIApplication sharedApplication].statusBarOrientation];
	}
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	self.account.reportsBadge = @(0);
	if ([self.account.managedObjectContext hasChanges]) {
		[self.account.managedObjectContext save:nil];
	}
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	UIInterfaceOrientation toInterfaceOrientation = [self relativeOrientationFromTransform:coordinator.targetTransform];
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
		[self adjustInterfaceForOrientation:toInterfaceOrientation];
	} completion:nil];
}

- (void)adjustInterfaceForOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if (self.selectedReportPopover.popoverVisible) {
		[self.selectedReportPopover dismissPopoverAnimated:YES];
	}
	
	if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
		if (@available(iOS 11.0, *)) {
			CGFloat safeAreaWidthInset = self.view.safeAreaInsets.left + self.view.safeAreaInsets.right;
			self.graphView.frame = CGRectMake(self.view.safeAreaInsets.left, 0.0f, self.view.bounds.size.width - safeAreaWidthInset, self.view.bounds.size.height - self.view.safeAreaInsets.bottom);
		} else {
			self.graphView.frame = self.view.bounds;
		}
		self.topView.frame = self.view.bounds;
		self.productsTableView.alpha = 0.0;
		self.shadowView.hidden = YES;
		[self.graphView reloadValuesAnimated:NO];
	} else {
		CGFloat graphHeight = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad ? 450.0 : self.view.bounds.size.height * 0.5;
		self.graphView.frame = CGRectMake(0, 0, self.view.bounds.size.width, graphHeight);
		self.topView.frame = CGRectMake(0, 0, self.view.bounds.size.width, graphHeight);
		self.productsTableView.frame = CGRectMake(0, CGRectGetMaxY(self.topView.frame), self.view.bounds.size.width, self.view.bounds.size.height - self.topView.bounds.size.height);
		self.shadowView.frame = CGRectMake(0.0f, CGRectGetMaxY(self.topView.frame), self.view.bounds.size.width, self.shadowView.bounds.size.height);
		self.shadowView.hidden = NO;
		self.productsTableView.alpha = 1.0;
		[self.graphView reloadValuesAnimated:NO];
	}
	
	previousOrientation = interfaceOrientation;
}

- (NSSet *)entityNamesTriggeringReload {
	return [NSSet setWithObjects:@"DailyReport", @"WeeklyReport", @"Product", nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"isDownloadingReports"]) {
		self.downloadReportsButtonItem.enabled = !self.account.isDownloadingReports;
		[self showOrHideStatusBar];
	} else if ([keyPath isEqualToString:@"downloadStatus"] || [keyPath isEqualToString:@"downloadProgress"]) {
		progressBar.progress = self.account.downloadProgress;
		statusLabel.text = self.account.downloadStatus;
	}
}

- (void)reloadData {
	[super reloadData];
	[sortedDailyReports removeAllObjects];
	[sortedWeeklyReports removeAllObjects];
	
	NSArray *sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"startDate" ascending:YES]];
	NSSet *allDailyReports = self.account.dailyReports;
	[sortedDailyReports addObjectsFromArray:[allDailyReports allObjects]];
	[sortedDailyReports sortUsingDescriptors:sortDescriptors];
	
	NSSet *allWeeklyReports = self.account.weeklyReports;
	[sortedWeeklyReports addObjectsFromArray:[allWeeklyReports allObjects]];
	[sortedWeeklyReports sortUsingDescriptors:sortDescriptors];
	
	// Group daily reports by calendar month:
	[sortedCalendarMonthReports removeAllObjects];
	NSDateComponents *prevDateComponents = nil;
	NSMutableArray *reportsInCurrentMonth = nil;
	for (Report *dailyReport in sortedDailyReports) {
		NSDateComponents *dateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:dailyReport.startDate];
		if (!prevDateComponents || (dateComponents.month != prevDateComponents.month || dateComponents.year != prevDateComponents.year)) {
			// New month discovered. Make a new ReportCollection to gather all the daily reports in this month.
			reportsInCurrentMonth = [NSMutableArray array];
			[reportsInCurrentMonth addObject:dailyReport];
			ReportCollection *monthCollection = [[ReportCollection alloc] initWithReports:reportsInCurrentMonth];
			[dateFormatter setDateFormat:@"MMMM yyyy"];
			monthCollection.title = [dateFormatter stringFromDate:dailyReport.startDate];
			[sortedCalendarMonthReports addObject:monthCollection];
		} else {
			// This report is from the same month as the previous report. Append the daily report to the existing collection.
			[reportsInCurrentMonth addObject:dailyReport];
		}
		prevDateComponents = dateComponents;
	}
	
	// Group daily reports by fiscal month:
	[sortedFiscalMonthReports removeAllObjects];
	NSString *prevFiscalMonthName = nil;
	NSMutableArray *reportsInCurrentFiscalMonth = nil;
	for (Report *dailyReport in sortedDailyReports) {
		NSString *fiscalMonth = [[AppleFiscalCalendar sharedFiscalCalendar] fiscalMonthForDate:dailyReport.startDate];
		if (![fiscalMonth isEqualToString:prevFiscalMonthName]) {
			// New month discovered. Make a new ReportCollection to gather all the daily reports in this month.
			reportsInCurrentFiscalMonth = [NSMutableArray array];
			[reportsInCurrentFiscalMonth addObject:dailyReport];
			ReportCollection *fiscalMonthCollection = [[ReportCollection alloc] initWithReports:reportsInCurrentFiscalMonth];
			fiscalMonthCollection.title = fiscalMonth;
			[sortedFiscalMonthReports addObject:fiscalMonthCollection];
		} else {
			// This report is from the same month as the previous report. Append the daily report to the existing collection.
			[reportsInCurrentFiscalMonth addObject:dailyReport];
		}
		prevFiscalMonthName = fiscalMonth;
	}
	
	[self.graphView reloadData];
}


- (void)setViewMode:(DashboardViewMode)newViewMode {
	viewMode = newViewMode;
	if (viewMode == DashboardViewModeSales || viewMode == DashboardViewModeRevenue) {
		self.graphView.title = nil;
	} else if (viewMode == DashboardViewModeRedownloads) {
		self.graphView.title = NSLocalizedString(@"Redownloads", nil);
	} else if (viewMode == DashboardViewModeEducationalSales) {
		self.graphView.title = NSLocalizedString(@"Educational Sales", nil);
	} else if (viewMode == DashboardViewModeGiftPurchases) {
		self.graphView.title = NSLocalizedString(@"Gift Purchases", nil);
	} else if (viewMode == DashboardViewModePromoCodes) {
		self.graphView.title = NSLocalizedString(@"Promo Codes", nil);
	} else if (viewMode == DashboardViewModeUpdates) {
		self.graphView.title = NSLocalizedString(@"Updates", nil);
	} else if (viewMode == DashboardViewModeTotalRevenue) {
		self.graphView.title = NSLocalizedString(@"Total Revenue", nil);
	} else if (viewMode == DashboardViewModeTotalSales) {
		self.graphView.title = NSLocalizedString(@"Total Sales", nil);
	}
}

#pragma mark - Actions

- (void)downloadReports:(id)sender {
	if ((account.providerID == nil) || (account.providerID.length == 0)) {
        [self displayAlertWithTitle:NSLocalizedString(@"Provider ID Missing", nil)
                            message:NSLocalizedString(@"Provider ID not set for this account. Please go to the account's settings and fill in the missing information.", nil)];
	} else if ((account.accessToken == nil) || (account.accessToken.length == 0)) {
        [self displayAlertWithTitle:NSLocalizedString(@"Access Token Missing", nil)
                            message:NSLocalizedString(@"Access token not set for this account. Please go to the account's settings and fill in the missing information.", nil)];
	} else if ((account.vendorID == nil) || (account.vendorID.length == 0)) {
        [self displayAlertWithTitle:NSLocalizedString(@"Vendor ID Missing", nil)
                            message:NSLocalizedString(@"You have not entered a vendor ID for this account. Please go to the account's settings and fill in the missing information.", nil)];
	} else {
		[[ReportDownloadCoordinator sharedReportDownloadCoordinator] downloadReportsForAccount:account];
	}
}

- (void)stopDownload:(id)sender {
	self.stopButtonItem.enabled = NO;
	[[ReportDownloadCoordinator sharedReportDownloadCoordinator] cancelDownloadForAccount:self.account];
}

- (void)switchTab:(UISegmentedControl *)modeControl {
	selectedTab = modeControl.selectedSegmentIndex;
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
		if (selectedTab == 0) {
			showWeeks = NO;
		} else if (selectedTab == 1) {
			selectedTab = 0;
			showWeeks = YES;
		} else if (selectedTab == 2) {
			selectedTab = 1;
			showFiscalMonths = NO;
		} else if (selectedTab == 3) {
			selectedTab = 1;
			showFiscalMonths = YES;
		}
	}
	
	[[NSUserDefaults standardUserDefaults] setInteger:selectedTab forKey:kSettingDashboardSelectedTab];
	[[NSUserDefaults standardUserDefaults] setBool:showWeeks forKey:kSettingDashboardShowWeeks];
	[[NSUserDefaults standardUserDefaults] setBool:showFiscalMonths forKey:kSettingShowFiscalMonths];
	
	[self reloadTableView];
	[self.graphView reloadData];
}

- (void)showGraphOptions:(id)sender {
    self.activeAlertSheet = [UIAlertController alertControllerWithTitle:nil
                                                                message:nil
                                                         preferredStyle:UIAlertControllerStyleActionSheet];
    
    [self.activeAlertSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                              style:UIAlertActionStyleCancel
                                                            handler:^(UIAlertAction * _Nonnull action) {
        self.activeAlertSheet = nil;
    }]];
    
	if (selectedTab == 0) {
        [self.activeAlertSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Daily Reports", nil)
                                                                  style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction * _Nonnull action) {
            self->showWeeks = NO;
            [self.graphView reloadData];
            [self reloadTableView];
            [[NSUserDefaults standardUserDefaults] setBool:self->showWeeks forKey:kSettingDashboardShowWeeks];
            self.activeAlertSheet = nil;
        }]];
        
        [self.activeAlertSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Weekly Reports", nil)
                                                                  style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction * _Nonnull action) {
            self->showWeeks = YES;
            [self.graphView reloadData];
            [self reloadTableView];
            [[NSUserDefaults standardUserDefaults] setBool:self->showWeeks forKey:kSettingDashboardShowWeeks];
            self.activeAlertSheet = nil;
        }]];
	} else {
        [self.activeAlertSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Calendar Months", nil)
                                                                  style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction * _Nonnull action) {
            self->showFiscalMonths = NO;
            [self.graphView reloadData];
            [self reloadTableView];
            [[NSUserDefaults standardUserDefaults] setBool:self->showFiscalMonths forKey:kSettingShowFiscalMonths];
            self.activeAlertSheet = nil;
        }]];
        
        [self.activeAlertSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Fiscal Months", nil)
                                                                  style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction * _Nonnull action) {
            self->showFiscalMonths = YES;
            [self.graphView reloadData];
            [self reloadTableView];
            [[NSUserDefaults standardUserDefaults] setBool:self->showFiscalMonths forKey:kSettingShowFiscalMonths];
            self.activeAlertSheet = nil;
        }]];
	}
    [self presentViewController:self.activeAlertSheet animated:YES completion:nil];
}

- (void)switchGraphMode:(id)sender {
	if (viewMode == DashboardViewModeRevenue) {
		self.viewMode = DashboardViewModeSales;
	} else if (viewMode == DashboardViewModeSales) {
		self.viewMode = DashboardViewModeRevenue;
	} else if (viewMode == DashboardViewModeTotalRevenue) {
		self.viewMode = DashboardViewModeTotalSales;
	} else if (viewMode == DashboardViewModeTotalSales) {
		self.viewMode = DashboardViewModeTotalRevenue;
	} else {
		self.viewMode = DashboardViewModeRevenue;
	}
	[[NSUserDefaults standardUserDefaults] setInteger:viewMode forKey:kSettingDashboardViewMode];
	if ((viewMode == DashboardViewModeRevenue) || (viewMode == DashboardViewModeTotalRevenue)) {
		[self.graphView setUnit:[[CurrencyManager sharedManager] baseCurrencyDescription]];
	} else {
		[self.graphView setUnit:@""];
	}
	[self.graphView reloadValuesAnimated:YES];
	[self reloadTableView];
}


#pragma mark - Graph view data source

- (NSArray *)colorsForGraphView:(GraphView *)graphView {
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

- (NSUInteger)numberOfBarsInGraphView:(GraphView *)graphView {
	if (selectedTab == 0) {
		return [(showWeeks ? self.sortedWeeklyReports : self.sortedDailyReports) count];
	} else if (selectedTab == 1) {
		if (showFiscalMonths) {
			return [self.sortedFiscalMonthReports count];
		} else {
			return [self.sortedCalendarMonthReports count];
		}
	}
	return 0;
}

- (NSArray *)graphView:(GraphView *)graphView valuesForBarAtIndex:(NSUInteger)index {
	if (selectedTab == 0) {
		return [self stackedValuesForReport:(showWeeks ? self.sortedWeeklyReports : self.sortedDailyReports)[index]];
	} else if (selectedTab == 1) {
		if (showFiscalMonths) {
			return [self stackedValuesForReport:self.sortedFiscalMonthReports[index]];
		} else {
			return [self stackedValuesForReport:self.sortedCalendarMonthReports[index]];
		}
	}
	return [NSArray array];
}

- (NSString *)graphView:(GraphView *)graphView labelForXAxisAtIndex:(NSUInteger)index {
	if (selectedTab == 0) {
		Report *report = (showWeeks ? self.sortedWeeklyReports : self.sortedDailyReports)[index];
		if (showWeeks) {
			NSDateComponents *dateComponents = [calendar components:NSCalendarUnitWeekdayOrdinal fromDate:report.startDate];
			NSInteger weekdayOrdinal = [dateComponents weekdayOrdinal];
			return [NSString stringWithFormat:@"W%li", (long)weekdayOrdinal];
		} else {
			[dateFormatter setDateFormat:@"d\nEEE"];
			return [dateFormatter stringFromDate:report.startDate];
		}
	} else {
		NSDate *monthDate = nil;
		if (showFiscalMonths) {
			NSDate *date = [self.sortedFiscalMonthReports[index] startDate];
			NSDate *representativeDateForFiscalMonth = [[AppleFiscalCalendar sharedFiscalCalendar] representativeDateForFiscalMonthOfDate:date];
			monthDate = representativeDateForFiscalMonth;
		} else {
			id<ReportSummary> report = self.sortedCalendarMonthReports[index];
			monthDate = report.startDate;
		}
		[dateFormatter setDateFormat:@"MMM"];
		return [dateFormatter stringFromDate:monthDate];
	}
}

- (UIColor *)graphView:(GraphView *)graphView labelColorForXAxisAtIndex:(NSUInteger)index {
	if (selectedTab == 0) {
		id<ReportSummary> report = (showWeeks ? self.sortedWeeklyReports : self.sortedDailyReports)[index];
		NSDateComponents *dateComponents = [calendar components:NSCalendarUnitDay | NSCalendarUnitWeekday fromDate:report.startDate];
		NSInteger weekday = [dateComponents weekday];
		if (weekday == 1) {
			return [UIColor colorWithRed:0.843 green:0.278 blue:0.282 alpha:1.0];
		}
	}
	if (@available(iOS 13.0, *)) {
		return [UIColor secondaryLabelColor];
	} else {
		return [UIColor darkGrayColor];
	}
}

- (NSString *)graphView:(GraphView *)graphView labelForBarAtIndex:(NSUInteger)index {
	id<ReportSummary> report = nil;
	if (selectedTab == 0) {
		report = (showWeeks ? self.sortedWeeklyReports : self.sortedDailyReports)[index];
	} else {
		if (showFiscalMonths) {
			report = self.sortedFiscalMonthReports[index];
		} else {
			report = self.sortedCalendarMonthReports[index];
		}
	}
	
	CGFloat value = 0;
	
	NSArray *tProducts = (self.selectedProducts ? self.selectedProducts : self.visibleProducts);
	
	for (Product *selectedProduct in tProducts) {
		if (viewMode == DashboardViewModeRevenue) {
			value += [report totalRevenueInBaseCurrencyForProductWithID:selectedProduct.productID];
		} else {
			if (viewMode == DashboardViewModeSales) {
				value += [report totalNumberOfPaidDownloadsForProductWithID:selectedProduct.productID];
			} else if (viewMode == DashboardViewModeUpdates) {
				value += [report totalNumberOfUpdatesForProductWithID:selectedProduct.productID];
			} else if (viewMode == DashboardViewModeRedownloads) {
				value += [report totalNumberOfRedownloadsForProductWithID:selectedProduct.productID];
			} else if (viewMode == DashboardViewModeEducationalSales) {
				value += [report totalNumberOfEducationalSalesForProductWithID:selectedProduct.productID];
			} else if (viewMode == DashboardViewModeGiftPurchases) {
				value += [report totalNumberOfGiftPurchasesForProductWithID:selectedProduct.productID];
			} else if (viewMode == DashboardViewModePromoCodes) {
				value += [report totalNumberOfPromoCodeTransactionsForProductWithID:selectedProduct.productID];
			}
		}
	}
	
	NSString *labelText = @"";
	if (viewMode == DashboardViewModeRevenue) {
		labelText = [NSString stringWithFormat:@"%@%@", [[CurrencyManager sharedManager] baseCurrencyDescription], [numberFormatter stringFromNumber:@(roundf(value))]];
	} else {
		labelText = [numberFormatter stringFromNumber:@(value)];
	}
	
	return labelText;
}

- (NSString *)graphView:(GraphView *)graphView labelForSectionAtIndex:(NSUInteger)index {
	if (selectedTab == 0) {
		if ([(showWeeks ? self.sortedWeeklyReports : self.sortedDailyReports) count] > index) {
			Report *report = (showWeeks ? self.sortedWeeklyReports : self.sortedDailyReports)[index];
			[dateFormatter setDateFormat:@"MMM '’'yy"];
			return [dateFormatter stringFromDate:report.startDate];
		} else {
			return @"N/A";
		}
	} else {
		if ([self.sortedCalendarMonthReports count] > index) {
			id<ReportSummary> report = self.sortedCalendarMonthReports[index];
			[dateFormatter setDateFormat:@"yyyy"];
			NSString *yearString = [dateFormatter stringFromDate:report.startDate];
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

- (NSArray *)stackedValuesForReport:(id<ReportSummary>)report {
	NSMutableArray *stackedValues = [NSMutableArray array];
	for (Product *product in self.products) {
		NSString *productID = product.productID;
		if (!self.selectedProducts || [self.selectedProducts containsObject:product]) {
			float valueForProduct = 0.0;
			if (viewMode == DashboardViewModeRevenue) {
				valueForProduct = [report totalRevenueInBaseCurrencyForProductWithID:productID];
			} else {
				if (viewMode == DashboardViewModeSales) {
					valueForProduct = (float)[report totalNumberOfPaidDownloadsForProductWithID:productID];
				} else if (viewMode == DashboardViewModeUpdates) {
					valueForProduct = (float)[report totalNumberOfUpdatesForProductWithID:productID];
				} else if (viewMode == DashboardViewModeRedownloads) {
					valueForProduct = (float)[report totalNumberOfRedownloadsForProductWithID:productID];
				} else if (viewMode == DashboardViewModeEducationalSales) {
					valueForProduct = (float)[report totalNumberOfEducationalSalesForProductWithID:productID];
				} else if (viewMode == DashboardViewModeGiftPurchases) {
					valueForProduct = (float)[report totalNumberOfGiftPurchasesForProductWithID:productID];
				} else if (viewMode == DashboardViewModePromoCodes) {
					valueForProduct = (float)[report totalNumberOfPromoCodeTransactionsForProductWithID:productID];
				}
			}
			[stackedValues addObject:@(valueForProduct)];
		} else {
			[stackedValues addObject:@(0.0)];
		}
	}
	return stackedValues;
}

#pragma mark - Graph view delegate

- (void)graphView:(GraphView *)view didSelectBarAtIndex:(NSUInteger)index withFrame:(CGRect)barFrame {
	NSArray *reports = nil;
	if (selectedTab == 0) {
		reports = (showWeeks ? self.sortedWeeklyReports : self.sortedDailyReports);
	} else if (selectedTab == 1) {
		if (showFiscalMonths) {
			reports = self.sortedFiscalMonthReports;
		} else {
			reports = self.sortedCalendarMonthReports;
		}
	}
	ReportDetailViewController *vc = [[ReportDetailViewController alloc] initWithReports:reports selectedIndex:index];
	vc.selectedProduct = [self.selectedProducts lastObject];
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
		[self.navigationController pushViewController:vc animated:YES];
	} else {
		if (self.selectedReportPopover.isPopoverVisible) {
			ReportDetailViewController *selectedReportDetailViewController = (ReportDetailViewController *)(((UINavigationController *)self.selectedReportPopover.contentViewController).viewControllers[0]);
			if (selectedReportDetailViewController.selectedReportIndex == index) {
				[self.selectedReportPopover dismissPopoverAnimated:YES];
				return;
			} else {
				[self.selectedReportPopover dismissPopoverAnimated:NO];
			}
		}
		UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
		self.selectedReportPopover = [[UIPopoverController alloc] initWithContentViewController:nav];
		self.selectedReportPopover.passthroughViews = @[self.graphView];
		if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
			[self.selectedReportPopover presentPopoverFromRect:barFrame 
														inView:self.graphView 
									  permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
		} else {
			[self.selectedReportPopover presentPopoverFromRect:barFrame 
														inView:self.graphView 
									  permittedArrowDirections:UIPopoverArrowDirectionLeft | UIPopoverArrowDirectionRight animated:YES];
		}
	}
}

- (BOOL)graphView:(GraphView *)view canDeleteBarAtIndex:(NSUInteger)index {
	// Only allow deletion of actual reports, not monthly summaries.
	return (selectedTab == 0);
}

- (void)graphView:(GraphView *)view deleteBarAtIndex:(NSUInteger)index {
	Report *report = nil;
	if (showWeeks) {
		report = self.sortedWeeklyReports[index];
		[self.sortedWeeklyReports removeObject:report];
	} else {
		report = self.sortedDailyReports[index];
		[self.sortedDailyReports removeObject:report];
	}
	
	NSManagedObjectContext *moc = [report managedObjectContext];
	[moc deleteObject:report];
	[moc save:nil];
}

#pragma mark - Table view data source

- (UIButton *)latestValueButtonWithTitle:(NSString *)title {
	UIColor *topColor = [UIColor colorWithRed:112.0f/255.0f green:167.0f/255.0f blue:223.0f/255.0f alpha:1.0f];
	UIColor *bottomColor = [UIColor colorWithRed:72.0f/255.0f green:126.0f/255.0f blue:165.0f/255.0f alpha:1.0f];
	UIColor *borderColor = [UIColor colorWithRed:38.0f/255.0f green:70.0f/255.0f blue:97.0f/255.0f alpha:0.25f];
	
	UIButton *latestValueButton = [UIButton buttonWithType:UIButtonTypeCustom];
	latestValueButton.frame = CGRectMake(0.0f, 0.0f, 64.0f, 28.0f);
	
	latestValueButton.titleLabel.font = [UIFont systemFontOfSize:16.0f weight:UIFontWeightSemibold];
	latestValueButton.titleLabel.adjustsFontSizeToFitWidth = YES;
	[latestValueButton setTitle:title forState:UIControlStateNormal];
	
	latestValueButton.backgroundColor = topColor;
	CAGradientLayer *gradientLayer = [CAGradientLayer layer];
	gradientLayer.frame = latestValueButton.bounds;
	gradientLayer.colors = @[(id)topColor.CGColor,
							 (id)bottomColor.CGColor];
	[latestValueButton.layer insertSublayer:gradientLayer atIndex:0];
	
	latestValueButton.layer.borderColor = borderColor.CGColor;
	latestValueButton.layer.borderWidth = 1.0f;
	latestValueButton.layer.cornerRadius = 5.0f;
	latestValueButton.clipsToBounds = YES;
	
	[latestValueButton addTarget:self action:@selector(switchGraphMode:) forControlEvents:UIControlEventTouchUpInside];
	
	UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(selectAdvancedViewMode:)];
	[latestValueButton addGestureRecognizer:longPressRecognizer];
	
	return latestValueButton;
}

- (UIView *)accessoryViewForRowAtIndexPath:(NSIndexPath *)indexPath {
	Product *product = nil;
	if (indexPath.row != 0) {
		product = self.visibleProducts[indexPath.row - 1];
	}
	if (selectedTab == 0 || selectedTab == 1) {
		NSString *title = nil;
		
		id<ReportSummary> latestReport = nil;
		if (selectedTab == 0) {
			latestReport = [(showWeeks ? self.sortedWeeklyReports : self.sortedDailyReports) lastObject];
		} else {
			if (showFiscalMonths) {
				latestReport = [self.sortedFiscalMonthReports lastObject];
			} else {
				latestReport = [self.sortedCalendarMonthReports lastObject];
			}
		}
		
		if ((viewMode == DashboardViewModeTotalRevenue) || (viewMode == DashboardViewModeTotalSales)) {
			CGFloat value = 0;
			
			for (id<ReportSummary> dailyReport in self.sortedDailyReports) {
				if (!product.productID) {
					NSArray *tProducts = self.selectedProducts ?: self.visibleProducts;
					for (Product *selectedProduct in tProducts) {
						if (viewMode == DashboardViewModeTotalRevenue) {
							value += [dailyReport totalRevenueInBaseCurrencyForProductWithID:selectedProduct.productID];
						} else if (viewMode == DashboardViewModeTotalSales) {
							value += [dailyReport totalNumberOfPaidDownloadsForProductWithID:selectedProduct.productID];
						}
					}
				} else {
					if (viewMode == DashboardViewModeTotalRevenue) {
						value += [dailyReport totalRevenueInBaseCurrencyForProductWithID:product.productID];
					} else if (viewMode == DashboardViewModeTotalSales) {
						value += [dailyReport totalNumberOfPaidDownloadsForProductWithID:product.productID];
					}
				}
			}
			
			if (viewMode == DashboardViewModeTotalRevenue) {
				title = [NSString stringWithFormat:@"%@%@", [[CurrencyManager sharedManager] baseCurrencyDescription], [numberFormatter stringFromNumber:@(roundf(value))]];
			} else {
				title = [numberFormatter stringFromNumber:@(value)];
			}
		} else if (viewMode == DashboardViewModeRevenue) {
			title = [NSString stringWithFormat:@"%@%@", [[CurrencyManager sharedManager] baseCurrencyDescription], [numberFormatter stringFromNumber:@(roundf([latestReport totalRevenueInBaseCurrencyForProductWithID:product.productID]))]];
		} else {
			NSInteger latestNumber = 0;
			if (viewMode == DashboardViewModeSales) {
				latestNumber = [latestReport totalNumberOfPaidDownloadsForProductWithID:product.productID];
			} else if (viewMode == DashboardViewModeUpdates) {
				latestNumber = [latestReport totalNumberOfUpdatesForProductWithID:product.productID];
			} else if (viewMode == DashboardViewModeRedownloads) {
				latestNumber = [latestReport totalNumberOfRedownloadsForProductWithID:product.productID];
			} else if (viewMode == DashboardViewModeEducationalSales) {
				latestNumber = [latestReport totalNumberOfEducationalSalesForProductWithID:product.productID];
			} else if (viewMode == DashboardViewModeGiftPurchases) {
				latestNumber = [latestReport totalNumberOfGiftPurchasesForProductWithID:product.productID];
			} else if (viewMode == DashboardViewModePromoCodes) {
				latestNumber = [latestReport totalNumberOfPromoCodeTransactionsForProductWithID:product.productID];
			}
			title = [numberFormatter stringFromNumber:@(latestNumber)];
		}
		
		return [self latestValueButtonWithTitle:title];
	}
	return nil;
}

- (void)selectAdvancedViewMode:(UILongPressGestureRecognizer *)gestureRecognizer {
	if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        self.activeAlertSheet = [UIAlertController alertControllerWithTitle:nil
                                                                    message:nil
                                                             preferredStyle:UIAlertControllerStyleActionSheet];
        
        [self.activeAlertSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                                  style:UIAlertActionStyleCancel
                                                                handler:^(UIAlertAction * _Nonnull action) {
            self.activeAlertSheet = nil;
        }]];
        
        [self.activeAlertSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Revenue", nil)
                                                                  style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction * _Nonnull action) {
            self.viewMode = DashboardViewModeRevenue;
            [self switchAdvancedViewMode];
        }]];
        
        [self.activeAlertSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sales", nil)
                                                                  style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction * _Nonnull action) {
            self.viewMode = DashboardViewModeSales;
            [self switchAdvancedViewMode];
        }]];
        
        [self.activeAlertSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Updates", nil)
                                                                  style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction * _Nonnull action) {
            self.viewMode = DashboardViewModeUpdates;
            [self switchAdvancedViewMode];
        }]];
        
        [self.activeAlertSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Redownloads", nil)
                                                                  style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction * _Nonnull action) {
            self.viewMode = DashboardViewModeRedownloads;
            [self switchAdvancedViewMode];
        }]];
        
        [self.activeAlertSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Educational Sales", nil)
                                                                  style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction * _Nonnull action) {
            self.viewMode = DashboardViewModeEducationalSales;
            [self switchAdvancedViewMode];
        }]];
        
        [self.activeAlertSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Gift Purchases", nil)
                                                                  style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction * _Nonnull action) {
            self.viewMode = DashboardViewModeGiftPurchases;
            [self switchAdvancedViewMode];
        }]];
        
        [self.activeAlertSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Promo Codes", nil)
                                                                  style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction * _Nonnull action) {
            self.viewMode = DashboardViewModePromoCodes;
            [self switchAdvancedViewMode];
        }]];
        
        [self.activeAlertSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Total", nil)
                                                                  style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction * _Nonnull action) {
            self.viewMode = DashboardViewModeTotalRevenue;
            [self switchAdvancedViewMode];
        }]];
        
        [self presentViewController:self.activeAlertSheet animated:YES completion:nil];
	}
}

- (void)switchAdvancedViewMode {
    [[NSUserDefaults standardUserDefaults] setInteger:viewMode forKey:kSettingDashboardViewMode];
    if ((viewMode == DashboardViewModeRevenue) || (viewMode == DashboardViewModeTotalRevenue)) {
        [self.graphView setUnit:[[CurrencyManager sharedManager] baseCurrencyDescription]];
    } else {
        [self.graphView setUnit:@""];
    }
    [self.graphView reloadValuesAnimated:YES];
    [self reloadTableView];
}

#pragma mark - Table view delegate

- (void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer {
	[super handleLongPress:gestureRecognizer];
	[self.graphView reloadValuesAnimated:YES];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
	[super tableView:tableView didDeselectRowAtIndexPath:indexPath];
	[self.graphView reloadValuesAnimated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[super tableView:tableView didSelectRowAtIndexPath:indexPath];
	[self.graphView reloadValuesAnimated:YES];
}

#pragma mark -

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:ASViewSettingsDidChangeNotification object:nil];
	
	[account removeObserver:self forKeyPath:@"isDownloadingReports"];
	[account removeObserver:self forKeyPath:@"downloadProgress"];
	[account removeObserver:self forKeyPath:@"downloadStatus"];
	
}

@end
