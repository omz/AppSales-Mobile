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

@implementation StatisticsViewController

@synthesize allAppsTrendView, regionsGraphView, trendViewsForApps, scrollView, datePicker, days, selectedDays, dateFormatter;

- (void)loadView 
{
	[super loadView];
	
	self.navigationItem.title = NSLocalizedString(@"Charts",nil);
	
	self.trendViewsForApps = [NSMutableArray array];
	
	self.dateFormatter = [[NSDateFormatter new] autorelease];
	[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
	
	UIImageView *scrollBackground = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 200)] autorelease];
	scrollBackground.image = [UIImage imageNamed:@"GraphScrollBackground.png"];
	[self.view addSubview:scrollBackground];
	
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
	
	self.datePicker = [[[UIPickerView alloc] initWithFrame:CGRectMake(0, 200, 320, 100)] autorelease];
	datePicker.showsSelectionIndicator = YES;
	datePicker.delegate = self;
	datePicker.dataSource = self;
	[self.view addSubview:datePicker];
	
	UIButton *dateButton = [UIButton buttonWithType:UIButtonTypeCustom];
	dateButton.frame = CGRectMake(272, 287, 30, 45);
	[dateButton setImage:[UIImage imageNamed:@"DateButtonNormal.png"] forState:UIControlStateNormal];
	[dateButton setImage:[UIImage imageNamed:@"DateButtonHighlight.png"] forState:UIControlStateHighlighted];
	[self.view addSubview:dateButton];
	[dateButton addTarget:self action:@selector(selectDate:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)viewDidLoad
{
	//show last 7 days by default:
	int fromRow = [days count] - 7;
	if (fromRow < 0) fromRow = 0;
	int toRow = [days count] - 1;
	
	[datePicker selectRow:fromRow inComponent:0 animated:NO];
	[datePicker selectRow:toRow inComponent:1 animated:NO];
	
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
	
	NSMutableSet *allApps = [NSMutableSet set];
	for (Day *d in selectedDays) {
		[allApps addObjectsFromArray:[d allProductNames]];
	}
	NSArray *allAppsSorted = [[allApps allObjects] sortedArrayUsingSelector:@selector(compare:)];
	for (UIView *v in self.trendViewsForApps) {
		[v removeFromSuperview];
	}
	[trendViewsForApps removeAllObjects];
	float x = 640.0;
	for (NSString *app in allAppsSorted) {
		TrendGraphView *trendView = [[[TrendGraphView alloc] initWithFrame:CGRectMake(x, 0, 320, 200)] autorelease];
		trendView.days = nil;
		trendView.app = app;
		[trendViewsForApps addObject:trendView];
		[self.scrollView addSubview:trendView];
		x += 320;
	}
	self.scrollView.contentSize = CGSizeMake(640.0 + [trendViewsForApps count] * 320.0, 200);
	
	[self scrollViewDidEndDecelerating:scrollView];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)aScrollView
{
	if (!self.days || [self.days count] == 0)
		return; 
	
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

- (void)selectDate:(id)sender
{
	if ([self.days count] == 0)
		return;
	
	NSEnumerator *backEnum = [self.days reverseObjectEnumerator];
	Day *d = nil;
	int lastMonth = -1;
	NSMutableArray *months = [NSMutableArray array];
	NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSDateFormatter *monthFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[monthFormatter setDateFormat:@"MMMM yyyy"];
	while (d = [backEnum nextObject]) {
		NSDateComponents *comps = [gregorian components:NSMonthCalendarUnit fromDate:d.date];
		int month = [comps month];
		if (month != lastMonth) {
			[months addObject:[monthFormatter stringFromDate:d.date]];
			lastMonth = month;
		}
		if ([months count] >= 4)
			break;
	}
	
	UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Quick Selection",nil) message:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) otherButtonTitles:nil] autorelease];
	[alert addButtonWithTitle:NSLocalizedString(@"Last 7 Days",nil)];
	[alert addButtonWithTitle:NSLocalizedString(@"Last 30 Days",nil)];
	for (NSString *monthButton in months) {
		[alert addButtonWithTitle:monthButton];
	}
	
	[alert show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	//TODO: This is really messy, got to clean it up sometime...
	
	int fromIndex;
	int toIndex;
	//NSLog(@"%i", buttonIndex);
	if (buttonIndex == 0) {
		//NSLog(@"Cancel");
		return;
	}
	else if (buttonIndex == 1) {
		//Last 7 days
		toIndex = [self.days count] - 1;
		fromIndex = [self.days count] - 7;
		if (fromIndex < 0) fromIndex = 0;
	}
	else if (buttonIndex == 2) {
		//Last 7 days
		toIndex = [self.days count] - 1;
		fromIndex = [self.days count] - 30;
		if (fromIndex < 0) fromIndex = 0;
	}
	else if (buttonIndex == 3) {
		//NSLog(@"This month");
		fromIndex = [self.days count] - 1;
		toIndex = fromIndex;
		NSEnumerator *backEnum = [self.days reverseObjectEnumerator];
		Day *d = nil;
		int lastMonth = -1;
		int months = 0;
		NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
		while (d = [backEnum nextObject]) {
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
	else if (buttonIndex == 4) {
		//NSLog(@"Last month");
		fromIndex = [self.days count] - 1;
		toIndex = fromIndex;
		int i = toIndex;
		NSEnumerator *backEnum = [self.days reverseObjectEnumerator];
		Day *d = nil;
		int lastMonth = -1;
		int months = 0;
		NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
		while (d = [backEnum nextObject]) {
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
	else if (buttonIndex == 5) {
		//NSLog(@"Two months ago");
		fromIndex = [self.days count] - 1;
		toIndex = fromIndex;
		int i = toIndex;
		NSEnumerator *backEnum = [self.days reverseObjectEnumerator];
		Day *d = nil;
		int lastMonth = -1;
		int months = 0;
		NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
		while (d = [backEnum nextObject]) {
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
	else if (buttonIndex == 6) {
		//NSLog(@"Three months ago");
		fromIndex = [self.days count] - 1;
		toIndex = fromIndex;
		int i = toIndex;
		NSEnumerator *backEnum = [self.days reverseObjectEnumerator];
		Day *d = nil;
		int lastMonth = -1;
		int months = 0;
		NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
		while (d = [backEnum nextObject]) {
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
	return [dateFormatter stringFromDate:[[days objectAtIndex:row] date]];
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
	self.dateFormatter = nil;
	self.trendViewsForApps = nil;
	self.regionsGraphView = nil;
	
    [super dealloc];
}


@end
