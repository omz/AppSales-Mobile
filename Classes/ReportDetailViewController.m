//
//  ReportDetailViewController.m
//  AppSales
//
//  Created by Ole Zorn on 21.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "ReportDetailViewController.h"
#import "MapView.h"
#import "AppIconView.h"
#import "ASAccount.h"
#import "Report.h"
#import "Product.h"
#import "CurrencyManager.h"
#import "ReportCSVViewController.h"
#import "ReportDetailEntryCell.h"
#import "ReportDetailEntry.h"
#import "CountryDictionary.h"

#define kSettingReportDetailMapHidden @"ReportDetailMapHidden"

@implementation ReportDetailViewController

@synthesize selectedReport, selectedReportIndex, mapView, mapShadowView, shadowView, tableView;
@synthesize prevItem, nextItem;
@synthesize countryEntries, productEntries;
@synthesize selectedCountry, selectedProduct;

- (instancetype)initWithReports:(NSArray *)reportsArray selectedIndex:(NSInteger)selectedIndex {
	self = [super init];
	if (self) {
		reports = reportsArray;
		selectedReportIndex = selectedIndex;
		self.selectedReport = reports[selectedReportIndex];
		mapHidden = [[NSUserDefaults standardUserDefaults] boolForKey:kSettingReportDetailMapHidden];
		self.preferredContentSize = CGSizeMake(320.0f, 500.0f);
	}
	return self;
}

