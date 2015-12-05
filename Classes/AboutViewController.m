//
//  AboutViewController.m
//  AppSales
//
//  Created by Ole Zorn on 02.08.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "AboutViewController.h"

@implementation AboutViewController

+ (NSString *)appVersion {
	NSString *version = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
	NSString *build = [[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"];
	return [NSString stringWithFormat:@"%@ (%@)", version, build];
}

+ (NSString *)aboutHTML {
	NSString *webpagePath = [[NSBundle mainBundle] pathForResource:@"About" ofType:@"html"];
	NSString *fileHTML = [[NSString alloc] initWithContentsOfFile:webpagePath encoding:NSUTF8StringEncoding error:nil];
	fileHTML = [fileHTML stringByReplacingOccurrencesOfString:@"[[APP_VERSION_BUILD]]" withString:AboutViewController.appVersion];
	return fileHTML;
}

- (void)loadView {
	self.title = NSLocalizedString(@"About", nil);
	
	webView = [[UIWebView alloc] initWithFrame:CGRectZero];
	webView.backgroundColor = [UIColor colorWithRed:197.0f/255.0f green:204.0f/255.0f blue:212.0f/255.0f alpha:1.0f];
	webView.opaque = NO;
	webView.scalesPageToFit = YES;
	webView.dataDetectorTypes = UIDataDetectorTypeNone;
	webView.delegate = self;
	self.view = webView;
	
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
}

- (void)viewWillAppear:(BOOL)animated {
	[webView loadHTMLString:AboutViewController.aboutHTML baseURL:[NSBundle mainBundle].bundleURL];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
		return YES;
	}
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	if (navigationType == UIWebViewNavigationTypeLinkClicked) {
		[[UIApplication sharedApplication] openURL:[request URL]];
		return NO;
	}
	return YES;
}

- (void)done:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dealloc {
	webView.delegate = nil;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
	return UIInterfaceOrientationMaskPortrait;
}

@end
