//
//  PromoCodesLicenseViewController.m
//  AppSales
//
//  Created by Ole Zorn on 14.08.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "PromoCodesLicenseViewController.h"
#import "DownloadStepOperation.h"
#import "MBProgressHUD.h"

@implementation PromoCodesLicenseViewController

@synthesize webView;

- (id)initWithLicenseAgreement:(NSString *)licenseAgreement operation:(DownloadStepOperation *)operation
{
	self = [super initWithNibName:nil bundle:nil];
	if (self) {
		self.title = NSLocalizedString(@"License", nil);
		licenseAgreementHTML = [licenseAgreement retain];
		downloadOperation = [operation retain];
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
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Agree", nil) style:UIBarButtonItemStyleDone target:self action:@selector(agree:)] autorelease];
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)] autorelease];
}

- (void)agree:(id)sender
{
	downloadOperation.paused = NO;
	[downloadOperation start];
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cancel:(id)sender
{
	[downloadOperation cancel];
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
	[self.webView loadHTMLString:licenseAgreementHTML baseURL:nil];
	
	[MBProgressHUD showHUDAddedTo:self.view animated:YES];
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

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	[MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (void)done:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dealloc
{
	webView.delegate = nil;
	[webView release];
	[downloadOperation release];
	[licenseAgreementHTML release];
	[super dealloc];
}

@end