- (void)loadView {
	[super loadView];
	self.edgesForExtendedLayout = UIRectEdgeNone;
	
	if (@available(iOS 13.0, *)) {
		self.view.backgroundColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
			switch (traitCollection.userInterfaceStyle) {
				case UIUserInterfaceStyleDark:
					return [UIColor colorWithRed:14.0f/255.0f green:14.0f/255.0f blue:15.0f/255.0f alpha:1.0f];
				default:
					return [UIColor colorWithRed:111.0f/255.0f green:113.0f/255.0f blue:121.0f/255.0f alpha:1.0f];
			}
		}];
	} else {
		self.view.backgroundColor = [UIColor colorWithRed:111.0f/255.0f green:113.0f/255.0f blue:121.0f/255.0f alpha:1.0f];
	}
	
	numberFormatter = [[NSNumberFormatter alloc] init];
	numberFormatter.locale = [NSLocale currentLocale];
	numberFormatter.formatterBehavior = NSNumberFormatterBehavior10_4;
	numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
	numberFormatter.maximumFractionDigits = 0;
	numberFormatter.minimumFractionDigits = 0;
	
	viewMode = self.selectedProduct ? ReportDetailViewModeCountries : ReportDetailViewModeProducts;
	
	mapHidden = mapHidden || UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation);
	self.mapView = [[MapView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.bounds.size.width, 208.0f)];
	mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	mapView.alpha = !mapHidden;
	if (!mapHidden) {
		mapView.report = (Report *)self.selectedReport;
	}
	[self.view addSubview:mapView];
	
	self.mapShadowView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ShadowBottom.png"]];
	mapShadowView.frame = CGRectMake(0.0f, CGRectGetMaxY(mapView.frame), self.view.bounds.size.width, 20.0f);
	mapShadowView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	mapShadowView.alpha = !mapHidden;
	[self.view addSubview:mapShadowView];
	
	UIVisualEffect *visualEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
	headerView = [[UIVisualEffectView alloc] initWithEffect:visualEffect];
	headerView.frame = mapHidden ? CGRectMake(0.0f, 0.0f, self.view.bounds.size.width, 20.0f) : CGRectMake(0.0f, 208.0f - 20.0f, self.view.bounds.size.width, 20.0f);
	headerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[self.view addSubview:headerView];
	
	if (@available(iOS 11.0, *)) {
		headerView.contentView.translatesAutoresizingMaskIntoConstraints = NO;
		[NSLayoutConstraint activateConstraints:@[[headerView.contentView.topAnchor constraintEqualToAnchor:headerView.topAnchor],
												  [headerView.contentView.bottomAnchor constraintEqualToAnchor:headerView.bottomAnchor],
												  [headerView.contentView.leftAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leftAnchor],
												  [headerView.contentView.rightAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.rightAnchor],
												  ]];
	}
	
	headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(30.0f, 0.0f, headerView.bounds.size.width - 40.0f, 20.0f)];
	headerLabel.backgroundColor = [UIColor clearColor];
	headerLabel.font = [UIFont boldSystemFontOfSize:13.0f];
	headerLabel.textColor = [UIColor whiteColor];
	[headerView.contentView addSubview:headerLabel];
	
	headerIconView = [[AppIconView alloc] initWithFrame:CGRectMake(7.0f, 2.0f, 16.0f, 16.0f)];
	headerIconView.image = [UIImage imageNamed:@"AllApps"];
	[headerView.contentView addSubview:headerIconView];
	
	CGRect tableViewFrame = mapHidden ? CGRectMake(0.0f, 20.0f, self.view.bounds.size.width, self.view.bounds.size.height - 20.0f) : CGRectMake(0.0f, 208.0f, self.view.bounds.size.width, self.view.bounds.size.height - 208.0f);
	self.tableView = [[UITableView alloc] initWithFrame:tableViewFrame style:UITableViewStylePlain];
	tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	tableView.backgroundColor = [UIColor clearColor];
	tableView.dataSource = self;
	tableView.delegate = self;
	
	self.tableView.tableHeaderView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ShadowTop.png"]];
	self.tableView.tableFooterView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ShadowBottom.png"]];
	self.tableView.contentInset = UIEdgeInsetsMake(-20.0f, 0.0f, -20.0f, 0.0f);
	
	[self.view addSubview:tableView];
	
	self.shadowView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ShadowBottom.png"]];
	shadowView.frame = mapHidden ? CGRectMake(0.0f, 20.0f, self.view.bounds.size.width, 20.0f) : CGRectMake(0.0f, 208.0f, self.view.bounds.size.width, 20.0f);
	shadowView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	shadowView.alpha = 0.0;
	[self.view addSubview:shadowView];
	
	if (!UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:(mapHidden ? @"ShowMap" : @"HideMap")] style:UIBarButtonItemStylePlain target:self action:@selector(toggleMap:)];
	}
	
	CGFloat segmentWidth = 75.0f;
	UISegmentedControl *modeControl = [[UISegmentedControl alloc] initWithItems:@[NSLocalizedString(@"Apps", nil), NSLocalizedString(@"Countries", nil)]];
	[modeControl setWidth:segmentWidth forSegmentAtIndex:0];
	[modeControl setWidth:segmentWidth forSegmentAtIndex:1];
	modeControl.selectedSegmentIndex = (viewMode == ReportDetailViewModeProducts) ? 0 : 1;
	[modeControl addTarget:self action:@selector(switchMode:) forControlEvents:UIControlEventValueChanged];
	UIBarButtonItem *modeItem = [[UIBarButtonItem alloc] initWithCustomView:modeControl];
	modeItem.width = segmentWidth * 2.0f;
	
	UIBarButtonItem *csvItem = [[UIBarButtonItem alloc] initWithTitle:@"CSV" style:UIBarButtonItemStylePlain target:self action:@selector(showCSV:)];
	csvItem.width = 40.0f;
	self.prevItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Back"] style:UIBarButtonItemStylePlain target:self action:@selector(selectPreviousReport:)];
	self.nextItem  = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Forward"] style:UIBarButtonItemStylePlain target:self action:@selector(selectNextReport:)];
	UIBarButtonItem *flexSpaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	UIBarButtonItem *spaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
	spaceItem.width = 21.0f;
	
	[self updateNavigationButtons];
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
		self.toolbarItems = @[spaceItem, spaceItem, flexSpaceItem, modeItem, flexSpaceItem, spaceItem, csvItem];
	} else {
		self.toolbarItems = @[prevItem, nextItem, flexSpaceItem, modeItem, flexSpaceItem, spaceItem, csvItem];
		self.navigationController.toolbar.translucent = YES;
	}
	
	[self reloadData];
	[self updateHeader];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	UIInterfaceOrientation toInterfaceOrientation = [self relativeOrientationFromTransform:coordinator.targetTransform];
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation) && !self->mapHidden) {
			[self toggleMap:nil];
		}
		self.tableView.contentInset = UIEdgeInsetsMake(-20.0f, 0.0f, -20.0f, 0.0f);
	} completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
		if (!UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:(self->mapHidden ? @"ShowMap" : @"HideMap")] style:UIBarButtonItemStylePlain target:self action:@selector(toggleMap:)];
		} else {
			self.navigationItem.rightBarButtonItem = nil;
		}
	}];
}

