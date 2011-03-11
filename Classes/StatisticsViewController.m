//
//  StatisticsViewController.m
//  AppSalesMobile
//
//  Created by Ole Zorn on 15.02.09.
//  Copyright 2009 omz:software. All rights reserved.
//

#import "StatisticsViewController.h"
#import "TrendGraphView.h"
#import "RegionsGraphView.h"
#import "Day.h"
#import "ReportManager.h"
#import "CurrencyManager.h"
#import "Entry.h"
#import "Country.h"
#import "NSDateFormatter+SharedInstances.h"


@implementation StatisticsViewController

@synthesize allAppsTrendView, regionsGraphView, trendViewsForApps, scrollView, pageControl, datePicker, days, selectedDays;

- (void)loadView 
{
	[super loadView];
	
	self.navigationItem.title = NSLocalizedString(@"Graphs",nil);
	
	self.trendViewsForApps = [NSMutableArray array];
	
	UIImageView *scrollBackground = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 200)] autorelease];
	scrollBackground.image = [UIImage imageNamed:@"GraphScrollBackground.png"];
	[self.view addSubview:scrollBackground];
	
	self.pageControl = [[[UIPageControl alloc] initWithFrame:CGRectMake(0, 197, 320, 10)] autorelease];
	pageControl.numberOfPages = 1;
	pageControl.backgroundColor = [UIColor colorWithHue:0.6527f saturation:0.13 brightness:0.35 alpha:1.0f];
	[pageControl addTarget:self action:@selector(changePage:) forControlEvents:UIControlEventValueChanged];
	[self.view addSubview:pageControl];
	
	self.scrollView = [[[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, 320, 200)] autorelease];
	scrollView.backgroundColor = [UIColor clearColor];
	scrollView.pagingEnabled = YES;
	scrollView.contentSize = CGSizeMake(640, 200);
	scrollView.showsVerticalScrollIndicator = NO;
	scrollView.showsHorizontalScrollIndicator = NO;
	scrollView.delegate = self;
	
	self.regionsGraphView = [[[RegionsGraphView alloc] initWithFrame:CGRectMake(0, 0, 320, 200)] autorelease];
	[scrollView addSubview:regionsGraphView];
	
	self.allAppsTrendView = [[[TrendGraphView alloc] initWithFrame:CGRectMake(320, 0, 320, 200)] autorelease];
	[scrollView addSubview:allAppsTrendView];
	
	[self.view addSubview:scrollView];
	
	self.datePicker = [[[UIPickerView alloc] initWithFrame:CGRectMake(0, 207, 320, 100)] autorelease];
	datePicker.showsSelectionIndicator = YES;
	datePicker.delegate = self;
	datePicker.dataSource = self;
	[self.view addSubview:datePicker];
	
	UIButton *dateButton = [UIButton buttonWithType:UIButtonTypeCustom];
	dateButton.frame = CGRectMake(272, 293, 30, 45);
	[dateButton setImage:[UIImage imageNamed:@"DateButtonNormal.png"] forState:UIControlStateNormal];
	[dateButton setImage:[UIImage imageNamed:@"DateButtonHighlight.png"] forState:UIControlStateHighlighted];
	[self.view addSubview:dateButton];
	[dateButton addTarget:self action:@selector(selectDate:) forControlEvents:UIControlEventTouchUpInside];
	
	graphModeButton = [[[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStyleBordered target:self action:@selector(toggleGraphMode)] autorelease];
	[self updateGraphModeButton];
	self.navigationItem.rightBarButtonItem = graphModeButton;
	
	[self reloadDays];
    /*
	//insert the weeks older than the oldest daily report
	NSMutableArray *allDays = [[sortedDays mutableCopy] autorelease];
	Day *oldestDayReport = [sortedDays objectAtIndex:0];
	// we don't want to calculate this each time in the following loop
	NSTimeInterval oldestDayReportInterval = [oldestDayReport.date timeIntervalSince1970];	
	NSSortDescriptor *weekSorter = [[[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO] autorelease];
	NSArray *sortedWeeks = [[[ReportManager sharedManager].weeks allValues] sortedArrayUsingDescriptors:[NSArray arrayWithObject:weekSorter]]; 
	BOOL weeksInserite = NO;
	for (Day *w in sortedWeeks) {
		if ([w.date timeIntervalSince1970] < oldestDayReportInterval) {
			if(!weeksInserite){ //delete the days that is in the week
				NSDateComponents *comp = [[[NSDateComponents alloc] init] autorelease];
				[comp setHour:167];
				NSDate *dateWeekLater = [[NSCalendar currentCalendar] dateByAddingComponents:comp toDate:w.date options:0];
				while ([((Day *)[allDays objectAtIndex:0]).date timeIntervalSince1970] < [dateWeekLater timeIntervalSince1970]) {
					[allDays removeObjectAtIndex:0];
				}				
			}
			[allDays insertObject:w atIndex:0];
			weeksInserite = YES;
		}
	}
	*/
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadDays)
												 name:ReportManagerDownloadedDailyReportsNotification object:nil];
	
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	//show last 7 days by default:
	int fromRow = [days count] - 7;
	if (fromRow < 0) fromRow = 0;
	int toRow = [days count] - 1;
	
	[datePicker selectRow:fromRow inComponent:0 animated:NO];
	[datePicker selectRow:toRow inComponent:1 animated:NO];
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self reload];
}

