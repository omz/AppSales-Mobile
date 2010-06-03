//
//  ReviewsPane.m
//  AppSalesMobile
//
//  Created by Ole Zorn on 06.04.10.
//  Copyright 2010 omz:software. All rights reserved.
//

#import "ReviewsPane.h"
#import "ReportManager.h"
#import "ReviewSummaryView.h"
#import "App.h"
#import "Review.h"
#import "ReviewsListController.h"

@implementation ReviewsPane

@synthesize scrollView, statusLabel, activityIndicator, reviewsPopover;

- (id)initWithFrame:(CGRect)frame 
{
    if ((self = [super initWithFrame:frame])) {
        UIImageView *backgroundImageView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"PaneBackground.png"]] autorelease];
		backgroundImageView.contentStretch = CGRectMake(0.1, 0.1, 0.8, 0.8);
		backgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		[self addSubview:backgroundImageView];
		
		self.scrollView = [[[UIScrollView alloc] initWithFrame:CGRectMake(23, 17, 726, 227)] autorelease];
		scrollView.contentSize = CGSizeMake(1024, 227);
		scrollView.backgroundColor = [UIColor clearColor];
		[self addSubview:scrollView];
		
		self.statusLabel = [[[UILabel alloc] initWithFrame:CGRectMake(550, 268, 200, 20)] autorelease];
		statusLabel.backgroundColor = [UIColor clearColor];
		statusLabel.textColor = [UIColor darkGrayColor];
		[self addSubview:statusLabel];
		
		self.activityIndicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
		activityIndicator.frame = CGRectMake(550-20, 268+2, 16, 16);
		[self addSubview:activityIndicator];
		
		UIButton *downloadReviewsButton = [UIButton buttonWithType:UIButtonTypeCustom];
		downloadReviewsButton.frame = CGRectMake(24, 250, 209, 47);
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
		[self addSubview:downloadReviewsButton];
		
		[self reload];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:ReportManagerDownloadedDailyReportsNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:ReportManagerDownloadedReviewsNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateStatus) name:ReportManagerUpdatedReviewDownloadProgressNotification object:nil];
    }
    return self;
}

- (void)updateStatus
{
	if ([[ReportManager sharedManager] isDownloadingReviews]) {
		statusLabel.text = [[ReportManager sharedManager] reviewDownloadStatus];
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
	
	NSDictionary *apps = [[ReportManager sharedManager] appsByID];
	int i = 0;
	for (App *app in [apps allValues]) {
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
	NSArray *allReviews = [app.reviewsByUser allValues];
	ReviewsListController *listController = [[[ReviewsListController alloc] initWithStyle:UITableViewStylePlain] autorelease];
	NSSortDescriptor *reviewSorter1 = [[[NSSortDescriptor alloc] initWithKey:@"reviewDate" ascending:NO] autorelease];
	NSSortDescriptor *reviewSorter2 = [[[NSSortDescriptor alloc] initWithKey:@"downloadDate" ascending:NO] autorelease];
	NSSortDescriptor *reviewSorter3 = [[[NSSortDescriptor alloc] initWithKey:@"countryCode" ascending:YES] autorelease];
	listController.reviews = [allReviews sortedArrayUsingDescriptors:[NSArray arrayWithObjects:reviewSorter1, reviewSorter2, reviewSorter3, nil]];
	listController.hidesBottomBarWhenPushed = YES;
	listController.title = app.appName;
	listController.contentSizeForViewInPopover = CGSizeMake(320, 480);
	UINavigationController *reviewListNavigationController = [[[UINavigationController alloc] initWithRootViewController:listController] autorelease];
	self.reviewsPopover = [[[NSClassFromString(@"UIPopoverController") alloc] initWithContentViewController:reviewListNavigationController] autorelease];
	
	CGRect reviewSummaryFrame = [(UIView *)sender frame];
	CGRect fromRect = CGRectMake(reviewSummaryFrame.origin.x, reviewSummaryFrame.origin.y + 20, reviewSummaryFrame.size.width, 10);
	[reviewsPopover presentPopoverFromRect:fromRect inView:[sender superview] permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
}


- (void)downloadReviews:(id)sender
{
	if ([[ReportManager sharedManager] isDownloadingReviews])
		return;
	
	UIActionSheet *sheet = [[[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Download Reviews",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Top Countries",nil), NSLocalizedString(@"All Countries",nil), nil] autorelease];
	[sheet showFromRect:[sender frame] inView:self animated:YES];
}


- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == 2)
		return;
	if (buttonIndex == 0)
		[[ReportManager sharedManager] downloadReviewsForTopCountriesOnly:YES];
	else
		[[ReportManager sharedManager] downloadReviewsForTopCountriesOnly:NO];
}


- (void)dealloc 
{
	[statusLabel release];
	[activityIndicator release];
	[reviewsPopover release];
	[scrollView release];
    [super dealloc];
}


@end
