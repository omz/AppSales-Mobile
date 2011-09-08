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

#define kSettingReportDetailMapHidden		@"ReportDetailMapHidden"

@implementation ReportDetailViewController

@synthesize selectedReport, selectedReportIndex, mapView, mapShadowView, shadowView, tableView;
@synthesize prevItem, nextItem, toolbar;
@synthesize countryEntries, productEntries;
@synthesize selectedCountry, selectedProduct;
@synthesize headerView, headerLabel, headerIconView;

- (id)initWithReports:(NSArray *)reportsArray selectedIndex:(NSInteger)selectedIndex
{
	self = [super initWithNibName:nil bundle:nil];
	if (self) {
		reports = [reportsArray retain];
		selectedReportIndex = selectedIndex;
		self.selectedReport = [reports objectAtIndex:selectedReportIndex];
		revenueFormatter = [[NSNumberFormatter alloc] init];
		[revenueFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
		[revenueFormatter setMinimumFractionDigits:2];
		[revenueFormatter setMaximumFractionDigits:2];
		mapHidden = [[NSUserDefaults standardUserDefaults] boolForKey:kSettingReportDetailMapHidden];
    }
    return self;
}

- (void)loadView
{
	[super loadView];
	self.view.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
	
	viewMode = (self.selectedProduct) ? ReportDetailViewModeCountries : ReportDetailViewModeProducts;
	
	mapHidden = mapHidden || UIInterfaceOrientationIsLandscape(self.interfaceOrientation);
	self.mapView = [[[MapView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 208)] autorelease];
	mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	mapView.alpha = (mapHidden) ? 0.0 : 1.0;
	if (!mapHidden) {
		mapView.report = self.selectedReport;
	}
	[self.view addSubview:mapView];
	
	self.mapShadowView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ShadowBottom.png"]] autorelease];
	mapShadowView.frame = CGRectMake(0, CGRectGetMaxY(mapView.frame), self.view.bounds.size.width, 20);
	mapShadowView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	mapShadowView.alpha = (mapHidden) ? 0.0 : 1.0;
	[self.view addSubview:mapShadowView];
	
	CGRect headerFrame = (mapHidden) ? CGRectMake(0, 0, self.view.bounds.size.width, 20) : CGRectMake(0, 208-20, self.view.bounds.size.width, 20);
	self.headerView = [[[UIImageView alloc] initWithFrame:headerFrame] autorelease];
	headerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	headerView.image = [UIImage imageNamed:@"DetailHeader.png"];
	self.headerLabel = [[[UILabel alloc] initWithFrame:CGRectMake(30, 0, headerView.bounds.size.width - 40, 20)] autorelease];
	headerLabel.textColor = [UIColor darkGrayColor];
	headerLabel.shadowColor = [UIColor whiteColor];
	headerLabel.shadowOffset = CGSizeMake(0, 1);
	headerLabel.backgroundColor = [UIColor clearColor];
	headerLabel.font = [UIFont boldSystemFontOfSize:13.0];
	[headerView addSubview:headerLabel];
	self.headerIconView = [[[AppIconView alloc] initWithFrame:CGRectMake(7, 2, 16, 16)] autorelease];
	headerIconView.image = [UIImage imageNamed:@"AllApps.png"];
	[headerView addSubview:headerIconView];
	[self.view addSubview:headerView];
	
	CGFloat toolbarHeight = UIInterfaceOrientationIsLandscape(self.interfaceOrientation) ? 32.0 : 44.0;
	
	CGRect tableViewFrame = (mapHidden) ? CGRectMake(0, 20, self.view.bounds.size.width, self.view.bounds.size.height - 20) : CGRectMake(0, 208, self.view.bounds.size.width, self.view.bounds.size.height - 208);
	self.tableView = [[[UITableView alloc] initWithFrame:tableViewFrame style:UITableViewStylePlain] autorelease];
	tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	tableView.backgroundColor = [UIColor clearColor];
	tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, toolbarHeight, 0);
	tableView.dataSource = self;
	tableView.delegate = self;
	
	self.tableView.tableHeaderView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ShadowTop.png"]] autorelease];
	self.tableView.tableFooterView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ShadowBottom.png"]] autorelease];
	self.tableView.contentInset = UIEdgeInsetsMake(-20, 0, toolbarHeight - 20, 0);
	
	[self.view addSubview:tableView];
	
	self.shadowView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ShadowBottom.png"]] autorelease];
	shadowView.frame = (mapHidden) ? CGRectMake(0, 20, self.view.bounds.size.width, 20) : CGRectMake(0, 208, self.view.bounds.size.width, 20);
	shadowView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	shadowView.alpha = 0.0;
	[self.view addSubview:shadowView];
	
	if (!UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:(mapHidden) ? @"ShowMap.png" : @"HideMap.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(toggleMap:)] autorelease];
	}
	
	self.toolbar = [[[UIToolbar alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - toolbarHeight, self.view.bounds.size.width, toolbarHeight)] autorelease];
	toolbar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
	[self.view addSubview:toolbar];
	
	float segmentWidth = 75.0;
	UISegmentedControl *modeControl = [[[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:NSLocalizedString(@"Apps", nil), NSLocalizedString(@"Countries", nil), nil]] autorelease];
	[modeControl setWidth:segmentWidth forSegmentAtIndex:0];
	[modeControl setWidth:segmentWidth forSegmentAtIndex:1];
	modeControl.segmentedControlStyle = UISegmentedControlStyleBar;
	modeControl.selectedSegmentIndex = (viewMode == ReportDetailViewModeProducts) ? 0 : 1;
	[modeControl addTarget:self action:@selector(switchMode:) forControlEvents:UIControlEventValueChanged];
	UIBarButtonItem *modeItem = [[[UIBarButtonItem alloc] initWithCustomView:modeControl] autorelease];
	modeItem.width = 2 * segmentWidth;
	
	UIBarButtonItem *csvItem = [[[UIBarButtonItem alloc] initWithTitle:@"CSV" style:UIBarButtonItemStyleBordered target:self action:@selector(showCSV:)] autorelease];
	csvItem.width = 40.0;
	self.prevItem = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Back.png"] style:UIBarButtonItemStylePlain target:self action:@selector(selectPreviousReport:)] autorelease];
	self.nextItem  = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Forward.png"] style:UIBarButtonItemStylePlain target:self action:@selector(selectNextReport:)] autorelease];
	UIBarButtonItem *flexSpaceItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
	UIBarButtonItem *spaceItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil] autorelease];
	spaceItem.width = 21.0;
	
	[self updateNavigationButtons];
	toolbar.items = [NSArray arrayWithObjects:prevItem, nextItem, flexSpaceItem, modeItem, flexSpaceItem, spaceItem, csvItem, nil];
	toolbar.translucent = YES;
	
	[self reloadData];
	[self updateHeader];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation) && !mapHidden) {
		[self toggleMap:nil];
	}
	CGFloat toolbarHeight = UIInterfaceOrientationIsLandscape(toInterfaceOrientation) ? 32.0 : 44.0;
	self.toolbar.frame = CGRectMake(0, self.view.bounds.size.height - toolbarHeight, self.view.bounds.size.width, toolbarHeight);
	self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, toolbarHeight, 0);
	self.tableView.contentInset = UIEdgeInsetsMake(-20, 0, toolbarHeight - 20, 0);
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	if (!UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:(mapHidden) ? @"ShowMap.png" : @"HideMap.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(toggleMap:)] autorelease];
	} else {
		self.navigationItem.rightBarButtonItem = nil;
	}
}