- (void)toggleGraphMode
{
	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"ShowUnitsInGraphs"]) { //sales
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"ShowUnitsInGraphs"];
	}
	else { //revenue
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"ShowUnitsInGraphs"];
	}
	[self updateGraphModeButton];
	[allAppsTrendView setNeedsDisplay];
	[regionsGraphView setNeedsDisplay];
	for (UIView *v in trendViewsForApps) {
		[v setNeedsDisplay];
	}
}

- (void)updateGraphModeButton
{
	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"ShowUnitsInGraphs"]) {
		[graphModeButton setTitle:@"#"];
	}
	else {
		//[graphModeButton setTitle:@"$"];
		[graphModeButton setTitle:[[CurrencyManager sharedManager] baseCurrencyDescription]];
		
	}
}

- (void)reloadDays
{
    NSSortDescriptor *dateSorter = [[[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES] autorelease];
	NSArray *sortedDays = [[[ReportManager sharedManager].days allValues] sortedArrayUsingDescriptors:[NSArray arrayWithObject:dateSorter]];
    self.days = sortedDays;
    [datePicker reloadAllComponents];
    [self reload];
}

- (void)reload
{
	if (!self.days || [self.days count] == 0)
		return;
	
	int fromIndex = [datePicker selectedRowInComponent:0];
	int toIndex = [datePicker selectedRowInComponent:1];
	
	allAppsTrendView.days = nil;
	regionsGraphView.days = nil;
	
	if (fromIndex > toIndex) {
		int temp = toIndex;
		toIndex = fromIndex;
		fromIndex = temp;
	}
    
	NSRange selectedRange = NSMakeRange(fromIndex, toIndex - fromIndex + 1);
	self.selectedDays = [self.days subarrayWithRange:selectedRange];
	
	// this is gross!  There should be a way to lookup an app name by it's id, and the converse
	NSMutableDictionary *appNamesByAppId = [NSMutableDictionary dictionary];
	for (Day *d in selectedDays) {
		for (Country *c in d.countries.allValues) {
			for (Entry *e in c.entries) { // O(N^3) for a simple lookup?  You know it baby!
				[appNamesByAppId setObject:e.productName forKey:e.productIdentifier];
			}
		}
	}
    //sort apps by app id, so that the app with the highest id (latest release date) is shown first:
    NSArray *allAppIDs = [[appNamesByAppId allKeys] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:nil ascending:NO selector:@selector(compare:)] autorelease]]];
    
	for (UIView *v in self.trendViewsForApps) {
		[v removeFromSuperview];
	}
	[trendViewsForApps removeAllObjects];
	float x = 640.0;
	for (NSString *appID in allAppIDs) {
		TrendGraphView *trendView = [[[TrendGraphView alloc] initWithFrame:CGRectMake(x, 0, 320, 200)] autorelease];
		trendView.days = nil;
		trendView.appName = [appNamesByAppId objectForKey:appID];
		trendView.appID = appID;// [appIdByAppName objectForKey:appName];
		[trendViewsForApps addObject:trendView];
		[self.scrollView addSubview:trendView];
		x += 320;
	}
	self.scrollView.contentSize = CGSizeMake(640.0 + [trendViewsForApps count] * 320.0, 200);
	
	self.pageControl.numberOfPages = [allAppIDs count] + 2;
	
	[self scrollViewDidEndDecelerating:scrollView];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)aScrollView
{
	if (!self.days || [self.days count] == 0)
		return; 

	if (!pageControlUsed) {	
		CGFloat pageWidth = aScrollView.frame.size.width;
		int page = floor((aScrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
		pageControl.currentPage = page;
	}
	pageControlUsed = NO;
	
	CGPoint offset = scrollView.contentOffset;
	
	float x = offset.x;
	if (x <= 640) {
		regionsGraphView.days = self.selectedDays;
		allAppsTrendView.days = self.selectedDays;
		//NSLog(@"regions and all apps charts filled");
	}
	
	int visibleChartIndex = 0;
	visibleChartIndex = (x - 640) / 320;
	
	if (visibleChartIndex == -1) visibleChartIndex = 0;
	if (visibleChartIndex < 0) return;
	if (visibleChartIndex > [trendViewsForApps count] - 1) visibleChartIndex = [trendViewsForApps count] - 1;
	
	TrendGraphView *visibleChart = [trendViewsForApps objectAtIndex:visibleChartIndex];
	visibleChart.days = self.selectedDays;
	//NSLog(@"trend view for app %i filled", visibleChartIndex);
	if (visibleChartIndex > 0) {
		TrendGraphView *visibleChart = [trendViewsForApps objectAtIndex:visibleChartIndex - 1];
		//NSLog(@"previous chart filled");
		visibleChart.days = self.selectedDays;
	}
	if (visibleChartIndex < [trendViewsForApps count] - 1) {
		if (((x - 640) / 320) >= 0) {
			//NSLog(@"Next chart filled");
			TrendGraphView *visibleChart = [trendViewsForApps objectAtIndex:visibleChartIndex + 1];
			visibleChart.days = self.selectedDays;
		}
	}
}

- (void)changePage:(id)sender{
	pageControlUsed = YES;
	int page = pageControl.currentPage;
	CGRect frame = scrollView.frame;
	frame.origin.x = frame.size.width * page;
	frame.origin.y = 0;
	[scrollView scrollRectToVisible:frame animated:YES];
	[self scrollViewDidEndDecelerating:scrollView];
}

- (void)selectDate:(id)sender
{
	if ([self.days count] == 0)
		return;
	
	int lastMonth = -1;
	NSMutableArray *months = [NSMutableArray array];
	NSCalendar *gregorian = [NSCalendar currentCalendar];
	NSDateFormatter *monthFormatter = [[NSDateFormatter new] autorelease];
	[monthFormatter setDateFormat:@"MMMM yyyy"];
	for (Day *d in [self.days reverseObjectEnumerator]) {
		NSDateComponents *comps = [gregorian components:NSMonthCalendarUnit fromDate:d.date];
		int month = [comps month];
		if (month != lastMonth) {
			[months addObject:[monthFormatter stringFromDate:d.date]];
			lastMonth = month;
		}
		if ([months count] >= 3)
			break;
	}
	
	UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"" message:@"" delegate:self 
										   cancelButtonTitle:NSLocalizedString(@"Cancel",nil) otherButtonTitles:nil] autorelease];
	[alert addButtonWithTitle:NSLocalizedString(@"All Time",nil)];
	[alert addButtonWithTitle:NSLocalizedString(@"Last 7 Days",nil)];
	[alert addButtonWithTitle:NSLocalizedString(@"Last 30 Days",nil)];
	int i = 2; // alertView acts screwy if too many entries are present
	for (NSString *monthButton in months) {
		[alert addButtonWithTitle:monthButton];
		if (--i == 0) {
			break; // stop adding buttons, otherwise they'll run off the dialog
		}
	}
	
	[alert show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	//TODO: This is really messy, got to clean it up sometime...
	int fromIndex = 0;
	int toIndex = 0;
	//NSLog(@"%i", buttonIndex);
	if (buttonIndex == 0) {
		//NSLog(@"Cancel");
		return;
	}
	else if (buttonIndex == 1) {
		toIndex = [self.days count] - 1;
		fromIndex = 0;
	}
	else if (buttonIndex == 2) {
		//Last 7 days
		toIndex = [self.days count] - 1;
		fromIndex = [self.days count] - 7;
		if (fromIndex < 0) fromIndex = 0;
	}
	else if (buttonIndex == 3) {
		//Last 7 days
		toIndex = [self.days count] - 1;
		fromIndex = [self.days count] - 30;
		if (fromIndex < 0) fromIndex = 0;
	}
	else if (buttonIndex == 4) {
		//NSLog(@"This month");
		fromIndex = [self.days count] - 1;
		toIndex = fromIndex;
		int lastMonth = -1;
		int months = 0;
		NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
        for (Day *d in [self.days reverseObjectEnumerator]) {
			NSDateComponents *comps = [gregorian components:NSMonthCalendarUnit fromDate:d.date];
			int month = [comps month];
			if (month != lastMonth) {
				months++;
			}
			if (months > 1) {
				break;
			}
			if ((months == 1) && (lastMonth != -1)) {
				fromIndex--;
			}
			lastMonth = month;
		}
	}
	else if (buttonIndex == 5) {
		//NSLog(@"Last month");
		fromIndex = [self.days count] - 1;
		toIndex = fromIndex;
		int i = toIndex;
		int lastMonth = -1;
		int months = 0;
		NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
        for (Day *d in [self.days reverseObjectEnumerator]) {
			NSDateComponents *comps = [gregorian components:NSMonthCalendarUnit fromDate:d.date];
			int month = [comps month];
			if (month != lastMonth) {
				months++;
				if (months == 2) {
					toIndex = i;
				}
			}
			if (months == 3) {
				break;
			}
			if ((months <= 2) && (lastMonth != -1)) {
				fromIndex--;
			}
			lastMonth = month;
			i--;
		}
	}
	else if (buttonIndex == 6) {
		//NSLog(@"Two months ago");
		fromIndex = [self.days count] - 1;
		toIndex = fromIndex;
		int i = toIndex;
		int lastMonth = -1;
		int months = 0;
		NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
        for (Day *d in [self.days reverseObjectEnumerator]) {
			NSDateComponents *comps = [gregorian components:NSMonthCalendarUnit fromDate:d.date];
			int month = [comps month];
			if (month != lastMonth) {
				months++;
				if (months == 3) {
					toIndex = i;
				}
			}
			if (months == 4) {
				break;
			}
			if ((months <= 3) && (lastMonth != -1)) {
				fromIndex--;
			}
			lastMonth = month;
			i--;
		}
	}
	else if (buttonIndex == 7) {
		//NSLog(@"Three months ago");
		fromIndex = [self.days count] - 1;
		toIndex = fromIndex;
		int i = toIndex;
		int lastMonth = -1;
		int months = 0;
		NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
        for (Day *d in [self.days reverseObjectEnumerator]) {
			NSDateComponents *comps = [gregorian components:NSMonthCalendarUnit fromDate:d.date];
			int month = [comps month];
			if (month != lastMonth) {
				months++;
				if (months == 4) {
					toIndex = i;
				}
			}
			if (months == 5) {
				break;
			}
			if ((months <= 4) && (lastMonth != -1)) {
				fromIndex--;
			}
			lastMonth = month;
			i--;
		}
	}
	
	[datePicker selectRow:fromIndex inComponent:0 animated:NO];
	[datePicker selectRow:toIndex inComponent:1 animated:NO];
	[self reload];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
	[self reload];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
	return [[NSDateFormatter sharedShortDateFormatter] stringFromDate:[[days objectAtIndex:row] date]];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
	return 2;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
	return [days count];
}

- (void)dealloc 
{
	self.days = nil;
	self.datePicker = nil;
	self.trendViewsForApps = nil;
	self.regionsGraphView = nil;
	
    [super dealloc];
}


@end
