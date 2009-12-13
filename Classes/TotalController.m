//
//  TotalController.m
//  AppSalesMobile
//
//  Created by Kyosuke Takayama on 09/11/20.
//  Copyright 2009 Kyosuke Takayama. All rights reserved.
//

#import "TotalController.h"

#import "Day.h"
#import "WeekCell.h"
#import "CountriesController.h"
#import "RootViewController.h"
#import "CurrencyManager.h"
#import "ReportManager.h"

#import "Country.h"
#import "Entry.h"

@implementation TotalController

- (id)init
{
	[super init];
	
	[self reload];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:ReportManagerDownloadedDailyReportsNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:ReportManagerDownloadedWeeklyReportsNotification object:nil];
	self.title = NSLocalizedString(@"Total",nil);
	
	return self;
}

- (void)reload
{
	self.daysByMonth = [NSMutableArray array];
	[daysByMonth addObject:[NSMutableArray array]];
	
	NSSortDescriptor *dateSorter = [[[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO] autorelease];
	NSArray *sortedDays = [[[ReportManager sharedManager].days allValues] sortedArrayUsingDescriptors:[NSArray arrayWithObject:dateSorter]];
	NSArray *sortedWeeks = [[[ReportManager sharedManager].weeks allValues] sortedArrayUsingDescriptors:[NSArray arrayWithObject:dateSorter]];
	if (sortedWeeks.count == 0) {
		NSLog(@"no weekly data found"); // if user views totals during first report download
		return;
	}
	Day *latestWeek = [sortedWeeks objectAtIndex:0];

	Day *total = nil;
	total = [[[Day alloc] init] autorelease];
	total.countries = [NSMutableDictionary dictionary];
	total.isWeek = TRUE;
	total.wasLoadedFromDisk = TRUE;
	total.cachedWeekEndDateString = @"total";
	total.date = latestWeek.date;

	NSDate *startOfDay = [total.date addTimeInterval:(24*7-1)*3600];
	NSMutableArray *additionalDays = [NSMutableArray array];
	for(Day *d in sortedDays) {
		if([d.date compare:startOfDay] == NSOrderedDescending) {
			[additionalDays addObject:d];
		}
	}

	if([sortedDays count] > 0) {
		total.date = [[sortedDays objectAtIndex:0] date];
	}

	NSArray *days = [sortedWeeks arrayByAddingObjectsFromArray:additionalDays];
	for(Day *w in days) {
		for (Country *c in [w.countries allValues]) {
			Country *country = [total countryNamed:c.name];
			Entry *totalEntry = nil;
			
			for (Entry *e in c.entries) {
				for (Entry *totalE in country.entries) {
					if ([e.productName isEqualToString:totalE.productName] &&
							e.royalties == totalE.royalties &&
							e.transactionType == totalE.transactionType) {
						totalEntry = totalE;
						break;
					}
				}
				if (totalEntry == nil) {
					[[[Entry alloc] initWithProductName:e.productName
										transactionType:e.transactionType
												units:e.units
												royalties:e.royalties
												currency:e.currency
												country:country] autorelease];
				} else {
					totalEntry.units += e.units;
					totalEntry = nil;
				}
			}
		}
	}
	[[daysByMonth lastObject] addObject:total];

	[self.tableView reloadData];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath 
{
	return NO;
}

@end
