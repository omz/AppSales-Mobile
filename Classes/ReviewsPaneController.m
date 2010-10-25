//
//  ReviewsPane.m
//  AppSalesMobile
//
//  Created by Ole Zorn on 06.04.10.
//  Copyright 2010 omz:software. All rights reserved.
//

#import "ReviewsPaneController.h"
#import "ReportManager.h"
#import "ReviewSummaryView.h"
#import "App.h"
#import "Review.h"
#import "ReviewsListController.h"
#import "ReviewsController.h"
#import "ReviewManager.h"
#import "AppManager.h"

@implementation ReviewsPaneController

@synthesize scrollView, statusLabel, activityIndicator;

- (void) viewDidLoad {
	[super viewDidLoad];
	UIImageView *backgroundImageView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"PaneBackground.png"]] autorelease];
	backgroundImageView.contentStretch = CGRectMake(0.1, 0.1, 0.8, 0.8);
	backgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[self.view addSubview:backgroundImageView];
	
	self.scrollView = [[[UIScrollView alloc] initWithFrame:CGRectMake(23, 17, 726, 227)] autorelease];
	scrollView.contentSize = CGSizeMake(1024, 227);
	scrollView.backgroundColor = [UIColor clearColor];
	[self.view addSubview:scrollView];
	
	self.statusLabel = [[[UILabel alloc] initWithFrame:CGRectMake(550, 268, 200, 20)] autorelease];
	statusLabel.backgroundColor = [UIColor clearColor];
	statusLabel.textColor = [UIColor darkGrayColor];
	[self.view addSubview:statusLabel];
	
	self.activityIndicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
	activityIndicator.frame = CGRectMake(550-20, 268+2, 16, 16);
	[self.view addSubview:activityIndicator];
	
	UIButton *downloadReviewsButton = [UIButton buttonWithType:UIButtonTypeCustom];
	downloadReviewsButton.frame = CGRectMake(24+169+11, 250, 209, 47);
	[downloadReviewsButton setBackgroundImage:[[UIImage imageNamed:@"PaneButtonNormal.png"] stretchableImageWithLeftCapWidth:10 topCapHeight:0] forState:UIControlStateNormal];
	[downloadReviewsButton setBackgroundImage:[[UIImage imageNamed:@"PaneButtonHighlighted.png"] stretchableImageWithLeftCapWidth:10 topCapHeight:0] forState:UIControlStateHighlighted];
	[downloadReviewsButton setTitle:NSLocalizedString(@"Download Reviews",nil) forState:UIControlStateNormal];
	[downloadReviewsButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
	[downloadReviewsButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateHighlighted];
	[downloadReviewsButton setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[downloadReviewsButton setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
	downloadReviewsButton.titleLabel.frame = downloadReviewsButton.bounds;
	downloadReviewsButton.titleLabel.font = [UIFont boldSystemFontOfSize:15.0];
	downloadReviewsButton.titleLabel.shadowOffset = CGSizeMake(0, 1);
	[downloadReviewsButton addTarget:self action:@selector(downloadReviews:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:downloadReviewsButton];
	
	UIButton *reviewsControllerButton = [UIButton buttonWithType:UIButtonTypeCustom];
	reviewsControllerButton.frame = CGRectMake(24, 250, 169, 47);
	[reviewsControllerButton setBackgroundImage:[[UIImage imageNamed:@"PaneButtonNormal.png"] stretchableImageWithLeftCapWidth:10 topCapHeight:0] forState:UIControlStateNormal];
	[reviewsControllerButton setBackgroundImage:[[UIImage imageNamed:@"PaneButtonHighlighted.png"] stretchableImageWithLeftCapWidth:10 topCapHeight:0] forState:UIControlStateHighlighted];
	[reviewsControllerButton setTitle:NSLocalizedString(@"Show Reviews",nil) forState:UIControlStateNormal];
	[reviewsControllerButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
	[reviewsControllerButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateHighlighted];
	[reviewsControllerButton setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[reviewsControllerButton setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
	reviewsControllerButton.titleLabel.frame = reviewsControllerButton.bounds;
	reviewsControllerButton.titleLabel.font = [UIFont boldSystemFontOfSize:15.0];
	reviewsControllerButton.titleLabel.shadowOffset = CGSizeMake(0, 1);
	[reviewsControllerButton addTarget:self action:@selector(showReviewsController:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:reviewsControllerButton];
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self reload];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:ReportManagerDownloadedDailyReportsNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:ReviewManagerDownloadedReviewsNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateStatus) name:ReviewManagerUpdatedReviewDownloadProgressNotification object:nil];
}

- (void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)updateStatus
{
	if ([[ReviewManager sharedManager] isDownloadingReviews]) {
		statusLabel.text = [[ReviewManager sharedManager] reviewDownloadStatus];
		[activityIndicator startAnimating];
	}
	else {
		statusLabel.text = @"";
		[activityIndicator stopAnimating];
	}
}

- (void)reload
{
	for (UIView *v in scrollView.subviews) [v removeFromSuperview];
	
	NSArray *apps = [AppManager sharedManager].allApps;
	int i = 0;
	for (App *app in apps) {
		ReviewSummaryView *summaryView = [[[ReviewSummaryView alloc] initWithFrame:CGRectMake(i * 235, 0, 224, 215) app:app] autorelease];
		[summaryView addTarget:self action:@selector(showReviews:) forControlEvents:UIControlEventTouchUpInside];
		[scrollView addSubview:summaryView];
		i++;
	}
	scrollView.contentSize = CGSizeMake(235 * [apps count], 227);
	
}

- (void)showReviews:(id)sender
{
	App *app = [(ReviewSummaryView *)sender app];
	ReviewsListController *listController = [[[ReviewsListController alloc] initWithApp:app style:UITableViewStylePlain] autorelease];
	listController.hidesBottomBarWhenPushed = YES;
	listController.title = app.appName;
	UINavigationController *reviewListNavigationController = [[[UINavigationController alloc] initWithRootViewController:listController] autorelease];
    // popover will be retained until next call to show reviews (even after dismissed)
    // could add a delegate to release it upon being dismissed
    [currentPopover release];
	currentPopover = [[UIPopoverController alloc] initWithContentViewController:reviewListNavigationController];
	
	CGRect reviewSummaryFrame = [(UIView *)sender frame];
	CGRect fromRect = CGRectMake(reviewSummaryFrame.origin.x, reviewSummaryFrame.origin.y + 20, reviewSummaryFrame.size.width, 10);
    
	[currentPopover presentPopoverFromRect:fromRect inView:[sender superview] permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
}


- (void)downloadReviews:(id)sender
{
	if ([[ReviewManager sharedManager] isDownloadingReviews])
		return;
	
	if ([AppManager sharedManager].numberOfApps == 0) {
		[[[[UIAlertView alloc] initWithTitle:@"" message:NSLocalizedString(@"Before you can download reviews, you have to download at least one daily report with this version. If you already have today's report, you can delete it and download it again.",nil) 
									delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) 
						   otherButtonTitles:nil] autorelease] show];
		return;
	}
	[[ReviewManager sharedManager] downloadReviews];
}

- (void)showReviewsController:(id)sender
{
	ReviewsController *reviewsController = [[[ReviewsController alloc] initWithStyle:UITableViewStylePlain] autorelease];
	UINavigationController *nav = [[[UINavigationController alloc] initWithRootViewController:reviewsController] autorelease];
    [currentPopover release];
	currentPopover = [[UIPopoverController alloc] initWithContentViewController:nav];
	
	CGRect fromRect = [(UIView *)sender frame];
	[currentPopover presentPopoverFromRect:fromRect inView:[sender superview] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}


- (void)dealloc 
{
	[statusLabel release];
	[activityIndicator release];
	[scrollView release];
    [currentPopover release];
    [super dealloc];
}


@end
