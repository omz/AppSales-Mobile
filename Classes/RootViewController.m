/*
 RootViewController.m
 AppSalesMobile
 
 * Copyright (c) 2008, omz:software
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of omz:software nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY omz:software ''AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL <copyright holder> BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <zlib.h>
#import "RootViewController.h"
#import "AppSalesMobileAppDelegate.h"
#import "NSDictionary+HTTP.h"
#import "Day.h"
#import "Country.h"
#import "Entry.h"
#import "CurrencyManager.h"
#import "SettingsViewController.h"
#import "DaysController.h"
#import "WeeksController.h"
#import "HelpBrowser.h"
#import "SFHFKeychainUtils.h"
#import "StatisticsViewController.h"
#import "ReportManager.h"
#import "ReviewsController.h"

@implementation RootViewController

@synthesize activityIndicator, statusLabel, daysController, weeksController, settingsController, statisticsController, reviewsController;
@synthesize dailyTrendView, weeklyTrendView;

- (void)loadView
{
	[super loadView];
	
	self.activityIndicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite] autorelease];
	UIBarButtonItem *progressItem = [[[UIBarButtonItem alloc] initWithCustomView:activityIndicator] autorelease];
	
	self.settingsController = [[[SettingsViewController alloc] initWithNibName:@"SettingsViewController" bundle:nil] autorelease];
	settingsController.hidesBottomBarWhenPushed = YES;
	
	UIBarButtonItem *refreshItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(downloadReports)] autorelease];
	UIBarButtonItem *flexSpaceItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
	
	self.statusLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 150, 32)] autorelease];
	statusLabel.textColor = [UIColor whiteColor];
	statusLabel.shadowColor = [UIColor darkGrayColor];
	statusLabel.shadowOffset = CGSizeMake(0, 1);
	statusLabel.font = [UIFont systemFontOfSize:12.0];
	statusLabel.numberOfLines = 2;
	statusLabel.lineBreakMode = UILineBreakModeWordWrap;
	statusLabel.backgroundColor = [UIColor clearColor];
	statusLabel.textAlignment = UITextAlignmentCenter;
	statusLabel.text = @"";
	UIBarButtonItem *statusItem = [[[UIBarButtonItem alloc] initWithCustomView:statusLabel] autorelease];
	
	self.toolbarItems = [NSArray arrayWithObjects:refreshItem, flexSpaceItem, statusItem, flexSpaceItem, progressItem, nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateProgress) name:ReportManagerUpdatedDownloadProgressNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshDailyTrend) name:ReportManagerDownloadedDailyReportsNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshWeeklyTrend) name:ReportManagerDownloadedWeeklyReportsNotification object:nil];
}


- (void)viewDidLoad 
{
	[super viewDidLoad];
	self.navigationItem.title = @"AppSales";
	
	UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
	[infoButton addTarget:self action:@selector(showInfo) forControlEvents:UIControlEventTouchUpInside];
	UIBarButtonItem *infoButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:infoButton] autorelease];
	self.navigationItem.rightBarButtonItem = infoButtonItem;
	
	self.tableView.contentInset = UIEdgeInsetsMake(44, 0, 0, 0);
	[self.tableView setScrollEnabled:NO];
	
	[self refreshDailyTrend];
	[self refreshWeeklyTrend];
}

- (void)refreshDailyTrend
{
	UIImage *sparkline = [self sparklineForReports:[[ReportManager sharedManager].days allValues]];
	self.dailyTrendView = [[[UIImageView alloc] initWithImage:sparkline] autorelease];
	[self.tableView reloadData];
}

- (UIImage *)sparklineForReports:(NSArray *)days
{
	UIGraphicsBeginImageContext(CGSizeMake(120, 30));
	CGContextRef c = UIGraphicsGetCurrentContext();
	
	NSSortDescriptor *dateSorter = [[[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO] autorelease];
	NSArray *sortedDays = [days sortedArrayUsingDescriptors:[NSArray arrayWithObject:dateSorter]];
	if ([sortedDays count] > 7) {
		sortedDays = [sortedDays subarrayWithRange:NSMakeRange(0, 7)];
	}
	BOOL reportIsLatest = NO;
	if ([sortedDays count] > 0) {
		Day *lastDay = [sortedDays objectAtIndex:0];
		NSTimeInterval reportAge = [[NSDate date] timeIntervalSince1970] - [lastDay.date timeIntervalSince1970];
		if (!lastDay.isWeek && reportAge < 172800) { //48 hours
			reportIsLatest = YES;
		}
		else if (lastDay.isWeek && reportAge < 1209600) { //14 days
			reportIsLatest = YES;
		}
	}
	
	int maxUnitSales = 0;
	NSMutableArray *unitSales = [NSMutableArray array];
	for (Day *d in [sortedDays reverseObjectEnumerator]) {
		int units = [d totalUnits];
		if (units > maxUnitSales)
			maxUnitSales = units;
		[unitSales addObject:[NSNumber numberWithInt:units]];
	}
	[[UIColor grayColor] set];
	float maxY = 27.0;
	float minY = 3.0;
	float minX = 2.0;
	float maxX = 75.0;
	int i = 0;
	float prevX = 0.0;
	float prevY = 0.0;
	CGMutablePathRef path = CGPathCreateMutable();
	
	CGContextBeginPath(c);
	for (NSNumber *sales in unitSales) {
		float r = [sales floatValue];
		float y = maxY - ((r / maxUnitSales) * (maxY - minY));
		float x = minX + ((maxX - minX) / ([unitSales count] - 1)) * i;
		if (prevX == 0.0) {
			CGPathMoveToPoint(path, NULL, x, y);
		}
		else {
			CGPathAddLineToPoint(path, NULL, x, y);
		}
		prevX = x;
		prevY = y;
		i++;
	}
	if ([unitSales count] > 1) {
		CGContextSetLineWidth(c, 1.0);
		CGContextSetLineJoin(c, kCGLineJoinRound);
		CGContextSetLineCap(c, kCGLineCapRound);
		
		CGMutablePathRef fillPath = CGPathCreateMutableCopy(path);
		CGPathAddLineToPoint(fillPath, NULL, prevX, maxY);
		CGPathAddLineToPoint(fillPath, NULL, minX, maxY);
		[[UIColor colorWithWhite:0.95 alpha:1.0] set];
		CGContextAddPath(c, fillPath);
		CGContextFillPath(c);
		CGPathRelease(fillPath);
		
		[[UIColor grayColor] set];
		CGContextAddPath(c, path);
		CGContextStrokePath(c);
				
		[[UIColor colorWithRed:0.84 green:0.11 blue:0.06 alpha:1.0] set];
		CGContextFillEllipseInRect(c, CGRectMake(prevX-2.5, prevY-2.5, 5, 5));
		
		NSNumber *lastDayUnits = [unitSales lastObject];
		NSNumber *lastButOneDayUnits = [unitSales objectAtIndex:[unitSales count]-2];
		float percentage = ([lastDayUnits floatValue] - [lastButOneDayUnits floatValue]) / [lastButOneDayUnits floatValue];
		int roundedPercent = (int)(percentage * 100.0);
		NSString *percentString = (roundedPercent < 0) ? [NSString stringWithFormat:@"%i%%", roundedPercent] : [NSString stringWithFormat:@"+%i%%", roundedPercent];
		[(reportIsLatest) ? ([UIColor blackColor]) : ([UIColor darkGrayColor]) set];
		[percentString drawInRect:CGRectMake(80, 7, 40, 15) withFont:[UIFont boldSystemFontOfSize:12.0]];
	}
	CGPathRelease(path);
	
	UIImage *trendImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return trendImage;
}

- (void)refreshWeeklyTrend
{
	UIImage *sparkline = [self sparklineForReports:[[ReportManager sharedManager].weeks allValues]];
	self.weeklyTrendView = [[[UIImageView alloc] initWithImage:sparkline] autorelease];
	[self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
	[self updateProgress];
}

- (void)downloadReports
{
	[[ReportManager sharedManager] downloadReports];
}

- (void)showInfo
{
	HelpBrowser *browser = [[HelpBrowser new] autorelease];
	UINavigationController *browserNavController = [[[UINavigationController alloc] initWithRootViewController:browser] autorelease];
	browserNavController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	[self.navigationController presentModalViewController:browserNavController animated:YES];
}

- (void)visitIconDrawer
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://icondrawer.com"]];
}

- (void)updateProgress
{
	BOOL isDownloading = [[ReportManager sharedManager] isDownloadingReports];
	if (isDownloading) {
		[activityIndicator startAnimating];
	}
	else {
		[activityIndicator stopAnimating];
	}
	statusLabel.text = [ReportManager sharedManager].reportDownloadStatus;
}

#pragma mark Table View methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	if (section == 0)
		return 3; //daily + weekly + graphs
	else
		return 1; //reviews / settings
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
	int row = [indexPath row];
	int section = [indexPath section];
	if ((row == 0) && (section == 0)) {
		cell.imageView.image = [UIImage imageNamed:@"Daily.png"];
		cell.textLabel.text = NSLocalizedString(@"Daily",nil);
		cell.accessoryView = self.dailyTrendView;
	}
	else if ((row == 1) && (section == 0)) {
		cell.imageView.image = [UIImage imageNamed:@"Weekly.png"];
		cell.textLabel.text = NSLocalizedString(@"Weekly",nil);
		cell.accessoryView = self.weeklyTrendView;
	}
	else if ((row == 2) && (section == 0)) {
		cell.imageView.image = [UIImage imageNamed:@"Statistics.png"];
		cell.textLabel.text = NSLocalizedString(@"Graphs",nil);
	}
	else if ((row == 0) && (section == 1)) {
		cell.imageView.image = [UIImage imageNamed:@"Reviews.png"];
		cell.textLabel.text = NSLocalizedString(@"Reviews",nil);
	}
	else if ((row == 0) && (section == 2)) {
		cell.imageView.image = [UIImage imageNamed:@"Settings.png"];
		cell.textLabel.text = NSLocalizedString(@"Settings",nil);
	}
    return cell;
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	int row = [indexPath row];
	int section = [indexPath section];
	if ((row == 0) && (section == 0)) {
		if (!self.daysController) {
			self.daysController = [[[DaysController alloc] init] autorelease];
			daysController.hidesBottomBarWhenPushed = YES;
		}
		[self.navigationController pushViewController:daysController animated:YES];
	}
	else if ((row == 1) && (section == 0)) {
		if (!self.weeksController) {
			self.weeksController = [[[WeeksController alloc] init] autorelease];
			weeksController.hidesBottomBarWhenPushed = YES;		
		}
		[self.navigationController pushViewController:weeksController animated:YES];
	}
	else if ((row == 2) && (section == 0)) {
		if (!self.statisticsController) {
			self.statisticsController = [[StatisticsViewController new] autorelease];
			statisticsController.hidesBottomBarWhenPushed = YES;
		}
		[self.navigationController pushViewController:statisticsController animated:YES];
	}
	else if ((row == 0) && (section == 1)) {
		if ([[ReportManager sharedManager].appsByID count] == 0) {
			[[[[UIAlertView alloc] initWithTitle:@"" message:NSLocalizedString(@"Before you can download reviews, you have to download at least one daily report with this version. If you already have today's report, you can delete it and download it again.",nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil] autorelease] show];
			return;
		}
		else {
			if (!self.reviewsController) {
				self.reviewsController = [[[ReviewsController alloc] initWithStyle:UITableViewStylePlain] autorelease];
			}
			[self.navigationController pushViewController:reviewsController animated:YES];
		}
	}
	else if ((row == 0) && (section == 2)) {
		[self.navigationController pushViewController:settingsController animated:YES];
	}
	
	[aTableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end