- (void)switchMode:(UISegmentedControl *)sender {
	if ([sender selectedSegmentIndex] == 0) {
		viewMode = ReportDetailViewModeProducts;
	} else {
		viewMode = ReportDetailViewModeCountries;
	}
	[self reloadData];
	[self updateHeader];
}

- (void)viewDidLoad {
	[super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.navigationController.toolbarHidden = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	self.navigationController.toolbarHidden = YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return  UIInterfaceOrientationMaskAll;
}

- (void)toggleMap:(id)sender {
	if (mapHidden) {
		mapView.report = (Report *)self.selectedReport;
		mapView.selectedCountry = self.selectedCountry;
		mapView.selectedProduct = self.selectedProduct;
	}
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.4];
	[UIView setAnimationBeginsFromCurrentState:YES];
	if (!mapHidden) {
		tableView.frame = CGRectMake(0.0f, 20.0f, self.view.bounds.size.width, self.view.bounds.size.height - 20.0f);
		headerView.frame = CGRectMake(0.0f, 0.0f, self.view.bounds.size.width, 20.0f);
		shadowView.frame = CGRectMake(0.0f, 20.0f, self.view.bounds.size.width, 20.0f);
		mapView.alpha = 0.0f;
		mapShadowView.alpha = 0.0f;
		self.navigationItem.rightBarButtonItem.image = [UIImage imageNamed:@"ShowMap"];
	} else {
		tableView.frame = CGRectMake(0.0f, 208.0f, self.view.bounds.size.width, self.view.bounds.size.height - 208.0f);
		headerView.frame = CGRectMake(0.0f, 208.0f - 20.0f, self.view.bounds.size.width, 20.0f);
		shadowView.frame = CGRectMake(0.0f, 208.0f, self.view.bounds.size.width, 20.0f);
		shadowView.alpha = 0.0f;
		mapView.alpha = 1.0f;
		mapShadowView.alpha = 1.0f;
		self.navigationItem.rightBarButtonItem.image = [UIImage imageNamed:@"HideMap"];
		[self performSelector:@selector(scrollViewDidScroll:) withObject:tableView afterDelay:0.0];
	}
	[UIView commitAnimations];
	mapHidden = !mapHidden;
	[[NSUserDefaults standardUserDefaults] setBool:mapHidden forKey:kSettingReportDetailMapHidden];
}

- (void)showCSV:(id)sender {
	NSArray *allReports = [self.selectedReport allReports];
	if ([allReports count] == 1) {
		ReportCSVViewController *csvViewController = [[ReportCSVViewController alloc] initWithReport:(Report *)self.selectedReport];
		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:csvViewController];
		[self presentViewController:navController animated:YES completion:nil];
	} else {
		ReportCSVSelectionViewController *csvSelectionController = [[ReportCSVSelectionViewController alloc] initWithReports:allReports];
		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:csvSelectionController];
		[self presentViewController:navController animated:YES completion:nil];
	}
}

- (void)setSelectedReport:(Report *)report {
	if (report == selectedReport) return;
	selectedReport = report;
	
	[self reloadData];
	if (!mapHidden) {
		self.mapView.report = (Report *)self.selectedReport;
	}
}

