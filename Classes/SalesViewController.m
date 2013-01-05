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
#import "AccountsViewController.h"

#define kSheetTagDailyGraphOptions		1
#define kSheetTagMonthlyGraphOptions	2
#define kSheetTagAdvancedViewMode		3

@interface SalesViewController ()

- (NSArray *)stackedValuesForReport:(id<ReportSummary>)report;

@end

@implementation SalesViewController

@synthesize sortedDailyReports, sortedWeeklyReports, sortedCalendarMonthReports, sortedFiscalMonthReports, viewMode;
@synthesize graphView, downloadReportsButtonItem;
@synthesize selectedReportPopover;

- (id)initWithAccount:(ASAccount *)anAccount
{
	self = [super initWithAccount:anAccount];
	if (self) {
		self.title = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) ? NSLocalizedString(@"Sales", nil) : [account displayName];
		self.tabBarItem.image = [UIImage imageNamed:@"Sales.png"];
		
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
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:ASViewSettingsDidChangeNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowPasscodeLock:) name:ASWillShowPasscodeLockNotification object:nil];
    }
	return self;
}

- (void)willShowPasscodeLock:(NSNotification *)notification
{
	[super willShowPasscodeLock:notification];
	if (self.selectedReportPopover.popoverVisible) {
		[self.selectedReportPopover dismissPopoverAnimated:NO];
	}
}

- (void)loadView
{
	[super loadView];
	
	self.viewMode = [[NSUserDefaults standardUserDefaults] integerForKey:kSettingDashboardViewMode];
	
	BOOL iPad = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad);
	
	CGFloat graphHeight = iPad ? 450.0 : (self.view.bounds.size.height - 44.0) * 0.5;
	self.graphView = [[[GraphView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, graphHeight)] autorelease];
	graphView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	graphView.delegate = self;
	graphView.dataSource = self;
	[graphView setUnit:(viewMode != DashboardViewModeRevenue) ? @"" : [[CurrencyManager sharedManager] baseCurrencyDescription]];
	if (!iPad) {
		[graphView.sectionLabelButton addTarget:self action:@selector(showGraphOptions:) forControlEvents:UIControlEventTouchUpInside];	
	} else {
		graphView.sectionLabelButton.enabled = NO;
	}
	[graphView setNumberOfBarsPerPage:iPad ? 14 : 7];
	[self.topView addSubview:graphView];
	
	NSArray *segments;
	if (iPad) {
		segments = [NSArray arrayWithObjects:NSLocalizedString(@"Daily Reports", nil), NSLocalizedString(@"Weekly Reports", nil), NSLocalizedString(@"Calendar Months", nil), NSLocalizedString(@"Fiscal Months", nil), nil];
	} else {
		segments = [NSArray arrayWithObjects:NSLocalizedString(@"Reports", nil), NSLocalizedString(@"Months", nil), nil];
	}
	UISegmentedControl *tabControl = [[[UISegmentedControl alloc] initWithItems:segments] autorelease];
	tabControl.segmentedControlStyle = UISegmentedControlStyleBar;
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
	previousOrientation = self.interfaceOrientation;
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
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		return YES;
	}
	return UIInterfaceOrientationIsLandscape(interfaceOrientation) || interfaceOrientation == UIInterfaceOrientationPortrait;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	if (self.selectedReportPopover.popoverVisible) {
		[self.selectedReportPopover dismissPopoverAnimated:YES];
	}
	if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
		self.graphView.frame = self.view.bounds;
		self.topView.frame = self.view.bounds;
		self.productsTableView.alpha = 0.0;
		self.shadowView.hidden = YES;
		[self.graphView reloadValuesAnimated:NO];
	} else {
		CGFloat graphHeight = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? 450.0 : self.view.bounds.size.height * 0.5;
		self.graphView.frame = CGRectMake(0, 0, self.view.bounds.size.width, graphHeight);
		self.topView.frame = CGRectMake(0, 0, self.view.bounds.size.width, graphHeight);
		self.shadowView.hidden = NO;
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
	[monthFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	[sortedCalendarMonthReports removeAllObjects];
	NSDateComponents *prevDateComponents = nil;
	NSMutableArray *reportsInCurrentMonth = nil;
	for (Report *dailyReport in sortedDailyReports) {
		NSDateComponents *dateComponents = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit fromDate:dailyReport.startDate];
		if (!prevDateComponents || (dateComponents.month != prevDateComponents.month || dateComponents.year != prevDateComponents.year)) {
			// New month discovered. Make a new ReportCollection to gather all the daily reports in this month.
			reportsInCurrentMonth = [NSMutableArray array];
			[reportsInCurrentMonth addObject:dailyReport];
			ReportCollection *monthCollection = [[[ReportCollection alloc] initWithReports:reportsInCurrentMonth] autorelease];
			monthCollection.title = [monthFormatter stringFromDate:dailyReport.startDate];
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
	[self reloadTableView];
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
	if (self.account.password && self.account.password.length > 0) { //Only download reports for accounts with login
		if (!account.vendorID || account.vendorID.length == 0) {
			[[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Vendor ID Missing", nil) 
										 message:NSLocalizedString(@"You have not entered a vendor ID for this account. Please go to the account's settings and fill in the missing information.", nil) 
										delegate:nil 
							   cancelButtonTitle:NSLocalizedString(@"OK", nil) 
							   otherButtonTitles:nil] autorelease] show];
		} else {
			[[ReportDownloadCoordinator sharedReportDownloadCoordinator] downloadReportsForAccount:self.account];
		}
	} else {
		[[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Login Missing", nil) 
									 message:NSLocalizedString(@"You have not entered your iTunes Connect login for this account.", nil)
									delegate:nil 
						   cancelButtonTitle:NSLocalizedString(@"OK", nil) 
						   otherButtonTitles:nil] autorelease] show];
	}
	
}

