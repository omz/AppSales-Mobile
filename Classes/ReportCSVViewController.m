//
//  ReportCSVViewController.m
//  AppSales
//
//  Created by Ole Zorn on 22.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "ReportCSVViewController.h"
#import "Report.h"
#import "DarkModeCheck.h"


@implementation ReportCSVViewController

@synthesize webView;

- (instancetype)initWithReport:(Report *)selectedReport {
	self = [super init];
	if (self) {
		report = selectedReport;
	}
	return self;
}

- (void)loadView {
	WKWebViewConfiguration *theConfiguration = [[WKWebViewConfiguration alloc] init];
	self.webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:theConfiguration];
	self.webView.navigationDelegate = self;
	[self.webView setOpaque:NO];
	if (@available(iOS 13.0, *)) {
		[self.webView setBackgroundColor:[UIColor systemBackgroundColor]];
	}
	
	self.view = webView;
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(sendReport:)];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
	NSURL *cssUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"csv" ofType:@"css"]];
	NSString *cssString = [NSString stringWithContentsOfURL:cssUrl encoding:NSUTF8StringEncoding error:nil];
	cssString = [cssString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
	NSString *javascriptString = @"var style = document.createElement('style'); style.innerHTML = '%@'; document.head.appendChild(style)";
	NSString *javascriptWithCSSString = [NSString stringWithFormat:javascriptString, cssString];
	[self.webView evaluateJavaScript:javascriptWithCSSString completionHandler:nil];
}

- (void)viewWillAppear:(BOOL)animated {
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateStyle:NSDateFormatterShortStyle];
	[formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	self.navigationItem.title = [formatter stringFromDate:report.startDate];
	
	NSString *csv = [report valueForKeyPath:@"originalReport.content"];
	
	//WKWebView only recognizes commas as separators in CSV:
	csv = [csv stringByReplacingOccurrencesOfString:@"," withString:@"\uff0c"];
	csv = [csv stringByReplacingOccurrencesOfString:@"\t" withString:@","];
	
	//For whatever reason, UIWebView doesn't seem to support CSV when loading in-memory data, so we write it out to a temp file.
	NSString *tempDir = NSTemporaryDirectory();
	NSString *tempPath = [tempDir stringByAppendingPathComponent:@"temp.csv"];
	[csv writeToFile:tempPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
	[self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:tempPath]]];
}

- (void)done:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)sendReport:(id)sender {
	NSString *reportCSV = [report valueForKeyPath:@"originalReport.content"];
	NSString *filename = [report valueForKeyPath:@"originalReport.filename"];
	if ([filename hasSuffix:@".gz"]) {
		filename = [filename substringToIndex:filename.length - 3];
	}
	
    if (![MFMailComposeViewController canSendMail]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"No Email Account", nil)
                                                                       message:NSLocalizedString(@"You have not configured this device for sending email.", nil)
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
	} else {
		MFMailComposeViewController *vc = [[MFMailComposeViewController alloc] init];
		[vc setSubject:filename];
		[vc addAttachmentData:[reportCSV dataUsingEncoding:NSUTF8StringEncoding] mimeType:@"text/plain" fileName:filename];
		[vc setMailComposeDelegate:self];
		[self presentViewController:vc animated:YES completion:nil];
	}
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
	[controller dismissViewControllerAnimated:YES completion:nil];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        return UIInterfaceOrientationMaskAll;
    }
    return UIInterfaceOrientationMaskPortrait;
}


@end


@implementation ReportCSVSelectionViewController

- (instancetype)initWithReports:(NSArray *)allReports {
	self = [super initWithStyle:UITableViewStylePlain];
	if (self) {
		reports = allReports;
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
		[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	}
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [reports count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *cellIdentifier = @"Cell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	Report *report = reports[indexPath.row];
	cell.textLabel.text = [dateFormatter stringFromDate:report.startDate];
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	ReportCSVViewController *vc = [[ReportCSVViewController alloc] initWithReport:reports[indexPath.row]];
	[self.navigationController pushViewController:vc animated:YES];
}

- (void)done:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
