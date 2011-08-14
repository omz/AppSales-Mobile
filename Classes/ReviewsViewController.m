//
//  ReviewsViewController.m
//  AppSales
//
//  Created by Ole Zorn on 30.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "ReviewsViewController.h"
#import "ReviewDownloadManager.h"
#import "ReviewListViewController.h"
#import "ASAccount.h"

@implementation ReviewsViewController

@synthesize reviewSummaryView, downloadReviewsButtonItem;

- (id)initWithAccount:(ASAccount *)anAccount
{
	self = [super initWithAccount:anAccount];
	if (self) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reviewDownloadProgressDidChange:) name:ReviewDownloadManagerDidUpdateProgressNotification object:nil];
	}
	return self;
}

- (void)loadView
{
	[super loadView];
	
	self.reviewSummaryView = [[[ReviewSummaryView alloc] initWithFrame:self.topView.frame] autorelease];
	reviewSummaryView.dataSource = self;
	reviewSummaryView.delegate = self;
	[self.view addSubview:reviewSummaryView];
	
	self.downloadReviewsButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(downloadReviews:)] autorelease];
	downloadReviewsButtonItem.enabled = ![[ReviewDownloadManager sharedManager] isDownloading];
	self.navigationItem.rightBarButtonItem = downloadReviewsButtonItem;
	
	if ([self shouldShowStatusBar]) {
		self.progressBar.progress = [[ReviewDownloadManager sharedManager] downloadProgress];
		self.statusLabel.text = NSLocalizedString(@"Downloading Reviews...", nil);
	}
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	self.reviewSummaryView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL)shouldShowStatusBar
{
	return [[ReviewDownloadManager sharedManager] isDownloading];
}

- (void)reviewDownloadProgressDidChange:(NSNotification *)notification
{
	self.downloadReviewsButtonItem.enabled = ![[ReviewDownloadManager sharedManager] isDownloading];
	[self showOrHideStatusBar];
	if (!self.account.isDownloadingReports) {
		self.progressBar.progress = [[ReviewDownloadManager sharedManager] downloadProgress];
		if ([[ReviewDownloadManager sharedManager] isDownloading]) {
			self.statusLabel.text = NSLocalizedString(@"Downloading Reviews...", nil);
		} else {
			self.statusLabel.text = NSLocalizedString(@"Finished", nil);
		}
	}
}

- (NSSet *)entityNamesTriggeringReload
{
	return [NSSet setWithObjects:@"Review", @"Product", nil];
}

- (void)reloadData
{
	[super reloadData];
	[self.reviewSummaryView reloadDataAnimated:NO];
}

- (void)downloadReviews:(id)sender
{
	[[ReviewDownloadManager sharedManager] downloadReviewsForProducts:self.visibleProducts];
}

- (void)stopDownload:(id)sender
{
	self.stopButtonItem.enabled = NO;
	[[ReviewDownloadManager sharedManager] cancelAllDownloads];
	self.statusLabel.text = NSLocalizedString(@"Cancelled", nil);
}

- (NSUInteger)reviewSummaryView:(ReviewSummaryView *)view numberOfReviewsForRating:(NSInteger)rating
{
	NSFetchRequest *reviewsCountFetchRequest = [[[NSFetchRequest alloc] init] autorelease];
	[reviewsCountFetchRequest setEntity:[NSEntityDescription entityForName:@"Review" inManagedObjectContext:self.account.managedObjectContext]];
	if (!self.selectedProduct) {
		[reviewsCountFetchRequest setPredicate:[NSPredicate predicateWithFormat:@"product.account == %@ AND rating == %@", self.account, [NSNumber numberWithInt:rating]]];
	} else {
		[reviewsCountFetchRequest setPredicate:[NSPredicate predicateWithFormat:@"product == %@ AND rating == %@", self.selectedProduct, [NSNumber numberWithInt:rating]]];
	}
	NSUInteger numberOfReviewsForRating = [self.account.managedObjectContext countForFetchRequest:reviewsCountFetchRequest error:NULL];	
	return numberOfReviewsForRating;
}

- (NSUInteger)reviewSummaryView:(ReviewSummaryView *)view numberOfUnreadReviewsForRating:(NSInteger)rating
{
	NSFetchRequest *reviewsCountFetchRequest = [[[NSFetchRequest alloc] init] autorelease];
	[reviewsCountFetchRequest setEntity:[NSEntityDescription entityForName:@"Review" inManagedObjectContext:self.account.managedObjectContext]];
	if (!self.selectedProduct) {
		[reviewsCountFetchRequest setPredicate:[NSPredicate predicateWithFormat:@"product.account == %@ AND rating == %@ AND unread = TRUE", self.account, [NSNumber numberWithInt:rating]]];
	} else {
		[reviewsCountFetchRequest setPredicate:[NSPredicate predicateWithFormat:@"product == %@ AND rating == %@ AND unread = TRUE", self.selectedProduct, [NSNumber numberWithInt:rating]]];
	}
	NSUInteger numberOfUnreadReviewsForRating = [self.account.managedObjectContext countForFetchRequest:reviewsCountFetchRequest error:NULL];	
	return numberOfUnreadReviewsForRating;
}

- (void)reviewSummaryView:(ReviewSummaryView *)view didSelectRating:(NSInteger)rating
{
	ReviewListViewController *vc = [[[ReviewListViewController alloc] initWithAccount:self.account product:self.selectedProduct rating:rating] autorelease];
	[self.navigationController pushViewController:vc animated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[super tableView:tableView didSelectRowAtIndexPath:indexPath];
	[self.reviewSummaryView reloadDataAnimated:YES];
}

- (void)dealloc
{
	[reviewSummaryView release];
	[downloadReviewsButtonItem release];
	[super dealloc];
}

@end
