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

@synthesize reviewSummaryView, downloadReviewsButtonItem, reviewsPopover;

- (id)initWithAccount:(ASAccount *)anAccount
{
	self = [super initWithAccount:anAccount];
	if (self) {
		self.title = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) ? NSLocalizedString(@"Reviews", nil) : [account displayName];
		self.tabBarItem.image = [UIImage imageNamed:@"Reviews.png"];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reviewDownloadProgressDidChange:) name:ReviewDownloadManagerDidUpdateProgressNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowPasscodeLock:) name:ASWillShowPasscodeLockNotification object:nil];
	}
    
#ifdef __IPHONE_7_0
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= (float)__IPHONE_7_0/10000)
    {
        [self performSelector:@selector(setEdgesForExtendedLayout:) withObject:[NSNumber numberWithInteger:0]];
    }
#endif
    
	return self;
}

- (void)willShowPasscodeLock:(NSNotification *)notification
{
	[super willShowPasscodeLock:notification];
	if (self.reviewsPopover.popoverVisible) {
		[self.reviewsPopover dismissPopoverAnimated:NO];
	}
}

- (void)loadView
{
	[super loadView];
	
	self.reviewSummaryView = [[[ReviewSummaryView alloc] initWithFrame:self.topView.frame] autorelease];
	reviewSummaryView.dataSource = self;
	reviewSummaryView.delegate = self;
	reviewSummaryView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
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
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		return YES;
	}
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
	if (!self.account) return 0;
	
	NSFetchRequest *reviewsCountFetchRequest = [[[NSFetchRequest alloc] init] autorelease];
	[reviewsCountFetchRequest setEntity:[NSEntityDescription entityForName:@"Review" inManagedObjectContext:self.account.managedObjectContext]];

    NSMutableString * pred = [NSMutableString stringWithString:@"rating == %@"];
    NSMutableArray * args = [NSMutableArray arrayWithArray:self.selectedProducts];
    [args insertObject:[NSNumber numberWithInt:rating] atIndex:0];
    
	if (![self.selectedProducts count]) {
        [pred appendString:@" AND product.account = %@"];
        [args addObject:self.account];
        [reviewsCountFetchRequest setPredicate:[NSPredicate predicateWithFormat:pred argumentArray:args]];
	} else {
        [pred appendString:@" AND (product == nil"];
        for (Product* p in self.selectedProducts) {
            [pred appendString:@" OR product == %@"];
        }
        [pred appendString:@")"];
        [reviewsCountFetchRequest setPredicate:[NSPredicate predicateWithFormat:pred argumentArray:args]];
	}
	NSUInteger numberOfReviewsForRating = [self.account.managedObjectContext countForFetchRequest:reviewsCountFetchRequest error:NULL];	
	return numberOfReviewsForRating;
}

- (NSUInteger)reviewSummaryView:(ReviewSummaryView *)view numberOfUnreadReviewsForRating:(NSInteger)rating
{
	if (!self.account) return 0;
	
	NSFetchRequest *reviewsCountFetchRequest = [[[NSFetchRequest alloc] init] autorelease];
	[reviewsCountFetchRequest setEntity:[NSEntityDescription entityForName:@"Review" inManagedObjectContext:self.account.managedObjectContext]];
    
    NSMutableString * pred = [NSMutableString stringWithString:@"rating == %@ AND unread = TRUE"];
    NSMutableArray * args = [NSMutableArray arrayWithArray:self.selectedProducts];
    [args insertObject:[NSNumber numberWithInt:rating] atIndex:0];
    
	if (![self.selectedProducts count]) {
        [pred appendString:@" AND product.account = %@"];
        [args addObject:self.account];
        [reviewsCountFetchRequest setPredicate:[NSPredicate predicateWithFormat:pred argumentArray:args]];
	} else {
        [pred appendString:@" AND (product == nil"];
        for (Product* p in self.selectedProducts) {
            [pred appendString:@" OR product == %@"];
        }
        [pred appendString:@")"];
        [reviewsCountFetchRequest setPredicate:[NSPredicate predicateWithFormat:pred argumentArray:args]];
	}
	NSUInteger numberOfUnreadReviewsForRating = [self.account.managedObjectContext countForFetchRequest:reviewsCountFetchRequest error:NULL];	
	return numberOfUnreadReviewsForRating;
}

- (void)reviewSummaryView:(ReviewSummaryView *)view didSelectRating:(NSInteger)rating
{
	if (!self.account) return;
	
	ReviewListViewController *vc = [[[ReviewListViewController alloc] initWithAccount:self.account products:self.selectedProducts rating:rating] autorelease];
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
		[self.navigationController pushViewController:vc animated:YES];
	} else {
		UINavigationController *nav = [[[UINavigationController alloc] initWithRootViewController:vc] autorelease];
		self.reviewsPopover = [[[UIPopoverController alloc] initWithContentViewController:nav] autorelease];
		[reviewsPopover presentPopoverFromRect:[reviewSummaryView barFrameForRating:rating]	inView:reviewSummaryView permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
	}
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    [super tableView:tableView didDeselectRowAtIndexPath:indexPath];
    [self.reviewSummaryView reloadDataAnimated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[super tableView:tableView didSelectRowAtIndexPath:indexPath];
	[self.reviewSummaryView reloadDataAnimated:YES];
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer {
    [super handleLongPress:gestureRecognizer];
    [self.reviewSummaryView reloadDataAnimated:YES];
}

- (void)dealloc
{
	[reviewsPopover release];
	[reviewSummaryView release];
	[downloadReviewsButtonItem release];
	[super dealloc];
}

@end
