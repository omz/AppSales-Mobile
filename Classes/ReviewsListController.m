//
//  ReviewsListController.m
//  AppSalesMobile
//
//  Created by Ole Zorn on 12.09.09.
//  Copyright 2009 omz:software. All rights reserved.
//

#import "ReviewsListController.h"
#import "App.h"
#import "Review.h"
#import "ReviewCell.h"
#import "SingleReviewController.h"
#import "ReviewManager.h"

@implementation ReviewsListController

- (void) loadReviews {	
	NSArray *allReviews = app.reviewsByUser.allValues;
	if (allReviews.count == reviews.count) {
		return; // up to date
	}
	NSSortDescriptor *reviewSorter1 = [[[NSSortDescriptor alloc] initWithKey:@"downloadDate" ascending:NO] autorelease];
	NSSortDescriptor *reviewSorter2 = [[[NSSortDescriptor alloc] initWithKey:@"reviewDate" ascending:NO] autorelease];
	NSSortDescriptor *reviewSorter3 = [[[NSSortDescriptor alloc] initWithKey:@"countryCode" ascending:NO] autorelease];
	NSArray *sortDescriptors = [NSArray arrayWithObjects:reviewSorter1, reviewSorter2, reviewSorter3, nil];
	[reviews release];
	reviews = [[allReviews sortedArrayUsingDescriptors:sortDescriptors] retain];
	
	[self.tableView reloadData];
}

- (id)initWithApp:(App*)appToUse style:(UITableViewStyle)style {
	self = [self initWithStyle:style];
	if (self) {
		app = [appToUse retain];
	}
	return self;
}

- (void)viewDidLoad
{
	self.tableView.rowHeight = 85;
	UIBarButtonItem * lAllRead = [[UIBarButtonItem alloc] initWithTitle:@"Read all" style:UIBarButtonItemStylePlain target:self action:@selector(readall)];
	self.navigationItem.rightBarButtonItem = lAllRead ;
	[lAllRead release];
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	[self loadReviews];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(loadReviews) 
												 name:ReviewManagerDownloadedReviewsNotification 
											   object:nil];
}

- (void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (CGSize)contentSizeForViewInPopover
{
	return CGSizeMake(320, 480);
}

-(void) readall
{
    for (Review *rev in reviews) {
        rev.newOrUpdatedReview = NO;
    }
	[self.tableView reloadData];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView  {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return reviews.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"ReviewCell";
    
	ReviewCell *cell = (ReviewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[[ReviewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
	}
    
	Review *review = [reviews objectAtIndex:indexPath.row];
	
    cell.review = review;
	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	SingleReviewController *reviewController = [[SingleReviewController new] autorelease];
	Review *review = [reviews objectAtIndex:indexPath.row];
	reviewController.review = review;
	review.newOrUpdatedReview = NO;
	[self.navigationController pushViewController:reviewController animated:YES];
}


- (void)dealloc {
	[app release];
	[reviews release];
    [super dealloc];
}


@end