- (void)switchMode:(UISegmentedControl *)sender
{
	if ([sender selectedSegmentIndex] == 0) {
		viewMode = ReportDetailViewModeProducts;
	} else {
		viewMode = ReportDetailViewModeCountries;
	}
	[self reloadData];
	[self updateHeader];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
}

- (void)viewDidUnload
{
	[super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return (interfaceOrientation == UIInterfaceOrientationPortrait || UIInterfaceOrientationIsLandscape(interfaceOrientation));
}

- (void)toggleMap:(id)sender
{
	if (mapHidden) {
		mapView.report = self.selectedReport;
		mapView.selectedCountry = self.selectedCountry;
		mapView.selectedProduct = self.selectedProduct;
	}
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.4];
	[UIView setAnimationBeginsFromCurrentState:YES];
	if (!mapHidden) {
		tableView.frame = CGRectMake(0, 20, self.view.bounds.size.width, self.view.bounds.size.height - 20);
		headerView.frame = CGRectMake(0, 0, self.view.bounds.size.width, 20);
		shadowView.frame = CGRectMake(0, 20, self.view.bounds.size.width, 20);
		mapView.alpha = 0.0;
		mapShadowView.alpha = 0.0;
		self.navigationItem.rightBarButtonItem.image = [UIImage imageNamed:@"ShowMap.png"];
	} else {
		tableView.frame = CGRectMake(0, 208, self.view.bounds.size.width, 208);
		headerView.frame = CGRectMake(0, 208-20, self.view.bounds.size.width, 20);
		shadowView.frame = CGRectMake(0, 208, self.view.bounds.size.width, 20);
		shadowView.alpha = 0.0;
		mapView.alpha = 1.0;
		mapShadowView.alpha = 1.0;
		self.navigationItem.rightBarButtonItem.image = [UIImage imageNamed:@"HideMap.png"];
		[self performSelector:@selector(scrollViewDidScroll:) withObject:tableView afterDelay:0.0];
	}
	[UIView commitAnimations];
	mapHidden = !mapHidden;
	[[NSUserDefaults standardUserDefaults] setBool:mapHidden forKey:kSettingReportDetailMapHidden];
}