- (void)stopDownload:(id)sender
{
	self.stopButtonItem.enabled = NO;
	[[ReportDownloadCoordinator sharedReportDownloadCoordinator] cancelDownloadForAccount:self.account];
}

- (void)switchTab:(UISegmentedControl *)modeControl
{
	selectedTab = modeControl.selectedSegmentIndex;
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
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

- (void)showGraphOptions:(id)sender
{
	if (selectedTab == 0) {
		self.activeSheet = [[[UIActionSheet alloc] initWithTitle:nil 
											 delegate:self 
									cancelButtonTitle:NSLocalizedString(@"Cancel", nil) 
							   destructiveButtonTitle:nil 
									otherButtonTitles:NSLocalizedString(@"Daily Reports", nil), NSLocalizedString(@"Weekly Reports", nil), nil] autorelease];
		self.activeSheet.tag = kSheetTagDailyGraphOptions;
	} else {
		self.activeSheet = [[[UIActionSheet alloc] initWithTitle:nil 
											 delegate:self 
									cancelButtonTitle:NSLocalizedString(@"Cancel", nil) 
							   destructiveButtonTitle:nil 
									otherButtonTitles:NSLocalizedString(@"Calendar Months", nil), NSLocalizedString(@"Fiscal Months", nil), nil] autorelease];
		self.activeSheet.tag = kSheetTagMonthlyGraphOptions;
	}
	[self.activeSheet showInView:self.view];
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
		[monthFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
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
    
    float value = 0;
    
    NSArray* tProducts = ((self.selectedProducts) ? self.selectedProducts : self.visibleProducts);
    
    for (Product * selectedProduct in tProducts) {
        if (viewMode == DashboardViewModeRevenue) {
            value += [report totalRevenueInBaseCurrencyForProductWithID:selectedProduct.productID];
        } else {
            if (viewMode == DashboardViewModeSales) {
                value += [report totalNumberOfPaidDownloadsForProductWithID:selectedProduct.productID];
            } else if (viewMode == DashboardViewModeUpdates) {
                value += [report totalNumberOfUpdatesForProductWithID:selectedProduct.productID];
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
        labelText = [NSString stringWithFormat:@"%@%i", [[CurrencyManager sharedManager] baseCurrencyDescription], (int)roundf(value)];
    } else {
        labelText = [NSString stringWithFormat:@"%i", (int)value];
    }
    
    return labelText;
}

- (NSString *)graphView:(GraphView *)graphView labelForSectionAtIndex:(NSUInteger)index
{
	if (selectedTab == 0) {
		if ([((showWeeks) ? self.sortedWeeklyReports : self.sortedDailyReports) count] > index) {
			Report *report = [((showWeeks) ? self.sortedWeeklyReports : self.sortedDailyReports) objectAtIndex:index];
			NSDateFormatter *monthFormatter = [[[NSDateFormatter alloc] init] autorelease];
			[monthFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
			[monthFormatter setDateFormat:@"MMM '´'yy"];
			return [monthFormatter stringFromDate:report.startDate];
		} else {
			return @"N/A";
		}
	} else {
		if ([self.sortedCalendarMonthReports count] > index) {
			id<ReportSummary> report = [self.sortedCalendarMonthReports objectAtIndex:index];
			NSDateFormatter *yearFormatter = [[[NSDateFormatter alloc] init] autorelease];
			[yearFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
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
		if (!self.selectedProducts || [self.selectedProducts containsObject:product]) {
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

- (void)graphView:(GraphView *)view didSelectBarAtIndex:(NSUInteger)index withFrame:(CGRect)barFrame
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
	vc.selectedProduct = [self.selectedProducts lastObject];
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
		[self.navigationController pushViewController:vc animated:YES];
	} else {
		if (self.selectedReportPopover.isPopoverVisible) {
			ReportDetailViewController *selectedReportDetailViewController = (ReportDetailViewController *)[[(UINavigationController *)self.selectedReportPopover.contentViewController viewControllers] objectAtIndex:0];
			if (selectedReportDetailViewController.selectedReportIndex == index) {
				[self.selectedReportPopover dismissPopoverAnimated:YES];
				return;
			} else {
				[self.selectedReportPopover dismissPopoverAnimated:NO];
			}
		}
		UINavigationController *nav = [[[UINavigationController alloc] initWithRootViewController:vc] autorelease];
		self.selectedReportPopover = [[[UIPopoverController alloc] initWithContentViewController:nav] autorelease];
		self.selectedReportPopover.passthroughViews = [NSArray arrayWithObjects:self.graphView, nil];
		if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
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
		self.activeSheet = [[[UIActionSheet alloc] initWithTitle:nil 
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
		self.activeSheet.tag = kSheetTagAdvancedViewMode;
		[self.activeSheet showInView:self.navigationController.view];
	}
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[super tableView:tableView didSelectRowAtIndexPath:indexPath];
	[self.graphView reloadValuesAnimated:YES];
}

#pragma mark -

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:ASViewSettingsDidChangeNotification object:nil];
	
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
