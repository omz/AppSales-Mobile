//
//  ReviewsController.m
//  AppSalesMobile
//
//  Created by Ole Zorn on 12.09.09.
//  Copyright 2009 omz:software. All rights reserved.
//

#import "ReviewsController.h"
#import "ReportManager.h"
#import "App.h"
#import "Review.h"
#import "AppIconManager.h"
#import "AppCell.h"
#import "ReviewsListController.h"
#import "ReviewManager.h"

@implementation ReviewsController

@synthesize sortedApps, statusLabel, activityIndicator;

- (id)initWithStyle:(UITableViewStyle)style 
{
	if (self = [super initWithStyle:style]) {
		[self reload];
	}
    return self;
}

- (void)updateStatus
{
	ReviewManager *manager = [ReviewManager sharedManager];
	statusLabel.text = manager.reviewDownloadStatus;
	if (manager.isDownloadingReviews) {
		[activityIndicator startAnimating];
	} else {
		[activityIndicator stopAnimating];
	}
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.sortedApps = [[ReviewManager sharedManager] appNamesSorted];
	
	self.tableView.rowHeight = 45;
	self.title = NSLocalizedString(@"Reviews",nil);
	UIBarButtonItem *downloadButton = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Download",nil) 
																		style:UIBarButtonItemStyleBordered 
																	   target:self 
																	   action:@selector(downloadReviews)] autorelease];
	self.statusLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 150, 25)] autorelease];
	statusLabel.textColor = [UIColor whiteColor];
	statusLabel.shadowColor = [UIColor darkGrayColor];
	statusLabel.shadowOffset = CGSizeMake(0, 1);
	statusLabel.font = [UIFont systemFontOfSize:12.0];
	statusLabel.numberOfLines = 2;
	statusLabel.backgroundColor = [UIColor clearColor];
	statusLabel.textAlignment = UITextAlignmentLeft;
	statusLabel.text = @"";
	UIBarButtonItem *statusItem = [[[UIBarButtonItem alloc] initWithCustomView:statusLabel] autorelease];
	
	self.activityIndicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite] autorelease];
	//[activityIndicator startAnimating];
	UIBarButtonItem *activityItem = [[[UIBarButtonItem alloc] initWithCustomView:activityIndicator] autorelease];
	
	UIBarButtonItem *flexSpace = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
	
	self.toolbarItems = [NSArray arrayWithObjects:downloadButton, flexSpace, statusItem, flexSpace, activityItem, nil];
	[self updateStatus];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) 
												 name:ReviewManagerDownloadedReviewsNotification 
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateStatus) 
												 name:ReviewManagerUpdatedReviewDownloadProgressNotification 
											   object:nil];
}

- (void) viewDidUnload {
	[super viewDidUnload];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
}

- (void)reload
{
	[self.tableView reloadData];
}

- (void)downloadReviews
{
	if ([[ReviewManager sharedManager] isDownloadingReviews]) {
		return;
	}
	[[ReviewManager sharedManager] downloadReviews];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	return sortedApps.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{    
	static NSString *CellIdentifier = @"AppCell";
    AppCell *cell = (AppCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[AppCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    App *app = [sortedApps objectAtIndex:indexPath.row];
	cell.app = app;
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	App *app = [sortedApps objectAtIndex:indexPath.row];		
	ReviewsListController *listController = [[[ReviewsListController alloc] initWithApp:app] autorelease];
	listController.hidesBottomBarWhenPushed = YES;
	listController.title = app.appName;
	[self.navigationController pushViewController:listController animated:YES];
}

- (void)dealloc 
{
	[sortedApps release];
    [super dealloc];
}


@end