- (void)reloadData {
	self.navigationItem.title = [selectedReport title];
	NSDictionary *revenuesByCountry = [selectedReport revenueInBaseCurrencyByCountryForProductWithID:self.selectedProduct.productID];
	NSArray *sortedCountries = [revenuesByCountry keysSortedByValueUsingSelector:@selector(compare:)];
	NSMutableArray *sortedEntries = [NSMutableArray array];
	
	NSDictionary *paidDownloadsByCountryAndProduct = [self.selectedReport totalNumberOfPaidDownloadsByCountryAndProduct];
	
	NSDictionary *paidNonRefundDownloadsByCountryAndProduct = [self.selectedReport totalNumberOfPaidNonRefundDownloadsByCountryAndProduct];
	NSDictionary *refundedDownloadsByCountryAndProduct = [self.selectedReport totalNumberOfRefundedDownloadsByCountryAndProduct];
	
	CGFloat totalRevenue = 0.0f;
	if (viewMode == ReportDetailViewModeCountries) {
		totalRevenue = [self.selectedReport totalRevenueInBaseCurrencyForProductWithID:self.selectedProduct.productID inCountry:nil];
	} else {
		totalRevenue = [self.selectedReport totalRevenueInBaseCurrencyForProductWithID:nil inCountry:self.selectedCountry];
	}
	[sortedEntries addObject:[ReportDetailEntry entryWithRevenue:totalRevenue sales:0 percentage:0 subtitle:nil countryCode:@"WW" countryName:nil product:nil]];
	
	for (NSString *country in [sortedCountries reverseObjectEnumerator]) {
		CGFloat revenue = [revenuesByCountry[country] floatValue];
		CGFloat percentage = (totalRevenue > 0.0f) ? revenue / totalRevenue : 0.0f;
		
		NSInteger sales = 0, nonRefunds = 0, refunds = 0;
		if (self.selectedProduct) {
			sales = [paidDownloadsByCountryAndProduct[country.uppercaseString][self.selectedProduct.productID] integerValue];
			nonRefunds = [paidNonRefundDownloadsByCountryAndProduct[country.uppercaseString][self.selectedProduct.productID] integerValue];
			refunds = -[refundedDownloadsByCountryAndProduct[country.uppercaseString][self.selectedProduct.productID] integerValue];
		} else {
			NSDictionary *salesByProduct = paidDownloadsByCountryAndProduct[country.uppercaseString];
			sales = [[[salesByProduct allValues] valueForKeyPath:@"@sum.self"] integerValue];
			
			NSDictionary *nonRefundsByProduct = paidNonRefundDownloadsByCountryAndProduct[country.uppercaseString];
			nonRefunds = [[[nonRefundsByProduct allValues] valueForKeyPath:@"@sum.self"] integerValue];
			
			NSDictionary *refundsByProduct = refundedDownloadsByCountryAndProduct[country.uppercaseString];
			refunds = -[[[refundsByProduct allValues] valueForKeyPath:@"@sum.self"] integerValue];
		}
		
		// Only display if we have something to show.
		if (sales != 0) {
			NSString *subtitle = [NSString stringWithFormat:@"%@ × %@", [numberFormatter stringFromNumber:@(sales)], [[CountryDictionary sharedDictionary] nameForCountryCode:country]];
			if (sales != nonRefunds) {
				subtitle = [NSString stringWithFormat:@"%@ (%@ - %@) × %@", [numberFormatter stringFromNumber:@(sales)], [numberFormatter stringFromNumber:@(nonRefunds)], [numberFormatter stringFromNumber:@(refunds)], [[CountryDictionary sharedDictionary] nameForCountryCode:country]];
			}
			ReportDetailEntry *entry = [ReportDetailEntry entryWithRevenue:revenue sales:sales percentage:percentage subtitle:subtitle countryCode:country countryName:[[CountryDictionary sharedDictionary] nameForCountryCode:country] product:nil];
			[sortedEntries addObject:entry];
		}
	}
	[sortedEntries sortUsingComparator:^NSComparisonResult(ReportDetailEntry *entry1, ReportDetailEntry *entry2) {
		if ([entry1.countryCode isEqualToString:@"WW"]) {
			return NSOrderedAscending;
		} else if ([entry2.countryCode isEqualToString:@"WW"]) {
			return NSOrderedDescending;
		} else if (entry1.revenue > entry2.revenue) {
			return NSOrderedAscending;
		} else if (entry1.revenue < entry2.revenue) {
			return NSOrderedDescending;
		} else if (entry1.sales > entry2.sales) {
			return NSOrderedAscending;
		} else if (entry1.sales < entry2.sales) {
			return NSOrderedDescending;
		}
		return [entry1.countryName.uppercaseString compare:entry2.countryName.uppercaseString];
	}];
	self.countryEntries = [NSArray arrayWithArray:sortedEntries];
	
	NSMutableArray *entries = [NSMutableArray array];
	ReportDetailEntry *allProductsEntry = [ReportDetailEntry entryWithRevenue:totalRevenue sales:0 percentage:0 subtitle:nil countryCode:nil countryName:nil product:nil];
	[entries addObject:allProductsEntry];
	ASAccount *account = [[self.selectedReport firstReport] valueForKey:@"account"];
	NSArray *allProducts = [[account.products allObjects] sortedArrayUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"productID" ascending:NO]]];
	for (Product *product in allProducts) {
		NSString *productID = product.productID;
		CGFloat revenue = [self.selectedReport totalRevenueInBaseCurrencyForProductWithID:productID inCountry:self.selectedCountry];
		NSInteger sales = 0, nonRefunds = 0, refunds = 0;
		if (self.selectedCountry) {
			sales = [paidDownloadsByCountryAndProduct[self.selectedCountry.uppercaseString][productID] integerValue];
			nonRefunds = [paidNonRefundDownloadsByCountryAndProduct[self.selectedCountry.uppercaseString][productID] integerValue];
			refunds = -[refundedDownloadsByCountryAndProduct[self.selectedCountry.uppercaseString][productID] integerValue];
		} else {
			for (NSDictionary *salesByProduct in [paidDownloadsByCountryAndProduct allValues]) {
				sales += [salesByProduct[productID] integerValue];
			}
			for (NSDictionary *nonRefundsByProduct in [paidNonRefundDownloadsByCountryAndProduct allValues]) {
				nonRefunds += [nonRefundsByProduct[productID] integerValue];
			}
			for (NSDictionary *refundsByProduct in [refundedDownloadsByCountryAndProduct allValues]) {
				refunds -= [refundsByProduct[productID] integerValue];
			}
		}
		
		// Only display if we have something to show.
		if (sales != 0) {
			CGFloat percentage = (totalRevenue > 0.0f) ? revenue / totalRevenue : 0.0f;
			NSString *subtitle = [NSString stringWithFormat:@"%@ × %@", [numberFormatter stringFromNumber:@(sales)], product.displayName];
			if (sales != nonRefunds) {
				subtitle = [NSString stringWithFormat:@"%@ (%@ - %@) × %@", [numberFormatter stringFromNumber:@(sales)], [numberFormatter stringFromNumber:@(nonRefunds)], [numberFormatter stringFromNumber:@(refunds)], product.displayName];
			}
			ReportDetailEntry *entry = [ReportDetailEntry entryWithRevenue:revenue sales:sales percentage:percentage subtitle:subtitle countryCode:nil countryName:nil product:product];
			[entries addObject:entry];
		}
	}
	[entries sortUsingComparator:^NSComparisonResult(ReportDetailEntry *entry1, ReportDetailEntry *entry2) {
		if (entry1.product == nil) {
			return NSOrderedAscending;
		} else if (entry2.product == nil) {
			return NSOrderedDescending;
		} else if (entry1.revenue > entry2.revenue) {
			return NSOrderedAscending;
		} else if (entry1.revenue < entry2.revenue) {
			return NSOrderedDescending;
		} else if (entry1.sales > entry2.sales) {
			return NSOrderedAscending;
		} else if (entry1.sales < entry2.sales) {
			return NSOrderedDescending;
		}
		return [entry1.product.displayName.uppercaseString compare:entry2.product.displayName.uppercaseString];
	}];
	self.productEntries = [NSArray arrayWithArray:entries];
	
	[self reloadTableView];
}

