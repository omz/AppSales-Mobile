//
//  DashboardView.m
//  AppSalesMobile
//
//  Created by Ole Zorn on 05.04.10.
//  Copyright 2010 omz:software. All rights reserved.
//

#import "DashboardViewController.h"
#import "NSDateFormatter+SharedInstances.h"
#import "Day.h"
#import "DashboardGraphView.h"
#import "ReportManager.h"


@implementation DashboardViewController

@synthesize dateRangePicker, reports, graphView, reportsPopover, showsWeeklyReports, calendarButton, viewReportsButton;

- (void) loadView {
	[super loadView];
	self.view.backgroundColor = [UIColor clearColor];
	
	UIImageView *backgroundImageView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"PaneBackground.png"]] autorelease];
	backgroundImageView.contentStretch = CGRectMake(0.1, 0.1, 0.8, 0.8);
	backgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[self.view addSubview:backgroundImageView];
	
	self.dateRangePicker = [[[UIPickerView alloc] initWithFrame:CGRectMake(21, 17, 215, 215)] autorelease];
	dateRangePicker.showsSelectionIndicator = YES;
	dateRangePicker.delegate = self;
	dateRangePicker.dataSource = self;
	[self.view addSubview:dateRangePicker];
	
	UIImageView *pickerOverlay = [[[UIImageView alloc] initWithFrame:CGRectInset(dateRangePicker.frame, -7, -7)] autorelease];
	pickerOverlay.image = [UIImage imageNamed:@"PickerOverlay.png"];
	[self.view addSubview:pickerOverlay];
	
	self.viewReportsButton = [UIButton buttonWithType:UIButtonTypeCustom];
	viewReportsButton.frame = CGRectMake(84, 250, 149, 47);
	UIImage *buttonImageNormal = [[UIImage imageNamed:@"PaneButtonNormal.png"] stretchableImageWithLeftCapWidth:10 topCapHeight:0];
	UIImage *buttonImageHighlighted = [[UIImage imageNamed:@"PaneButtonHighlighted.png"] stretchableImageWithLeftCapWidth:10 topCapHeight:0];
	[viewReportsButton setBackgroundImage:buttonImageNormal forState:UIControlStateNormal];
	[viewReportsButton setBackgroundImage:buttonImageHighlighted forState:UIControlStateHighlighted];
	[viewReportsButton setTitle:NSLocalizedString(@"View Reports",nil) forState:UIControlStateNormal];
	[viewReportsButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
	[viewReportsButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateHighlighted];
	[viewReportsButton setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[viewReportsButton setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
	viewReportsButton.titleLabel.frame = viewReportsButton.bounds;
	viewReportsButton.titleLabel.font = [UIFont boldSystemFontOfSize:15.0];
	viewReportsButton.titleLabel.shadowOffset = CGSizeMake(0, 1);
	[viewReportsButton addTarget:self action:@selector(viewReports:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:viewReportsButton];
	
	self.calendarButton = [UIButton buttonWithType:UIButtonTypeCustom];
	calendarButton.frame = CGRectMake(24, 250, 49, 47);
	[calendarButton setImage:[UIImage imageNamed:@"CalendarButtonNormal.png"] forState:UIControlStateNormal];
	[calendarButton setImage:[UIImage imageNamed:@"CalendarButtonHighlighted.png"] forState:UIControlStateHighlighted];
	[calendarButton addTarget:self action:@selector(selectQuickDateRange:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:calendarButton];
	
	self.graphView = [[[DashboardGraphView alloc] initWithFrame:CGRectMake(246, 17, 500, 282)] autorelease];
	graphView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[self.view addSubview:graphView];
	
	shouldAutomaticallyShowNewReports = YES;
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	[self reloadData];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:ReportManagerDownloadedDailyReportsNotification object:nil];
}

- (void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)selectQuickDateRange:(id)sender
{
	if ([self.reports count] == 0) return;
	
	if(self.showsWeeklyReports){
		UIActionSheet *sheet = [[[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil] autorelease];
		[sheet addButtonWithTitle:NSLocalizedString(@"Last 8 Weeks",nil)];
		[sheet addButtonWithTitle:NSLocalizedString(@"All time",nil)];
		[sheet showFromRect:[sender frame] inView:self.view animated:YES];
	}else{
		int lastMonth = -1;
		NSMutableArray *months = [NSMutableArray array];
		NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
		NSDateFormatter *monthFormatter = [[[NSDateFormatter alloc] init] autorelease];
		[monthFormatter setDateFormat:@"MMMM yyyy"];
		for (Day *d in self.reports.reverseObjectEnumerator) {
			NSDateComponents *comps = [gregorian components:NSMonthCalendarUnit fromDate:d.date];
			int month = [comps month];
			if (month != lastMonth) {
				[months addObject:[monthFormatter stringFromDate:d.date]];
				lastMonth = month;
			}
			if ([months count] >= 3)
				break;
		}
		UIActionSheet *sheet = [[[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil] autorelease];
		[sheet addButtonWithTitle:NSLocalizedString(@"Last 7 Days",nil)];
		[sheet addButtonWithTitle:NSLocalizedString(@"Last 30 Days",nil)];
		for (NSString *monthButton in months) {
			[sheet addButtonWithTitle:monthButton];
		}
		[sheet addButtonWithTitle:NSLocalizedString(@"Last year", nil)];
		[sheet addButtonWithTitle:NSLocalizedString(@"All time", nil)];
		[sheet showFromRect:[sender frame] inView:self.view animated:YES];
	}
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == [actionSheet cancelButtonIndex]) return;
	
	int fromIndex = 0;
	int toIndex = 0;
	if(self.showsWeeklyReports){
		if (buttonIndex == 0) {
			//Last 8 month
			toIndex = [self.reports count] - 1;
			fromIndex = [self.reports count] - 8;
			if (fromIndex < 0) fromIndex = 0;
		}
		else if (buttonIndex == 1) {
			//All time
			toIndex = [self.reports count] - 1;
			fromIndex = 0;
		}
	}else{
		if (buttonIndex == 0) {
			//Last 7 days
			toIndex = [self.reports count] - 1;
			fromIndex = [self.reports count] - 7;
			if (fromIndex < 0) fromIndex = 0;
		}
		else if (buttonIndex == 1) {
			//Last 7 days
			toIndex = [self.reports count] - 1;
			fromIndex = [self.reports count] - 30;
			if (fromIndex < 0) fromIndex = 0;
		}
		else if (buttonIndex == [actionSheet numberOfButtons]-2) {
			//NSLog(@"Last year");
			fromIndex = [self.reports count] - 1;
			toIndex = fromIndex;
			int lastYear = -1;
			NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
			for (Day *d in self.reports.reverseObjectEnumerator) {
				NSDateComponents *comps = [gregorian components:NSYearCalendarUnit fromDate:d.date];
				int y = [comps year];
				if(lastYear == -1)
					lastYear = y;
				else if(lastYear != y){
					fromIndex++;
					break;
				}
				fromIndex--;
			}
		}
		else if (buttonIndex == [actionSheet numberOfButtons]-1) {
			//NSLog(@"All time");
			fromIndex = 0;
			toIndex = [self.reports count]-1;
		}
		else if (buttonIndex == 2) {
			//NSLog(@"This month");
			fromIndex = [self.reports count] - 1;
			toIndex = fromIndex;
			int lastMonth = -1;
			int months = 0;
			NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
			for (Day *d in self.reports.reverseObjectEnumerator) {
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
		else if (buttonIndex == 3) {
			//NSLog(@"Last month");
			fromIndex = [self.reports count] - 1;
			toIndex = fromIndex;
			int i = toIndex;
			int lastMonth = -1;
			int months = 0;
			NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
			for (Day *d in self.reports.reverseObjectEnumerator) {
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
		else if (buttonIndex == 4) {
			//NSLog(@"Two months ago");
			fromIndex = [self.reports count] - 1;
			toIndex = fromIndex;
			int i = toIndex;
			int lastMonth = -1;
			int months = 0;
			NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
			for (Day *d in self.reports.reverseObjectEnumerator) {
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
		else if (buttonIndex == 5) {
			//NSLog(@"Three months ago");
			fromIndex = [self.reports count] - 1;
			toIndex = fromIndex;
			int i = toIndex;
			int lastMonth = -1;
			int months = 0;
			NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
			for (Day *d in self.reports.reverseObjectEnumerator) {
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
	}
	
	[dateRangePicker selectRow:fromIndex inComponent:0 animated:NO];
	[dateRangePicker selectRow:toIndex inComponent:1 animated:NO];
	[self pickerView:dateRangePicker didSelectRow:[dateRangePicker selectedRowInComponent:0] inComponent:0];
	[self pickerView:dateRangePicker didSelectRow:[dateRangePicker selectedRowInComponent:1] inComponent:1];	
}

- (void)setShowsWeeklyReports:(BOOL)flag
{
	if (showsWeeklyReports == flag) return;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	showsWeeklyReports = flag;
	if (showsWeeklyReports) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:ReportManagerDownloadedWeeklyReportsNotification object:nil];
		//calendarButton.hidden = YES;
		//viewReportsButton.frame = CGRectMake(24, 250, 209, 47);
	} else {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:ReportManagerDownloadedDailyReportsNotification object:nil];		
		//calendarButton.hidden = NO;
		//viewReportsButton.frame = CGRectMake(84, 250, 149, 47);
	}
	graphView.showsWeeklyReports = flag;
}

- (void)resetDatePicker
{
	if (!self.reports || [reports count] == 0) return;
	
	int fromRow = [reports count] - (self.showsWeeklyReports ? 8 : 7);
	if (fromRow < 0) fromRow = 0;
	int toRow = [reports count] - 1;
	if (toRow < 0) toRow = 0;
	[dateRangePicker selectRow:fromRow inComponent:0 animated:NO];
	[dateRangePicker selectRow:toRow inComponent:1 animated:NO];
	
	NSRange selectedRange = NSMakeRange(fromRow, toRow - fromRow + 1);
	NSArray *selectedReports = [reports subarrayWithRange:selectedRange];
	graphView.reports = selectedReports;
	[graphView setNeedsDisplay];
}

- (void)reloadData
{
	NSSortDescriptor *dateSorter = [[[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES] autorelease];
	NSArray *sortedReports = nil;
	if (self.showsWeeklyReports) {
		sortedReports = [[[ReportManager sharedManager].weeks allValues] sortedArrayUsingDescriptors:[NSArray arrayWithObject:dateSorter]];
	} else {
		sortedReports = [[[ReportManager sharedManager].days allValues] sortedArrayUsingDescriptors:[NSArray arrayWithObject:dateSorter]];
		
		/*
		//insert the weeks older than the oldest daily report
		NSMutableArray *allDays = [[sortedReports mutableCopy] autorelease];
		
		Day *oldestDayReport = nil;
		
		// This was crashing before because it ignored that some user's
		// may not have a report downloaded, default to 0, the oldest date possible
		NSTimeInterval oldestDayReportInterval = 0;
		if([sortedReports count]>0) {
			oldestDayReport = [sortedReports objectAtIndex:0];
			oldestDayReportInterval = [oldestDayReport.date timeIntervalSince1970];
		}
		
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
			sortedReports = [[allDays copy] autorelease];
		}
		 */
	}
	self.reports = sortedReports;
	[dateRangePicker reloadAllComponents];
	
	if (shouldAutomaticallyShowNewReports) {
		[self resetDatePicker];
	} else {
		//The user has selected a date range, so the picker selection should not change when new reports arrive
		[self pickerView:dateRangePicker didSelectRow:[dateRangePicker selectedRowInComponent:0] inComponent:0];
		[self pickerView:dateRangePicker didSelectRow:[dateRangePicker selectedRowInComponent:1] inComponent:1];	
	}
}

- (void)viewReports:(id)sender
{
	[self.reportsPopover presentPopoverFromRect:[(UIButton *)sender frame] inView:[(UIView *)sender superview] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
	Day *report = [reports objectAtIndex:row];
	if (showsWeeklyReports) {
		if (component == 0) {
			return [[NSDateFormatter sharedShortDateFormatter] stringFromDate:[[reports objectAtIndex:row] date]];
		} else {
			NSDate *fromDate = report.date;
			NSDateComponents *comp = [[[NSDateComponents alloc] init] autorelease];
			[comp setHour:167];
			NSDate *dateWeekLater = [[NSCalendar currentCalendar] dateByAddingComponents:comp toDate:fromDate options:0];
			return [[NSDateFormatter sharedShortDateFormatter] stringFromDate:dateWeekLater];
		}
	} else {
		return [[NSDateFormatter sharedShortDateFormatter] stringFromDate:[[reports objectAtIndex:row] date]];
	}
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
	return 2;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
	return [reports count];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
	if (!self.reports || [reports count] == 0) return;
	
	shouldAutomaticallyShowNewReports = NO;
	
	int fromIndex = [pickerView selectedRowInComponent:0];
	int toIndex = [pickerView selectedRowInComponent:1];
		
	if (fromIndex > toIndex) {
		int temp = toIndex;
		toIndex = fromIndex;
		fromIndex = temp;
	}
	
	NSRange selectedRange = NSMakeRange(fromIndex, toIndex - fromIndex + 1);
	NSArray *selectedReports = [self.reports subarrayWithRange:selectedRange];
	graphView.reports = selectedReports;
	[graphView setNeedsDisplay];
}


- (void)dealloc 
{
	[viewReportsButton release];
	[calendarButton release];
	[dateRangePicker release];
	[reports release];
	[graphView release];
	[reportsPopover release];
	[super dealloc];
}


@end
