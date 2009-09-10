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

@implementation RootViewController

@synthesize activityIndicator, daysController, weeksController, settingsController, statisticsController;

- (void)loadView
{
	[super loadView];
	
	self.activityIndicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite] autorelease];
	UIBarButtonItem *progressItem = [[[UIBarButtonItem alloc] initWithCustomView:activityIndicator] autorelease];
	
	self.daysController = [[[DaysController alloc] init] autorelease];
	daysController.hidesBottomBarWhenPushed = YES;
	self.weeksController = [[[WeeksController alloc] init] autorelease];
	weeksController.hidesBottomBarWhenPushed = YES;
	self.settingsController = [[[SettingsViewController alloc] initWithNibName:@"SettingsViewController" bundle:nil] autorelease];
	settingsController.hidesBottomBarWhenPushed = YES;
	self.statisticsController = [[StatisticsViewController new] autorelease];
	statisticsController.hidesBottomBarWhenPushed = YES;
	
	UIBarButtonItem *refreshItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(downloadReports)] autorelease];
	UIBarButtonItem *flexSpaceItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
	
	self.toolbarItems = [NSArray arrayWithObjects:refreshItem, flexSpaceItem, progressItem, nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateProgress) name:ReportManagerUpdatedDownloadProgressNotification object:nil];
}

- (void)viewDidLoad 
{
	[super viewDidLoad];
	self.navigationItem.title = @"AppSales";
	
	/*
	UIButton *footer = [UIButton buttonWithType:UIButtonTypeCustom];
	[footer setFrame:CGRectMake(0,0,320,20)];
	[footer.titleLabel setFont:[UIFont systemFontOfSize:14.0]];
	[footer setTitleColor:[UIColor colorWithRed:0.3 green:0.34 blue:0.42 alpha:1.0] forState:UIControlStateNormal];
	[footer addTarget:self action:@selector(visitIconDrawer) forControlEvents:UIControlEventTouchUpInside];
	[footer setTitle:NSLocalizedString(@"Flag icons by icondrawer.com",nil) forState:UIControlStateNormal];
	[self.tableView setTableFooterView:footer];
	 */
	
	UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
	[infoButton addTarget:self action:@selector(showInfo) forControlEvents:UIControlEventTouchUpInside];
	UIBarButtonItem *infoButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:infoButton] autorelease];
	self.navigationItem.rightBarButtonItem = infoButtonItem;
	
	self.tableView.contentInset = UIEdgeInsetsMake(44, 0, 0, 0);
	[self.tableView setScrollEnabled:NO];
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
	float p = [[ReportManager sharedManager] downloadProgress];
	if ((p != 0.0) && (p != 1.0)) {
		[activityIndicator startAnimating];
	}
	else {
		[activityIndicator stopAnimating];
	}
	
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
		return 1; //settings
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
	}
	else if ((row == 1) && (section == 0)) {
		cell.imageView.image = [UIImage imageNamed:@"Weekly.png"];
		cell.textLabel.text = NSLocalizedString(@"Weekly",nil);
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
		[self.navigationController pushViewController:daysController animated:YES];
	}
	else if ((row == 1) && (section == 0)) {
		[self.navigationController pushViewController:weeksController animated:YES];
	}
	else if ((row == 2) && (section == 0)) {
		[self.navigationController pushViewController:statisticsController animated:YES];
	}
	else if ((row == 0) && (section == 2)) {
		[self.navigationController pushViewController:settingsController animated:YES];
	}
	
	
	[aTableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end