- (void)showCSV:(id)sender
{
	NSArray *allReports = [self.selectedReport allReports];
	if ([allReports count] == 1) {
		ReportCSVViewController *csvViewController = [[[ReportCSVViewController alloc] initWithReport:self.selectedReport] autorelease];
		UINavigationController *navController = [[[UINavigationController alloc] initWithRootViewController:csvViewController] autorelease];
		[self presentModalViewController:navController animated:YES];
	} else {
		ReportCSVSelectionViewController *csvSelectionController = [[[ReportCSVSelectionViewController alloc] initWithReports:allReports] autorelease];
		UINavigationController *navController = [[[UINavigationController alloc] initWithRootViewController:csvSelectionController] autorelease];
		[self presentModalViewController:navController animated:YES];
	}
}

- (void)setSelectedReport:(Report *)report
{
	if (report == selectedReport) return;
	[report retain];
	[selectedReport release];
	selectedReport = report;
	
	[self reloadData];
	if (!mapHidden) {
		self.mapView.report = self.selectedReport;
	}
}

- (void)reloadData
{
	self.navigationItem.title = [selectedReport title];
	NSDictionary *revenuesByCountry = [selectedReport revenueInBaseCurrencyByCountryForProductWithID:self.selectedProduct.productID];
	NSArray *sortedCountries = [revenuesByCountry keysSortedByValueUsingSelector:@selector(compare:)];
	NSMutableArray *sortedEntries = [NSMutableArray array];
	
	NSDictionary *paidDownloadsByCountryAndProduct = [self.selectedReport totalNumberOfPaidDownloadsByCountryAndProduct];
	
	float totalRevenue;
	if (viewMode == ReportDetailViewModeCountries) {
		totalRevenue = [self.selectedReport totalRevenueInBaseCurrencyForProductWithID:self.selectedProduct.productID inCountry:nil];
	} else {
		totalRevenue = [self.selectedReport totalRevenueInBaseCurrencyForProductWithID:nil inCountry:self.selectedCountry];
	}
	
	[sortedEntries addObject:[ReportDetailEntry entryWithRevenue:totalRevenue percentage:0 subtitle:nil country:@"world" product:nil]];
	
	for (NSString *country in [sortedCountries reverseObjectEnumerator]) {
		float revenue = [[revenuesByCountry objectForKey:country] floatValue];
		float percentage = (totalRevenue > 0) ? revenue / totalRevenue : 0.0;
		
		NSInteger sales = 0;
		if (self.selectedProduct) {
			sales = [[[paidDownloadsByCountryAndProduct objectForKey:[country uppercaseString]] objectForKey:self.selectedProduct.productID] integerValue];
		} else {
			NSDictionary *salesByProduct = [paidDownloadsByCountryAndProduct objectForKey:[country uppercaseString]];
			sales = [[[salesByProduct allValues] valueForKeyPath:@"@sum.self"] integerValue];
		}
		NSString *subtitle = [NSString stringWithFormat:@"%@: %i %@", [[CountryDictionary sharedDictionary] nameForCountryCode:country], sales, sales == 1 ? @"sale" : @"sales"];
		ReportDetailEntry *entry = [ReportDetailEntry entryWithRevenue:revenue percentage:percentage subtitle:subtitle country:country product:nil];
		[sortedEntries addObject:entry];
	}
	self.countryEntries = [NSArray arrayWithArray:sortedEntries];
	
	NSMutableArray *entries = [NSMutableArray array];
	ReportDetailEntry *allProductsEntry = [ReportDetailEntry entryWithRevenue:totalRevenue percentage:0 subtitle:nil country:nil product:nil];
	[entries addObject:allProductsEntry];
	ASAccount *account = [[self.selectedReport firstReport] valueForKey:@"account"];
	NSArray *allProducts = [[account.products allObjects] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"productID" ascending:NO] autorelease]]];
	for (Product *product in allProducts) {
		NSString *productID = product.productID;
		float revenue = [self.selectedReport totalRevenueInBaseCurrencyForProductWithID:productID inCountry:self.selectedCountry];
		NSInteger sales = 0;
		if (self.selectedCountry) {
			sales = [[[paidDownloadsByCountryAndProduct objectForKey:[self.selectedCountry uppercaseString]] objectForKey:productID] integerValue];
		} else {
			for (NSDictionary *salesByProduct in [paidDownloadsByCountryAndProduct allValues]) {
				sales += [[salesByProduct objectForKey:productID] integerValue];
			}
		}		
		float percentage = (totalRevenue > 0) ? revenue / totalRevenue : 0.0;
		NSString *subtitle = [NSString stringWithFormat:@"%i × %@", sales, [product displayName]];
		ReportDetailEntry *entry = [ReportDetailEntry entryWithRevenue:revenue percentage:percentage subtitle:subtitle country:nil product:product];
		[entries addObject:entry];
	}
	[entries sortUsingDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"revenue" ascending:NO] autorelease]]];
	
	self.productEntries = [NSArray arrayWithArray:entries];
	[self reloadTableView];
}

