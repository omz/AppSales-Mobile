//
//  ReviewDetailViewController.m
//  AppSales
//
//  Created by Ole Zorn on 28.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "ReviewDetailViewController.h"
#import "Review.h"
#import "Product.h"

@interface ReviewDetailViewController ()

- (void)sendReviewViaEmail;

@end


@implementation ReviewDetailViewController

@synthesize webView;

- (id)initWithReview:(Review *)aReview
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
		review = [aReview retain];
    }
    return self;
}

- (void)loadView
{
	self.webView = [[[UIWebView alloc] initWithFrame:CGRectZero] autorelease];
	webView.scalesPageToFit = YES;
	webView.dataDetectorTypes = UIDataDetectorTypeNone;
	self.view = webView;
}

- (void)viewDidLoad
{
	NSString *template = [[[NSString alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ReviewTemplate" ofType:@"html"] encoding:NSUTF8StringEncoding error:NULL] autorelease];
	template = [template stringByReplacingOccurrencesOfString:@"[[[TITLE]]]" withString:review.title];
	NSString *ratingString = [@"" stringByPaddingToLength:[review.rating integerValue] withString:@"\u2605" startingAtIndex:0];
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	NSString *reviewDateString = [dateFormatter stringFromDate:review.reviewDate];
	NSString *reviewSubtitle = [NSString stringWithFormat:@"%@<br/>%@ – %@<br/>%@ %@", ratingString, review.user, reviewDateString, [review.product displayName], review.productVersion];
	
	template = [template stringByReplacingOccurrencesOfString:@"[[[SUBTITLE]]]" withString:reviewSubtitle];
	template = [template stringByReplacingOccurrencesOfString:@"[[[CONTENT]]]" withString:review.text];
	
	UIBarButtonItem *sendReviewButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(sendReviewViaEmail)] autorelease];
	self.navigationItem.rightBarButtonItem = sendReviewButtonItem;
	
	[self.webView loadHTMLString:template baseURL:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	review.unread = [NSNumber numberWithBool:NO];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc
{
	[review release];
	[webView release];
	[super dealloc];
}

- (void)sendReviewViaEmail
{
	if (![MFMailComposeViewController canSendMail]) {
		[[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No Email Account", nil) message:NSLocalizedString(@"You have not configured this device for sending email.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] autorelease] show];
		return;
	}
	MFMailComposeViewController *mailComposeViewController = [[[MFMailComposeViewController alloc] init] autorelease];
	mailComposeViewController.mailComposeDelegate = self;
	NSString *body = [self.webView stringByEvaluatingJavaScriptFromString: @"document.body.innerHTML"];
	NSString *subject = [NSString stringWithFormat:@"Review from %@", review.user];
	[mailComposeViewController setMessageBody:body isHTML:YES];
	[mailComposeViewController setSubject:subject];
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		mailComposeViewController.modalPresentationStyle = UIModalPresentationFormSheet;
	}
	[self presentModalViewController:mailComposeViewController animated:YES];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
	[self dismissModalViewControllerAnimated:YES];
}


@end
