//
//  AboutViewController.m
//  AppSales
//
//  Created by Ole Zorn on 02.08.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "AboutViewController.h"

NSString *const kAppGitHubRepoInfoPLIST = @"https://gitcdn.xyz/repo/nicolasgomollon/AppSales-Mobile/master/Support/AppSales-Info.plist";

@implementation AboutViewController

+ (NSString *)appVersion {
	NSString *version = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
	NSString *build = [[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"];
	return [NSString stringWithFormat:@"%@ (%@)", version, build];
}

+ (NSString *)currentBuild {
	return [[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"];
}

+ (NSString *)latestBuild {
	NSDictionary *latestInfo = [[NSDictionary alloc] initWithContentsOfURL:[NSURL URLWithString:kAppGitHubRepoInfoPLIST]];
	if (latestInfo == nil) { return nil; }
	return latestInfo[@"CFBundleVersion"];
}

+ (NSString *)aboutHTML {
	NSString *webpagePath = [[NSBundle mainBundle] pathForResource:@"About" ofType:@"html"];
	NSString *fileHTML = [[NSString alloc] initWithContentsOfFile:webpagePath encoding:NSUTF8StringEncoding error:nil];
	fileHTML = [fileHTML stringByReplacingOccurrencesOfString:@"[[APP_VERSION_BUILD]]" withString:AboutViewController.appVersion];
	return fileHTML;
}

- (void)loadView {
	[super loadView];
	
	self.title = NSLocalizedString(@"About", nil);
	
	webView = [[UIWebView alloc] initWithFrame:CGRectZero];
	if (@available(iOS 13.0, *)) {
		webView.backgroundColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
			switch (traitCollection.userInterfaceStyle) {
				case UIUserInterfaceStyleDark:
					return [UIColor systemBackgroundColor];
				default:
					return [UIColor colorWithRed:197.0f/255.0f green:204.0f/255.0f blue:212.0f/255.0f alpha:1.0f];
			}
		}];
	} else {
		webView.backgroundColor = [UIColor colorWithRed:197.0f/255.0f green:204.0f/255.0f blue:212.0f/255.0f alpha:1.0f];
	}
	webView.opaque = NO;
	webView.scalesPageToFit = YES;
	webView.dataDetectorTypes = UIDataDetectorTypeNone;
	webView.delegate = self;
	self.view = webView;
	
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	if (didCheckForUpdates) { return; }
	didCheckForUpdates = YES;
	
	NSString *aboutHTML = AboutViewController.aboutHTML;
	aboutHTML = [aboutHTML stringByReplacingOccurrencesOfString:@"[[APP_VERSION_STATUS_COLOR]]" withString:@""];
	aboutHTML = [aboutHTML stringByReplacingOccurrencesOfString:@"[[APP_VERSION_STATUS_TEXT]]" withString:@"CHECKING FOR UPDATES..."];
	[webView loadHTMLString:aboutHTML baseURL:[NSBundle mainBundle].bundleURL];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
		NSString *aboutHTML = AboutViewController.aboutHTML;
		NSString *latestBuild = AboutViewController.latestBuild;
		if (latestBuild == nil) {
			aboutHTML = [aboutHTML stringByReplacingOccurrencesOfString:@"[[APP_VERSION_STATUS_TEXT]]" withString:@"UNABLE TO CHECK FOR UPDATES"];
		} else {
			NSString *currentBuild = AboutViewController.currentBuild;
			if (currentBuild.integerValue >= latestBuild.integerValue) {
				aboutHTML = [aboutHTML stringByReplacingOccurrencesOfString:@"[[APP_VERSION_STATUS_COLOR]]" withString:@"green"];
				aboutHTML = [aboutHTML stringByReplacingOccurrencesOfString:@"[[APP_VERSION_STATUS_TEXT]]" withString:@"LATEST VERSION"];
			} else {
				aboutHTML = [aboutHTML stringByReplacingOccurrencesOfString:@"[[APP_VERSION_STATUS_COLOR]]" withString:@"orange"];
				aboutHTML = [aboutHTML stringByReplacingOccurrencesOfString:@"[[APP_VERSION_STATUS_TEXT]]" withString:@"UPDATE AVAILABLE"];
			}
		}
		dispatch_async(dispatch_get_main_queue(), ^{
            [self->webView loadHTMLString:aboutHTML baseURL:[NSBundle mainBundle].bundleURL];
			[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
		});
	});
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
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        return UIInterfaceOrientationMaskAll;
    }
    return UIInterfaceOrientationMaskPortrait;
}

@end