- (void)reloadTableView {
	NSInteger selectedCountryIndex = 0;
	NSInteger selectedProductIndex = 0;
	if (self.selectedProduct) {
		NSInteger i = 0;
		for (ReportDetailEntry *productEntry in self.productEntries) {
			if (productEntry.product == self.selectedProduct) {
				selectedProductIndex = i;
				break;
			}
			i++;
		}
	}
	if (self.selectedCountry) {
		NSInteger i = 0;
		for (ReportDetailEntry *countryEntry in self.countryEntries) {
			if ([countryEntry.countryCode isEqual:self.selectedCountry]) {
				selectedCountryIndex = i;
				break;
			}
			i++;
		}
	}
	
	[self.tableView reloadData];
	if (viewMode == ReportDetailViewModeCountries) {
		[self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:selectedCountryIndex inSection:0] animated:NO scrollPosition:UITableViewScrollPositionMiddle];
	} else {
		[self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:selectedProductIndex inSection:0] animated:NO scrollPosition:UITableViewScrollPositionMiddle];
	}
}

- (void)setSelectedReportIndex:(NSUInteger)index {
	selectedReportIndex = index;
	[self updateNavigationButtons];
}

- (void)selectNextReport:(id)sender {
	if (selectedReportIndex >= [reports count] - 1) return;
	self.selectedReportIndex = self.selectedReportIndex + 1;
	self.selectedReport = reports[selectedReportIndex];
}

