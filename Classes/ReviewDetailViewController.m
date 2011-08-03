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

@end
