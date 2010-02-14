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
	// must synchronize on app, since ReviewManager might be mutating the users reviews.
	// this is a bit hacky and gross, but it's simple and works for now
	NSArray *allReviews;
	@synchronized (app) {
		allReviews = app.reviewsByUser.allValues;
	}
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

- (id)initWithApp:(App*)appToUse {
	self = [self initWithStyle:UITableViewStylePlain];
	if (self) {
		app = [appToUse retain];
	}
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	self.tableView.rowHeight = 85;
	[self loadReviews];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(loadReviews) 
												 name:ReviewManagerDownloadedReviewsNotification 
											   object:nil];
}

- (void)viewDidUnload {
	[super viewDidUnload];
	[[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:ReviewManagerDownloadedReviewsNotification];	
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
	
	SingleReviewController *reviewController = [[[SingleReviewController alloc] init] autorelease];
	reviewController.review = [reviews objectAtIndex:indexPath.row];
	[self.navigationController pushViewController:reviewController animated:YES];
}


- (void)dealloc {
	[app release];
	[reviews release];
    [super dealloc];
}


@end

