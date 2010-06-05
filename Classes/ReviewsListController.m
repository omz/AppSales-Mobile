//
//  ReviewsListController.m
//  AppSalesMobile
//
//  Created by Ole Zorn on 12.09.09.
//  Copyright 2009 omz:software. All rights reserved.
//

#import "ReviewsListController.h"
#import "Review.h"
#import "ReviewCell.h"
#import "SingleReviewController.h"

@implementation ReviewsListController

@synthesize reviews;

- (void)viewDidLoad
{
	self.tableView.rowHeight = 85.0;
	UIBarButtonItem * lAllRead = [[UIBarButtonItem alloc] initWithTitle:@"Read all" style:UIBarButtonItemStylePlain target:self action:@selector(readall)];
	self.navigationItem.rightBarButtonItem = lAllRead ;
	[lAllRead release];
}

- (CGSize)contentSizeForViewInPopover
{
	return CGSizeMake(320, 480);
}

-(void) readall
{
	NSUInteger lCurIdx, lNbReviews = [reviews count];
	for (lCurIdx = 0; lCurIdx < lNbReviews; lCurIdx++)
	{
		Review * lCurReview = [reviews objectAtIndex:lCurIdx];
		lCurReview.newOrUpdatedReview = NO;
	}
	[self.tableView reloadData];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	return [reviews count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{    
	static NSString *CellIdentifier = @"ReviewCell";
    
	ReviewCell *cell = (ReviewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[[ReviewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
	}
    
	Review *review = [reviews objectAtIndex:indexPath.row];
	
    cell.review = review;
	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	SingleReviewController *reviewController = [[[SingleReviewController alloc] init] autorelease];
	Review *review = [reviews objectAtIndex:indexPath.row];
	reviewController.review = review;
	review.newOrUpdatedReview = NO;
	[self.navigationController pushViewController:reviewController animated:YES];
}


- (void)dealloc 
{
	[reviews release];
    [super dealloc];
}


@end

