//
//  SingleReviewController.m
//  AppSalesMobile
//
//  Created by Ole Zorn on 12.09.09.
//  Copyright 2009 omz:software. All rights reserved.
//

#import "SingleReviewController.h"
#import "Review.h"

@implementation SingleReviewController

@synthesize webView, review;

- (void)loadView
{
	self.view = [[[UIWebView alloc] initWithFrame:CGRectMake(0,0,320,480)] autorelease];
	self.webView = (UIWebView *)self.view;
	self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	self.webView.scalesPageToFit = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
	NSString *templatePath = [[NSBundle mainBundle] pathForResource:@"ReviewTemplate" ofType:@"html"];
	NSString *template = [[[NSString alloc] initWithContentsOfFile:templatePath usedEncoding:NULL error:NULL] autorelease];
	
	template = [template stringByReplacingOccurrencesOfString:@"[[[TITLE]]]" withString:review.title];
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
	NSString *dateString = [dateFormatter stringFromDate:review.reviewDate];
	NSMutableString *starsString = [NSMutableString string];
	for (int i=0; i<review.stars; i++) {
		[starsString appendString:@"✭"];
	}
	NSString *variousInfo = [NSString stringWithFormat:@"%@<br/>(%@) – %@ – %@", starsString, review.version, review.user, dateString];
	template = [template stringByReplacingOccurrencesOfString:@"[[[DATE]]]" withString:variousInfo];
	template = [template stringByReplacingOccurrencesOfString:@"[[[CONTENT]]]" withString:review.text];
	
	[self.webView loadHTMLString:template baseURL:nil];
}

- (void)dealloc 
{
	[review release];
	[webView release];
	[super dealloc];
}


@end