- (void)updateNavigationButtons {
	self.prevItem.enabled = (selectedReportIndex > 0);
	self.nextItem.enabled = (selectedReportIndex < [reports count]-1);
}

- (void)updateHeader {
	headerIconView.product = nil;
	headerIconView.maskEnabled = (viewMode == ReportDetailViewModeCountries);
	if (viewMode == ReportDetailViewModeCountries) {
		if (self.selectedProduct) {
			headerIconView.product = self.selectedProduct;
			headerLabel.text = self.selectedProduct.displayName;
		} else {
			headerIconView.image = [UIImage imageNamed:@"AllApps"];
			headerLabel.text = NSLocalizedString(@"All Apps", nil);
		}
	} else {
		if (self.selectedCountry) {
			headerIconView.image = [UIImage imageNamed:self.selectedCountry];
			NSString *countryName = [[CountryDictionary sharedDictionary] nameForCountryCode:self.selectedCountry];
			headerLabel.text = countryName;
		} else {
			headerIconView.image = [UIImage imageNamed:@"WW"];
			headerLabel.text = NSLocalizedString(@"All Countries", nil);
		}
	}
}

- (void)selectPreviousReport:(id)sender {
	if (selectedReportIndex <= 0) return;
	self.selectedReportIndex = self.selectedReportIndex - 1;
	self.selectedReport = reports[selectedReportIndex];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (viewMode == ReportDetailViewModeCountries) {
		return [self.countryEntries count];
	} else {
		return [self.productEntries count];
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 44.0f;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *cellIdentifier = @"Cell";
	ReportDetailEntryCell *cell = (ReportDetailEntryCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (!cell) {
		cell = [[ReportDetailEntryCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
	}
	ReportDetailEntry *entry = ((viewMode == ReportDetailViewModeCountries) ? self.countryEntries : self.productEntries)[indexPath.row];
	cell.entry = entry;
    
    if (@available(iOS 13.0, *)) {
        cell.backgroundColor = [UIColor secondarySystemBackgroundColor];
    }
    
	return cell;
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (viewMode == ReportDetailViewModeCountries) {
		if (indexPath.row > 0) {
			self.selectedCountry = [countryEntries[indexPath.row] countryCode];
		} else {
			self.selectedCountry = nil;
		}
		mapView.selectedCountry = self.selectedCountry;
	} else {
		if (indexPath.row > 0) {
			Product *product = [productEntries[indexPath.row] product];
			self.selectedProduct = product;
			mapView.selectedProduct = product;
		} else {
			self.selectedProduct = nil;
			mapView.selectedProduct = nil;
		}
	}
	[self updateHeader];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	self.shadowView.alpha = MAX(0.0f, MIN(1.0f, (scrollView.contentOffset.y - 20.0f) / 20.0f));
}

@end
