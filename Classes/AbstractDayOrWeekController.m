//
//  AbstractDayOrWeekController.m
//  AppSalesMobile
//
//  Created by Evan Schoenberg on 1/29/09.
//  Copyright 2009 Adium X / Saltatory Software. All rights reserved.
//

#import "AbstractDayOrWeekController.h"
#import "Day.h"
#import "DayCell.h"
#import "CountriesController.h"
#import "RootViewController.h"
#import "CurrencyManager.h"
#import "ReportManager.h"

@implementation AbstractDayOrWeekController

@synthesize daysByMonth, maxRevenue, sectionTitleFormatter;

- (id)init
{
	[super init];
	self.daysByMonth = [NSMutableArray array];
	self.maxRevenue = 0;
	self.sectionTitleFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[sectionTitleFormatter setDateFormat:@"MMMM yyyy"];
	
	return self;
}

- (void)viewDidLoad
{
	self.tableView.rowHeight = 45.0;
}

- (void)reload
{
	[self.tableView reloadData];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if (self.daysByMonth.count == 0)
		return @"";
	
	NSArray *sectionArray = [daysByMonth objectAtIndex:section];
	if (sectionArray.count == 0)
		return @"";
		
	Day *firstDayInSection = [sectionArray objectAtIndex:0];
	return [self.sectionTitleFormatter stringFromDate:firstDayInSection.date];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	NSInteger count = self.daysByMonth.count;
	return (count > 1 ? count : 1);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	if (self.daysByMonth.count > 0) {
		return [[self.daysByMonth objectAtIndex:section] count];
	}
    return 0;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath 
{
	return YES;
}

- (void)dealloc 
{
	self.sectionTitleFormatter = nil;
	self.daysByMonth = nil;
    [super dealloc];
}

@end
