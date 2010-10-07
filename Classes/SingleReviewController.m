//
//  SingleReviewController.m
//  AppSalesMobile
//
//  Created by Ole Zorn on 12.09.09.
//  Copyright 2009 omz:software. All rights reserved.
//

#import "SingleReviewController.h"
#import "Review.h"
#import "Day.h"
#import "NSDateFormatter+SharedInstances.h"
#import "NSString+UnescapeHtml.h"

@implementation SingleReviewController

@synthesize webView, review;

- (void)loadView
{
	self.view = [[[UIWebView alloc] initWithFrame:CGRectMake(0,0,320,480)] autorelease];
	self.webView = (UIWebView *)self.view;
	self.webView.dataDetectorTypes = UIDataDetectorTypeNone;
	self.webView.scalesPageToFit = NO;
	self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
}

- (CGSize)contentSizeForViewInPopover
{
	return CGSizeMake(320, 480);
}

- (void)viewWillAppear:(BOOL)animated
{
	NSString *templatePath = [[NSBundle mainBundle] pathForResource:@"ReviewTemplate" ofType:@"html"];
	NSString *template = [[[NSString alloc] initWithContentsOfFile:templatePath usedEncoding:NULL error:NULL] autorelease];
	
	template = [template stringByReplacingOccurrencesOfString:@"[[[TITLE]]]" withString:[review.presentationTitle encodeIntoBasicHtml]];
	NSDateFormatter *dateFormatter = [NSDateFormatter sharedShortDateFormatter];
	NSString *dateString = [dateFormatter stringFromDate:review.reviewDate];
	NSMutableString *starsString = [NSMutableString string];
	for (NSUInteger i=0; i<review.stars; i++) {
		[starsString appendString:@"✭"];
	}
	NSString *variousInfo = [NSString stringWithFormat:@"%@<br/>(%@) – %@ – %@", starsString, review.version, [review.user encodeIntoBasicHtml], dateString];
	template = [template stringByReplacingOccurrencesOfString:@"[[[DATE]]]" withString:variousInfo];
	template = [template stringByReplacingOccurrencesOfString:@"[[[CONTENT]]]" withString:[review.presentationText encodeIntoBasicHtml]];
	
	[self.webView loadHTMLString:template baseURL:nil];
}

- (void)dealloc 
{
	[review release];
	[webView release];
	[super dealloc];
}


@end
