//
//  ReportCSVViewController.h
//  AppSales
//
//  Created by Ole Zorn on 22.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@class Report;

@interface ReportCSVViewController : UIViewController <MFMailComposeViewControllerDelegate> {

	Report *report;
	UIWebView *webView;
}

@property (nonatomic, strong) UIWebView *webView;

- (instancetype)initWithReport:(Report *)selectedReport;

@end


@interface ReportCSVSelectionViewController : UITableViewController {

	NSArray *reports;
	NSDateFormatter *dateFormatter;
}

- (instancetype)initWithReports:(NSArray *)allReports;

@end