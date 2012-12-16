//
//  ReportCSVViewController.m
//  AppSales
//
//  Created by Ole Zorn on 22.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "ReportCSVViewController.h"
#import "Report.h"


@implementation ReportCSVViewController

@synthesize webView;

- (id)initWithReport:(Report *)selectedReport
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
		report = selectedReport;
    }
    return self;
}

- (void)loadView
{
	self.webView = [[UIWebView alloc] initWithFrame:CGRectZero];
	webView.scalesPageToFit = YES;
	webView.dataDetectorTypes = UIDataDetectorTypeNone;
	self.view = webView;
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(sendReport:)];
}

- (void)viewWillAppear:(BOOL)animated
{
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateStyle:NSDateFormatterShortStyle];
	[formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	self.navigationItem.title = [formatter stringFromDate:report.startDate];
	
	NSString *csv = [report valueForKeyPath:@"originalReport.content"];
	
	//UIWebView only recognizes commas as separators in CSV:
	csv = [csv stringByReplacingOccurrencesOfString:@"," withString:@"\uff0c"];
	csv = [csv stringByReplacingOccurrencesOfString:@"\t" withString:@","];
	
	//For whatever reason, UIWebView doesn't seem to support CSV when loading in-memory data, so we write it out to a temp file.
	NSString *tempDir = NSTemporaryDirectory();
	NSString *tempPath = [tempDir stringByAppendingPathComponent:@"temp.csv"];
	[csv writeToFile:tempPath atomically:YES encoding:NSUTF8StringEncoding error:NULL];
	[self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:tempPath]]];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)done:(id)sender
{
	[self dismissModalViewControllerAnimated:YES];
}

- (void)sendReport:(id)sender
{
	NSString *reportCSV = [report valueForKeyPath:@"originalReport.content"];
	NSString *filename = [report valueForKeyPath:@"originalReport.filename"];
	if ([filename hasSuffix:@".gz"]) {
		filename = [filename substringToIndex:filename.length - 3];
	}
	
	if (![MFMailComposeViewController canSendMail]) {
		[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No Email Account", nil) message:NSLocalizedString(@"You have not configured this device for sending email.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
	} else {
		MFMailComposeViewController *vc = [[MFMailComposeViewController alloc] init];
		[vc setSubject:filename];
		[vc addAttachmentData:[reportCSV dataUsingEncoding:NSUTF8StringEncoding] mimeType:@"text/plain" fileName:filename];
		[vc setMailComposeDelegate:self];
		[self presentModalViewController:vc animated:YES];
	}
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
	[controller dismissModalViewControllerAnimated:YES];
}


@end


@implementation ReportCSVSelectionViewController

- (id)initWithReports:(NSArray *)allReports
{
	self = [super initWithStyle:UITableViewStylePlain];
	if (self) {
		reports = allReports;
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
		[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	}
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [reports count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	ReportCSVViewController *vc = [[ReportCSVViewController alloc] initWithReport:reports[indexPath.row]];
	[self.navigationController pushViewController:vc animated:YES];
}

- (void)done:(id)sender
{
	[self dismissModalViewControllerAnimated:YES];
}


@end