- (void)reloadTableView
{
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
			if ([countryEntry.country isEqual:self.selectedCountry]) {
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

- (void)setSelectedReportIndex:(NSUInteger)index
{
	selectedReportIndex = index;
	[self updateNavigationButtons];
}

- (void)selectNextReport:(id)sender
{
	if (selectedReportIndex >= [reports count] - 1) return;
	self.selectedReportIndex = self.selectedReportIndex + 1;
	self.selectedReport = [reports objectAtIndex:selectedReportIndex];
}

- (void)updateNavigationButtons
{
	self.prevItem.enabled = (selectedReportIndex > 0);
	self.nextItem.enabled = (selectedReportIndex < [reports count]-1);
}

- (void)updateHeader
{
	if (viewMode == ReportDetailViewModeCountries) {
		if (self.selectedProduct) {
			self.headerIconView.productID = self.selectedProduct.productID;
			self.headerLabel.text = [self.selectedProduct displayName];
		} else {
			self.headerIconView.productID = nil;
			self.headerIconView.image = [UIImage imageNamed:@"AllApps.png"];
			self.headerLabel.text = NSLocalizedString(@"All Apps", nil);
		}
	} else {
		self.headerIconView.productID = nil;
		if (self.selectedCountry) {
			self.headerIconView.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png", [self.selectedCountry lowercaseString]]];
			NSString *countryName = [[CountryDictionary sharedDictionary] nameForCountryCode:self.selectedCountry];
			self.headerLabel.text = countryName;
		} else {
			self.headerIconView.image = [UIImage imageNamed:@"world.png"];
			self.headerLabel.text = NSLocalizedString(@"All Countries", nil);
		}
	}
}

- (void)selectPreviousReport:(id)sender
{
	if (selectedReportIndex <= 0) return;
	self.selectedReportIndex = self.selectedReportIndex - 1;
	self.selectedReport = [reports objectAtIndex:selectedReportIndex];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (viewMode == ReportDetailViewModeCountries) {
		return [self.countryEntries count];
	} else {
		return [self.productEntries count];
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 40.0;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString *cellIdentifier = @"Cell";
	ReportDetailEntryCell *cell = (ReportDetailEntryCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (!cell) {
		cell = [[[ReportDetailEntryCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
	}
	ReportDetailEntry *entry = [(viewMode == ReportDetailViewModeCountries) ? self.countryEntries : self.productEntries objectAtIndex:indexPath.row];
	cell.entry = entry;
	return cell;
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (viewMode == ReportDetailViewModeCountries) {
		if (indexPath.row > 0) {
			self.selectedCountry = [[countryEntries objectAtIndex:indexPath.row] country];
		} else {
			self.selectedCountry = nil;
		}
		mapView.selectedCountry = self.selectedCountry;
	} else {
		if (indexPath.row > 0) {
			Product *product = [[productEntries objectAtIndex:indexPath.row] product];
			self.selectedProduct = product;
			mapView.selectedProduct = product;
		} else {
			self.selectedProduct = nil;
			mapView.selectedProduct = nil;
		}
	}
	[self updateHeader];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	self.shadowView.alpha = MAX(0.0, MIN(1.0, (scrollView.contentOffset.y - 20) / 20.0));
}

- (void)dealloc
{
	[toolbar release];
	[headerView release];
	[headerLabel release];
	[headerIconView release];
	[revenueFormatter release];
	[reports release];
	[selectedReport release];
	[super dealloc];
}

@end


