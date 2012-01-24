//
//  AboutViewController.m
//  AppSales
//
//  Created by Ole Zorn on 02.08.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "AboutViewController.h"

@implementation AboutViewController

@synthesize webView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		self.title = NSLocalizedString(@"About", nil);
	}
	return self;
}

- (void)loadView
{
	self.webView = [[[UIWebView alloc] initWithFrame:CGRectZero] autorelease];
	webView.scalesPageToFit = YES;
	webView.dataDetectorTypes = UIDataDetectorTypeNone;
	webView.delegate = self;
	self.view = webView;
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)] autorelease];
}

- (void)viewWillAppear:(BOOL)animated
{
	[self.webView loadRequest:[NSURLRequest requestWithURL:[[NSBundle mainBundle] URLForResource:@"About" withExtension:@"html"]]];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		return YES;
	}
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	if (navigationType == UIWebViewNavigationTypeLinkClicked) {
		[[UIApplication sharedApplication] openURL:[request URL]];
		return NO;
	}
	return YES;
}

- (void)done:(id)sender
{
	[self dismissModalViewControllerAnimated:YES];
}

- (void)dealloc
{
	webView.delegate = nil;
	[webView release];
	[super dealloc];
}


@end
