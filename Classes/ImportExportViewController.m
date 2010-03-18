    //
//  ImportExportViewController.m
//  AppSalesMobile
//
//  Created by Ole Zorn on 17.03.10.
//  Copyright 2010 omz:software. All rights reserved.
//

#import "ImportExportViewController.h"
#import "HTTPServer.h"
#import "MyHTTPConnection.h"
#import "localhostAddresses.h"
#import "ZipArchive.h"
#import "SFHFKeychainUtils.h"
#import "Day.h"
#import "ReportManager.h"

@implementation ImportExportViewController

@synthesize info;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil 
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		self.hidesBottomBarWhenPushed = YES;
		self.info = NSLocalizedString(@"(Loading)",nil);
		
		NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0];
		NSString *uploadPath = [docPath stringByAppendingPathComponent:@"Uploads"];
		[[NSFileManager defaultManager] removeItemAtPath:uploadPath error:NULL];
		
		httpServer = [HTTPServer new];
		httpServer.uploadPath = uploadPath;
		[httpServer setType:@"_http._tcp."];
		[httpServer setConnectionClass:[MyHTTPConnection class]];
		[httpServer setDocumentRoot:[NSURL fileURLWithPath:[[ReportManager sharedManager] originalReportsPath]]];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(displayInfoUpdate:) name:@"LocalhostAdressesResolved" object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileUploaded:) name:NewFileUploadedNotification object:nil];
    }
    return self;
}

- (void)fileUploaded:(NSNotification *)notification
{
	NSString *filename = [notification object];
	NSString *fullPath = [httpServer.uploadPath stringByAppendingPathComponent:filename];
	
	if ([[[filename pathExtension] lowercaseString] isEqual:@"zip"]) {
		NSLog(@"Zip file uploaded: %@", fullPath);
		NSString *unzipPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"Unzip"];
		
		//Unzip the archive:
		ZipArchive *archive = [[[ZipArchive alloc] init] autorelease];
		[archive UnzipOpenFile:fullPath];
		[archive UnzipFileTo:unzipPath overWrite:YES];
		
		//Import the report files:
		NSFileManager *fm = [NSFileManager defaultManager];
		NSArray *files = [fm contentsOfDirectoryAtPath:unzipPath error:NULL];
		for (NSString *file in files) {
			if ([[file pathExtension] isEqual:@"txt"]) {
				NSString *reportPath = [unzipPath stringByAppendingPathComponent:file];
				NSString *fileContents = [[[NSString alloc] initWithContentsOfFile:reportPath] autorelease];
				Day *report = [[[Day alloc] initWithCSV:fileContents] autorelease];
				if (!report || !report.date) {
					NSLog(@"Invalid report file: %@", file);
				} else {
					[report generateNameFromDate];
					NSLog(@"Report file read: %@", report.date);
					NSLog(@"Suggested file name: %@", [report proposedFilename]);
					if (report.isWeek)
						[[ReportManager sharedManager].weeks setObject:report forKey:report.name];
					else
						[[ReportManager sharedManager].days setObject:report forKey:report.name];
					[fm copyItemAtPath:reportPath toPath:[[[ReportManager sharedManager] originalReportsPath] stringByAppendingPathComponent:file] error:NULL];
				}
			}
		}
		[[ReportManager sharedManager] saveData];
		[[NSNotificationCenter defaultCenter] postNotificationName:ReportManagerDownloadedDailyReportsNotification object:self];
		[[NSNotificationCenter defaultCenter] postNotificationName:ReportManagerDownloadedWeeklyReportsNotification object:self];
		
		//clean up:
		[fm removeItemAtPath:unzipPath error:NULL];
	} else {
		UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",nil) 
														 message:NSLocalizedString(@"You uploaded a file that does not have a .zip extension.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) 
											   otherButtonTitles:nil] autorelease];
		[alert show];
	}
}

- (void)loadView 
{	
	self.title = NSLocalizedString(@"Import / Export",nil);
	UIWebView *webView = [[[UIWebView alloc] initWithFrame:CGRectZero] autorelease];
	
	self.view = webView;
	[self showInfo];

	
	
	//[super loadView];
}

- (void)displayInfoUpdate:(NSNotification *) notification
{
	NSDictionary *addresses = [notification object];
	NSString *localIP = [addresses objectForKey:@"en0"];
	if (!localIP) {
		localIP = [addresses objectForKey:@"en1"];
	}
	
	UInt16 port = [httpServer port];
	if (!localIP) {
		self.info = NSLocalizedString(@"(no wifi)",nil);
		UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",nil) message:NSLocalizedString(@"No Wifi connection.",nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil] autorelease];
		[alert show];
	} else {
		self.info = [NSString stringWithFormat:@"http://%@:%d\n", localIP, port];
		[self showInfo];
	}
	
}


- (void)viewDidAppear:(BOOL)animated
{
	NSError *error = nil;
	if(![httpServer start:&error]) {
		NSLog(@"Error starting HTTP Server: %@", error);
		UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",nil) message:[NSString stringWithFormat:NSLocalizedString(@"The server could not be started: %@", nil), [error description]] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil] autorelease];
		[alert show];
	} else {
		NSLog(@"HTTP Server started");
		[localhostAddresses list];// performSelectorInBackground:@selector(list) withObject:nil];
		
	}
}

- (void)showInfo
{
	NSString *page = [[[NSString alloc] initWithContentsOfFile:
					   [[NSBundle mainBundle] pathForResource:@"ImportHelp" ofType:@"html"]
													  encoding:NSUTF8StringEncoding
														 error:NULL] autorelease];
	
	page = [page stringByReplacingOccurrencesOfString:@"[[[ADDRESS]]]" withString:self.info];
	
	[(UIWebView *)self.view loadHTMLString:page baseURL:nil];
}


- (void)viewDidDisappear:(BOOL)animated
{
	[httpServer stop];
}

- (void)dealloc 
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[httpServer release];
	[info release];
	
    [super dealloc];
}


@end
