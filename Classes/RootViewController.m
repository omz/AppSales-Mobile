/*
 RootViewController.m
 AppSalesMobile
 
 * Copyright (c) 2008, omz:software
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the <organization> nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY omz:software ''AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL <copyright holder> BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <zlib.h>
#import "RootViewController.h"
#import "AppSalesMobileAppDelegate.h"
#import "NSDictionary+HTTP.h"
#import "Day.h"
#import "Country.h"
#import "Entry.h"
#import "CurrencyManager.h"
#import "SettingsViewController.h"
#import "DaysController.h"
#import "WeeksController.h"
#import "HelpBrowser.h"
#import "SFHFKeychainUtils.h"
#import "StatisticsViewController.h"

#define LIVE_DAY_MAX_REVENUE_UPDATE_REFRESH_INTERVAL 15
#define LIVE_WEEK_MAX_REVENUE_UPDATE_REFRESH_INTERVAL 5

@interface RootViewController (Internals)

- (void)importExistingDayData;

@end


@implementation RootViewController

@synthesize days;
@synthesize weeks;

- (id)initWithCoder:(NSCoder *)coder
{
	[super initWithCoder:coder];
	
	self.days = [NSMutableDictionary dictionary];
	self.weeks = [NSMutableDictionary dictionary];
	
	NSString *docPath = [self docPath];
	NSArray *filenames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:docPath error:NULL];
	
	for (NSString *filename in filenames) {
		if (![[filename pathExtension] isEqual:@"dat"])
			continue;
		
		Day *loadedDay = [Day dayFromFile:filename atPath:docPath];

		if (loadedDay != nil) {
			if (loadedDay.isWeek)
				[self.weeks setObject:loadedDay forKey:[loadedDay name]];
			else
				[self.days setObject:loadedDay forKey:[loadedDay name]];
		}
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveData) name:UIApplicationWillTerminateNotification object:nil];
	
	[self importExistingDayData];

	/* Note the date of the most recent day for which we have data */
	BOOL checkAutomaticallyPref = [[NSUserDefaults standardUserDefaults] boolForKey:@"DownloadReportsAutomatically"];
	if (checkAutomaticallyPref == YES) {
		NSDate *lastDownloadedDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"ReportsLastDownloadedDate"];
		if (lastDownloadedDate) {
			NSDateComponents *components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit
																		   fromDate:lastDownloadedDate
																			 toDate:[NSDate date]
																			options:0];
			/* We'll never have *today's* reports, as the most recent are yesterday's. We therefore want to download
			 * if the most recent reports were older than yesterday.
			 */
			if ([components day] > 1) {
				[self downloadReports:nil];
			}
		} else {
			/* We've never downloaded before; start a download now */
			[self downloadReports:nil];	
		}
	}

	return self;
}

- (void)dealloc 
{
	self.days = nil;
	self.weeks = nil;
	
    [super dealloc];
}

- (void)saveData
{
	//save all days/weeks in separate files:
	for (Day *d in [self.days allValues]) {
		NSString *fullPath = [[self docPath] stringByAppendingPathComponent:[d proposedFilename]];
		//wasLoadedFromDisk is set to YES in initWithCoder: ...
		if (!d.wasLoadedFromDisk) {
			[NSKeyedArchiver archiveRootObject:d toFile:fullPath];
		}
	}
	for (Day *w in [self.weeks allValues]) {
		NSString *fullPath = [[self docPath] stringByAppendingPathComponent:[w proposedFilename]];
		//wasLoadedFromDisk is set to YES in initWithCoder: ...
		if (!w.wasLoadedFromDisk) {
			[NSKeyedArchiver archiveRootObject:w toFile:fullPath];
		}
	}
}

- (NSString *)docPath
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	return documentsDirectory;
}

- (void)viewDidLoad 
{
    [super viewDidLoad];
    self.navigationItem.title = @"AppSales";
	progressView.alpha = 0.0;
	
	UIButton *footer = [UIButton buttonWithType:UIButtonTypeCustom];
	[footer setFrame:CGRectMake(0,0,320,20)];
	[footer.titleLabel setFont:[UIFont systemFontOfSize:14.0]];
	[footer setTitleColor:[UIColor colorWithRed:0.3 green:0.34 blue:0.42 alpha:1.0] forState:UIControlStateNormal];
	[footer addTarget:self action:@selector(visitIconDrawer) forControlEvents:UIControlEventTouchUpInside];
	[footer setTitle:NSLocalizedString(@"Flag icons by icondrawer.com",nil) forState:UIControlStateNormal];
	[tableView setTableFooterView:footer];
	
	[[CurrencyManager sharedManager] refreshIfNeeded];
}

- (void)visitIconDrawer
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://icondrawer.com"]];
}

- (void)deleteDay:(Day *)dayToDelete
{
	NSString *fullPath = [[self docPath] stringByAppendingPathComponent:[dayToDelete proposedFilename]];
	[[NSFileManager defaultManager] removeItemAtPath:fullPath error:NULL];
	if (dayToDelete.isWeek) {
		[self.weeks removeObjectForKey:dayToDelete.name];
		[self refreshWeekList];
	}
	else {
		[self.days removeObjectForKey:dayToDelete.name];
		[self refreshDayList];
	}
}

- (void)refreshMaxDayRevenue:(NSArray *)sortedDays
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	float max = 0.1;
	int checkedSinceUpdate = 0;

	for (Day *d in sortedDays) {
		float r = [d totalRevenueInBaseCurrency];
		if (r > max)
			max = r;

		checkedSinceUpdate++;
		if (checkedSinceUpdate == LIVE_DAY_MAX_REVENUE_UPDATE_REFRESH_INTERVAL) {
			if (daysController.maxRevenue != max) {
				daysController.maxRevenue = max;
				[daysController.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
			}
			
			checkedSinceUpdate = 0;
		}		
	}

	if (daysController.maxRevenue != max) {
		daysController.maxRevenue = max;
		[daysController.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
	}
	[pool release];
}

- (void)refreshDayList
{
	NSSortDescriptor *dateSorter = [[[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO] autorelease];
	NSArray *sortedDays = [[days allValues] sortedArrayUsingDescriptors:[NSArray arrayWithObject:dateSorter]];

	[self performSelectorInBackground:@selector(refreshMaxDayRevenue:) withObject:sortedDays];

	NSMutableArray *daysByMonth = [NSMutableArray array];
	int lastMonth = -1;
	for (Day *d in sortedDays) {
		NSDate *date = d.date;
		NSDateComponents *components = [[NSCalendar currentCalendar] components:NSMonthCalendarUnit fromDate:date];
		int month = [components month];
		if (month != lastMonth) {
			[daysByMonth addObject:[NSMutableArray array]];
			lastMonth = month;
		}
		[[daysByMonth lastObject] addObject:d];
	}
	daysController.daysByMonth = daysByMonth;
	[daysController reload];
	
	[tableView reloadData];
}

- (void)refreshMaxWeekRevenue:(NSArray *)sortedWeeks
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	float max = 0.1;
	int checkedSinceUpdate = 0;

	for (Day *w in sortedWeeks) {
		float r = [w totalRevenueInBaseCurrency];

		if (r > max)
			max = r;
			
		checkedSinceUpdate++;
		if (checkedSinceUpdate == LIVE_WEEK_MAX_REVENUE_UPDATE_REFRESH_INTERVAL) {
			if (weeksController.maxRevenue != max) {
				weeksController.maxRevenue = max;
				[weeksController.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];				
			}
			checkedSinceUpdate = 0;
		}
	}

	if (weeksController.maxRevenue != max) {
		weeksController.maxRevenue = max;
		[weeksController.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];				
	}

	[pool release];
}

- (void)refreshWeekList
{
	NSSortDescriptor *dateSorter = [[[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO] autorelease];
	NSArray *sortedDays = [[weeks allValues] sortedArrayUsingDescriptors:[NSArray arrayWithObject:dateSorter]];

	[self performSelectorInBackground:@selector(refreshMaxWeekRevenue:) withObject:sortedDays];
	
	NSMutableArray *daysByMonth = [NSMutableArray array];
	int lastMonth = -1;
	for (Day *d in sortedDays) {
		NSDate *date = d.date;
		NSDateComponents *components = [[NSCalendar currentCalendar] components:NSMonthCalendarUnit fromDate:date];
		int month = [components month];
		if (month != lastMonth) {
			[daysByMonth addObject:[NSMutableArray array]];
			lastMonth = month;
		}
		[[daysByMonth lastObject] addObject:d];
	}
	weeksController.daysByMonth = daysByMonth;
	[weeksController reload];
	
	[tableView reloadData];
}

#pragma mark Download
- (void)downloadFailed
{
	isRefreshing = NO;
	[self setProgress:[NSNumber numberWithFloat:1.0]];
	UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Download Failed",nil) message:NSLocalizedString(@"Sorry, an error occured when trying to download the report files. Please check your username, password and internet connection.",nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil] autorelease];
	[alert show];
}

- (void)successfullyDownloadedDays:(NSDictionary *)newDays
{
	[days addEntriesFromDictionary:newDays];
	[self refreshDayList];

	if (daysController.daysByMonth.count) {
		NSArray *mostRecentMonth = [daysController.daysByMonth objectAtIndex:0];
		if (mostRecentMonth.count) {
			Day *day = [mostRecentMonth objectAtIndex:0];
			
			/* Note the date of the most recent day for which we have data */
			[[NSUserDefaults standardUserDefaults] setObject:day.date forKey:@"ReportsLastDownloadedDate"];
		}
	}
}

- (void)successfullyDownloadedWeeks:(NSDictionary *)newDays
{
	isRefreshing = NO;
	[self setProgress:[NSNumber numberWithFloat:1.0]];
	[weeks addEntriesFromDictionary:newDays];
	[self refreshWeekList];
	//NSLog(@"Downloaded weeks: %@", newDays);
}

- (void)setProgress:(NSNumber *)progress
{
	float p = [progress floatValue];
	//NSLog(@"progress: %f", p);
	progressView.progress = p;
	if (p <= 0.0) {
		[UIView beginAnimations:@"fade" context:nil];
		progressView.alpha = 1.0;
		[UIView commitAnimations];
	}
	if (p >= 1.0) {
		[UIView beginAnimations:@"fade" context:nil];
		progressView.alpha = 0.0;
		[UIView commitAnimations];
	}
}

Day *ImportDayData(NSData *dayData, BOOL compressed) {
	if (compressed) {
		NSString *zipFile = [NSTemporaryDirectory() stringByAppendingPathComponent:@"temp.gz"];
		NSString *textFile = [NSTemporaryDirectory() stringByAppendingPathComponent:@"temp.txt"];
		[dayData writeToFile:zipFile atomically:YES];
		gzFile file = gzopen([zipFile UTF8String], "rb");
		FILE *dest = fopen([textFile UTF8String], "w");
		unsigned char buffer[262144];
		int uncompressedLength = gzread(file, buffer, 262144);
		if(fwrite(buffer, 1, uncompressedLength, dest) != uncompressedLength || ferror(dest)) {
			NSLog(@"error writing data");
		}
		fclose(dest);
		gzclose(file);
		
		NSString *text = [NSString stringWithContentsOfFile:textFile encoding:NSUTF8StringEncoding error:NULL];
		[[NSFileManager defaultManager] removeItemAtPath:zipFile error:NULL];
		[[NSFileManager defaultManager] removeItemAtPath:textFile error:NULL];
		return [[[Day alloc] initWithCSV:text] autorelease];
	} else {
		NSString *text = [[NSString alloc] initWithData:dayData encoding:NSUTF8StringEncoding];
		Day *day = [[[Day alloc] initWithCSV:text] autorelease];
		[text release];
		return day;
	}
}

- (void)fetchReportsWithUserInfo:(NSDictionary *)userInfo
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	NSMutableDictionary *downloadedDays = [NSMutableDictionary dictionary];
	
	[self performSelectorOnMainThread:@selector(setProgress:) withObject:[NSNumber numberWithFloat:0.0] waitUntilDone:YES];
	
	NSString *username = [userInfo objectForKey:@"username"];
	NSString *password = [userInfo objectForKey:@"password"];
	
	NSString *ittsBaseURL = @"https://itts.apple.com";
	NSString *ittsLoginPageURL = @"https://itts.apple.com/cgi-bin/WebObjects/Piano.woa";
	NSString *loginPage = [NSString stringWithContentsOfURL:[NSURL URLWithString:ittsLoginPageURL]];
	
	[self performSelectorOnMainThread:@selector(setProgress:) withObject:[NSNumber numberWithFloat:0.1] waitUntilDone:YES];
	
	NSScanner *scanner = [NSScanner scannerWithString:loginPage];
	NSString *loginAction = nil;
	[scanner scanUpToString:@"name=\"appleConnectForm\" action=\"" intoString:NULL];
	[scanner scanString:@"name=\"appleConnectForm\" action=\"" intoString:NULL];
	[scanner scanUpToString:@"\"" intoString:&loginAction];
	NSString *dateTypeSelectionPage;
	if (loginAction) { //not logged in yet
		NSString *loginURLString = [ittsBaseURL stringByAppendingString:loginAction];
		NSURL *loginURL = [NSURL URLWithString:loginURLString];
		NSDictionary *loginDict = [NSDictionary dictionaryWithObjectsAndKeys:username, @"theAccountName", password, @"theAccountPW", nil];
		NSString *encodedLoginDict = [loginDict formatForHTTP];
		NSData *httpBody = [encodedLoginDict dataUsingEncoding:NSASCIIStringEncoding];
		NSMutableURLRequest *loginRequest = [NSMutableURLRequest requestWithURL:loginURL];
		[loginRequest setHTTPMethod:@"POST"];
		[loginRequest setHTTPBody:httpBody];
		NSData *dateTypeSelectionPageData = [NSURLConnection sendSynchronousRequest:loginRequest returningResponse:NULL error:NULL];
		if (dateTypeSelectionPageData == nil) {
			NSLog(@"Error: could not login");
			[pool release];
			[self performSelectorOnMainThread:@selector(downloadFailed) withObject:nil waitUntilDone:YES];
			return;
		}
		dateTypeSelectionPage = [[[NSString alloc] initWithData:dateTypeSelectionPageData encoding:NSUTF8StringEncoding] autorelease];
	}
	else
		dateTypeSelectionPage = loginPage; //already logged in
	
	[self performSelectorOnMainThread:@selector(setProgress:) withObject:[NSNumber numberWithFloat:0.2] waitUntilDone:YES];
	
	scanner = [NSScanner scannerWithString:dateTypeSelectionPage];
	
	// check if page is "choose vendor" page (Patch by Christian Beer, thanks!)
	if ([scanner scanUpToString:@"enctype=\"multipart/form-data\" action=\"" intoString:NULL]) {
		NSString *chooseVendorAction = nil;
		[scanner scanString:@"enctype=\"multipart/form-data\" action=\"" intoString:NULL];
		[scanner scanUpToString:@"\"" intoString:&chooseVendorAction];
		
		// get vendor Id
		[scanner scanUpToString:@"<option value=\"null\">" intoString:NULL];
		[scanner scanString:@"<option value=\"null\">" intoString:NULL];
		[scanner scanUpToString:@"<option value=\"" intoString:NULL];
		[scanner scanString:@"<option value=\"" intoString:NULL];
		NSString *vendorId = nil;
		[scanner scanUpToString:@"\"" intoString:&vendorId];
		
		if (chooseVendorAction != nil) {
			NSString *chooseVendorURLString = [ittsBaseURL stringByAppendingString:chooseVendorAction];
			NSURL *chooseVendorURL = [NSURL URLWithString:chooseVendorURLString];
			NSDictionary *chooseVendorDict = [NSDictionary dictionaryWithObjectsAndKeys:
											  vendorId, @"9.6.0", 
											  vendorId, @"vndrid", 
											  @"1", @"Select1", 
											  @"", @"9.18", nil];
			NSString *encodedChooseVendorDict = [chooseVendorDict formatForHTTP];
			NSData *httpBody = [encodedChooseVendorDict dataUsingEncoding:NSASCIIStringEncoding];
			NSMutableURLRequest *chooseVendorRequest = [NSMutableURLRequest requestWithURL:chooseVendorURL];
			[chooseVendorRequest setHTTPMethod:@"POST"];
			[chooseVendorRequest setHTTPBody:httpBody];
			NSData *chooseVendorSelectionPageData = [NSURLConnection sendSynchronousRequest:chooseVendorRequest returningResponse:NULL error:NULL];
			if (chooseVendorSelectionPageData == nil) {
				NSLog(@"Error: could not choose vendor");
				[pool release];
				[self performSelectorOnMainThread:@selector(downloadFailed) withObject:nil waitUntilDone:YES];
				return;
			}
			NSString *chooseVendorSelectionPage = [[[NSString alloc] initWithData:chooseVendorSelectionPageData encoding:NSUTF8StringEncoding] autorelease];
			
			scanner = [NSScanner scannerWithString:chooseVendorSelectionPage];
			[scanner scanUpToString:@"enctype=\"multipart/form-data\" action=\"" intoString:NULL];
			NSString *chooseVendorAction2 = nil;
			[scanner scanString:@"enctype=\"multipart/form-data\" action=\"" intoString:NULL];
			[scanner scanUpToString:@"\"" intoString:&chooseVendorAction2];
			
			chooseVendorURLString = [ittsBaseURL stringByAppendingString:chooseVendorAction2];
			chooseVendorURL = [NSURL URLWithString:chooseVendorURLString];
			chooseVendorDict = [NSDictionary dictionaryWithObjectsAndKeys:
								vendorId, @"9.6.0", 
								vendorId, @"vndrid", 
								@"999998", @"Select1", 
								@"", @"9.18", 
								@"Submit", @"SubmitBtn", nil];
			encodedChooseVendorDict = [chooseVendorDict formatForHTTP];
			httpBody = [encodedChooseVendorDict dataUsingEncoding:NSASCIIStringEncoding];
			chooseVendorRequest = [NSMutableURLRequest requestWithURL:chooseVendorURL];
			[chooseVendorRequest setHTTPMethod:@"POST"];
			[chooseVendorRequest setHTTPBody:httpBody];
			chooseVendorSelectionPageData = [NSURLConnection sendSynchronousRequest:chooseVendorRequest returningResponse:NULL error:NULL];
			if (chooseVendorSelectionPageData == nil) {
				NSLog(@"Error: could not choose vendor page 2");
				[pool release];
				[self performSelectorOnMainThread:@selector(downloadFailed) withObject:nil waitUntilDone:YES];
				return;
			}
			chooseVendorSelectionPage = [[[NSString alloc] initWithData:chooseVendorSelectionPageData encoding:NSUTF8StringEncoding] autorelease];			
			
			scanner = [NSScanner scannerWithString:chooseVendorSelectionPage];
			[scanner scanUpToString:@"<td class=\"content\">" intoString:NULL];
			[scanner scanUpToString:@"<a href=\"" intoString:NULL];
			[scanner scanString:@"<a href=\"" intoString:NULL];
			NSString *trendReportsAction = nil;
			[scanner scanUpToString:@"\"" intoString:&trendReportsAction];
			NSString *trendReportsURLString = [ittsBaseURL stringByAppendingString:trendReportsAction];
			NSURL *trendReportsURL = [NSURL URLWithString:trendReportsURLString];
			NSMutableURLRequest *trendReportsRequest = [NSMutableURLRequest requestWithURL:trendReportsURL];
			[trendReportsRequest setHTTPMethod:@"GET"];
			chooseVendorSelectionPageData = [NSURLConnection sendSynchronousRequest:trendReportsRequest returningResponse:NULL error:NULL];
			if (chooseVendorSelectionPageData == nil) {
				NSLog(@"Error: could not open trend report page");
				[pool release];
				[self performSelectorOnMainThread:@selector(downloadFailed) withObject:nil waitUntilDone:YES];
				return;
			}
			dateTypeSelectionPage = [[[NSString alloc] initWithData:chooseVendorSelectionPageData encoding:NSUTF8StringEncoding] autorelease];
		}
	}
	
	scanner = [NSScanner scannerWithString:dateTypeSelectionPage];
	NSString *dateTypeAction = nil;
	[scanner scanUpToString:@"name=\"frmVendorPage\" action=\"" intoString:NULL];
	[scanner scanString:@"name=\"frmVendorPage\" action=\"" intoString:NULL];
	[scanner scanUpToString:@"\"" intoString:&dateTypeAction];
	if (dateTypeAction == nil) {
		NSLog(@"Error: couldn't select date type");
		[pool release];
		[self performSelectorOnMainThread:@selector(downloadFailed) withObject:nil waitUntilDone:YES];
		return;
	}
	
	float prog = 0.2;
	for (int i=0; i<=1; i++) {
		NSString *downloadType;
		NSString *downloadActionName;
		if (i==0) {
			downloadType = @"Daily";
			downloadActionName = @"9.11.1";
		}
		else {
			downloadType = @"Weekly";
			downloadActionName = @"9.13.1";
		}
		
		NSString *dateTypeSelectionURLString = [ittsBaseURL stringByAppendingString:dateTypeAction]; 
		NSDictionary *dateTypeDict = [NSDictionary dictionaryWithObjectsAndKeys:
									  downloadType, @"9.9", 
									  downloadType, @"hiddenDayOrWeekSelection", 
									  @"Summary", @"9.7", 
									  @"ShowDropDown", @"hiddenSubmitTypeName", nil];
		NSString *encodedDateTypeDict = [dateTypeDict formatForHTTP];
		NSData *httpBody = [encodedDateTypeDict dataUsingEncoding:NSASCIIStringEncoding];
		NSMutableURLRequest *dateTypeRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:dateTypeSelectionURLString]];
		[dateTypeRequest setHTTPMethod:@"POST"];
		[dateTypeRequest setHTTPBody:httpBody];
		NSData *daySelectionPageData = [NSURLConnection sendSynchronousRequest:dateTypeRequest returningResponse:NULL error:NULL];
		
		if (daySelectionPageData == nil) {
			[pool release];
			[self performSelectorOnMainThread:@selector(downloadFailed) withObject:nil waitUntilDone:YES];
			return;
		}
		NSString *daySelectionPage = [[[NSString alloc] initWithData:daySelectionPageData encoding:NSUTF8StringEncoding] autorelease];
		scanner = [NSScanner scannerWithString:daySelectionPage];
		NSMutableArray *availableDays = [NSMutableArray array];
		BOOL scannedDay = YES;
		while (scannedDay) {
			NSString *dayString = nil;
			scannedDay = [scanner scanUpToString:@"<option value=\"" intoString:NULL];
			scannedDay = [scanner scanString:@"<option value=\"" intoString:NULL];
			scannedDay = [scanner scanUpToString:@"\"" intoString:&dayString];
			if (dayString) {
				if ([dayString rangeOfString:@"/"].location != NSNotFound)
					[availableDays addObject:dayString];
				scannedDay = YES;
			}
			else {
				scannedDay = NO;
			}
		}
		
		if (i==0) { //daily
			NSArray *daysToSkip = [userInfo objectForKey:@"daysToSkip"];
			[availableDays removeObjectsInArray:daysToSkip];			
		}
		else { //weekly
			NSArray *weeksToSkip = [userInfo objectForKey:@"weeksToSkip"];
			[availableDays removeObjectsInArray:weeksToSkip];
		}
		
		float progressForOneDay = 0.4 / ((float)[availableDays count]);
		scanner = [NSScanner scannerWithString:daySelectionPage];
		NSString *dayDownloadAction = nil;
		[scanner scanUpToString:@"name=\"frmVendorPage\" action=\"" intoString:NULL];
		[scanner scanString:@"name=\"frmVendorPage\" action=\"" intoString:NULL];
		[scanner scanUpToString:@"\"" intoString:&dayDownloadAction];
		if (dayDownloadAction == nil) {
			[pool release];
			[self performSelectorOnMainThread:@selector(downloadFailed) withObject:nil waitUntilDone:YES];
			return;
		}
		NSString *dayDownloadActionURLString = [ittsBaseURL stringByAppendingString:dayDownloadAction];
		for (NSString *dayString in availableDays) {
			NSDictionary *dayDownloadDict = [NSDictionary dictionaryWithObjectsAndKeys:
											 downloadType, @"9.9", 
											 downloadType, @"hiddenDayOrWeekSelection",
											 @"Download", @"hiddenSubmitTypeName",
											 @"Summary", @"9.7",
											 dayString, downloadActionName, 
											 @"Download", @"download", nil];
			NSString *encodedDayDownloadDict = [dayDownloadDict formatForHTTP];
			httpBody = [encodedDayDownloadDict dataUsingEncoding:NSASCIIStringEncoding];
			NSMutableURLRequest *dayDownloadRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:dayDownloadActionURLString]];
			[dayDownloadRequest setHTTPMethod:@"POST"];
			[dayDownloadRequest setHTTPBody:httpBody];
			NSData *dayData = [NSURLConnection sendSynchronousRequest:dayDownloadRequest returningResponse:NULL error:NULL];
			
			if (dayData == nil) {
				[pool release];
				[self performSelectorOnMainThread:@selector(downloadFailed) withObject:nil waitUntilDone:YES];
				return;
			}
			
			Day *day = ImportDayData(dayData, YES);
			if (day != nil) {
				if (i != 0)
					day.isWeek = YES;
				[downloadedDays setObject:day forKey:dayString];
				day.name = dayString;
			}
			
			prog += progressForOneDay;
			[self performSelectorOnMainThread:@selector(setProgress:) withObject:[NSNumber numberWithFloat:prog] waitUntilDone:YES];
		}
		if (i == 0) {
			[self performSelectorOnMainThread:@selector(successfullyDownloadedDays:) withObject:downloadedDays waitUntilDone:YES];
			[downloadedDays removeAllObjects];
		}
		else
			[self performSelectorOnMainThread:@selector(successfullyDownloadedWeeks:) withObject:downloadedDays waitUntilDone:YES];
	}

	[pool release];
}

- (IBAction)downloadReports:(id)sender
{
	if (!isRefreshing) {
		NSError *error = nil;
		NSString *username = [[NSUserDefaults standardUserDefaults] stringForKey:@"iTunesConnectUsername"];
		NSString *password = (username ?
							  [SFHFKeychainUtils getPasswordForUsername:username
														 andServiceName:@"omz:software AppSales Mobile Service"
																  error:&error] :
							  nil);
		if (!username || !password || [username isEqual:@""] || [password isEqual:@""]) {
			UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Username / Password Missing",nil) message:NSLocalizedString(@"Please enter a username and a password in the settings.",nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil] autorelease];
			[alert show];
			return;
		}
		
		isRefreshing = YES;
		NSArray *daysToSkip = [days allKeys];
		NSArray *weeksToSkip = [weeks allKeys];
		NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:username, @"username", password, @"password", weeksToSkip, @"weeksToSkip", daysToSkip, @"daysToSkip", nil];
		[self performSelectorInBackground:@selector(fetchReportsWithUserInfo:) withObject:userInfo];
	}
}

#pragma mark Table View methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	if (section == 0)
		return 3; //daily + weekly + statistics
	else
		return 2; //settings + about
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if (section == 0)
		return NSLocalizedString(@"View Reports",nil);
	else
		return nil; // NSLocalizedString(@"Configuration",nil);
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
	int row = [indexPath row];
	int section = [indexPath section];
	if ((row == 0) && (section == 0)) {
		cell.imageView.image = [UIImage imageNamed:@"Daily.png"];
		//display trend:
		if ([days count] >= 2) {
			NSSortDescriptor *dateSorter = [[[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO] autorelease];
			NSArray *sortedWeeks = [[days allValues] sortedArrayUsingDescriptors:[NSArray arrayWithObject:dateSorter]];
			Day *lastWeek = [sortedWeeks objectAtIndex:0];
			Day *previousWeek = [sortedWeeks objectAtIndex:1];
			float lastRevenue = [lastWeek totalRevenueInBaseCurrency];
			float previousRevenue = [previousWeek totalRevenueInBaseCurrency];
			float percent = (previousRevenue > 0) ? (lastRevenue / previousRevenue) : 0.0;
			if (percent != 0.0) {
				float diff = percent - 1.0;
				NSNumberFormatter *formatter = [[NSNumberFormatter new] autorelease];
				[formatter setMaximumFractionDigits:1];
				[formatter setMinimumIntegerDigits:1];
				NSString *percentString = [formatter stringFromNumber:[NSNumber numberWithFloat:fabsf(diff)*100]];
				if (diff > 0)
					cell.textLabel.text = [NSString stringWithFormat:@"%@ (+ %@%%)", NSLocalizedString(@"Daily",nil), percentString];
				else
					cell.textLabel.text = [NSString stringWithFormat:@"%@ (- %@%%)", NSLocalizedString(@"Daily",nil), percentString];
			}
			else
				cell.textLabel.text = NSLocalizedString(@"Daily",nil);
		}
		else {
			cell.textLabel.text = NSLocalizedString(@"Daily",nil);
		}
	}
	else if ((row == 1) && (section == 0)) {
		cell.imageView.image = [UIImage imageNamed:@"Weekly.png"];
		if ([weeks count] >= 2) {
			NSSortDescriptor *dateSorter = [[[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO] autorelease];
			NSArray *sortedWeeks = [[weeks allValues] sortedArrayUsingDescriptors:[NSArray arrayWithObject:dateSorter]];
			Day *lastWeek = [sortedWeeks objectAtIndex:0];
			Day *previousWeek = [sortedWeeks objectAtIndex:1];
			float lastRevenue = [lastWeek totalRevenueInBaseCurrency];
			float previousRevenue = [previousWeek totalRevenueInBaseCurrency];
			float percent = (previousRevenue > 0) ? (lastRevenue / previousRevenue) : 0.0;
			if (percent != 0.0) {
				float diff = percent - 1.0;
				NSNumberFormatter *formatter = [[NSNumberFormatter new] autorelease];
				[formatter setMaximumFractionDigits:1];
				[formatter setMinimumIntegerDigits:1];
				NSString *percentString = [formatter stringFromNumber:[NSNumber numberWithFloat:fabsf(diff)*100]];
				if (diff > 0)
					cell.textLabel.text = [NSString stringWithFormat:@"%@ (+ %@%%)", NSLocalizedString(@"Weekly",nil), percentString];
				else
					cell.textLabel.text = [NSString stringWithFormat:@"%@ (- %@%%)", NSLocalizedString(@"Weekly",nil), percentString];
			}
			else
				cell.textLabel.text = NSLocalizedString(@"Weekly",nil);
		}
		else {
			cell.textLabel.text = NSLocalizedString(@"Weekly",nil);
		}
	}
	else if ((row == 2) && (section == 0)) {
		cell.imageView.image = [UIImage imageNamed:@"Statistics.png"];
		cell.textLabel.text = NSLocalizedString(@"Graphs",nil);
	}
	else if ((row == 0) && (section == 1)) {
		cell.imageView.image = [UIImage imageNamed:@"Settings.png"];
		cell.textLabel.text = NSLocalizedString(@"Settings",nil);
	}
	else if ((row == 1) && (section == 1)) {
		cell.imageView.image = [UIImage imageNamed:@"About.png"];
		cell.textLabel.text = NSLocalizedString(@"About",nil);
	}
    return cell;
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	int row = [indexPath row];
	int section = [indexPath section];
	if ((row == 0) && (section == 0)) {
		[self refreshDayList];
		[self.navigationController pushViewController:daysController animated:YES];
	}
	else if ((row == 0) && (section == 1)) {
		[self.navigationController pushViewController:settingsController animated:YES];
	}
	else if ((row == 1) && (section == 0)) {
		[self refreshWeekList];
		[self.navigationController pushViewController:weeksController animated:YES];
	}
	else if ((row == 2) && (section == 0)) {
		StatisticsViewController *statVC = [[StatisticsViewController new] autorelease];
		NSSortDescriptor *dateSorter = [[[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES] autorelease];
		NSArray *sortedDays = [[self.days allValues] sortedArrayUsingDescriptors:[NSArray arrayWithObject:dateSorter]];
		statVC.days = sortedDays;
		[self.navigationController pushViewController:statVC animated:YES];
		
	}
	else if ((row == 1) && (section == 1)) {
		HelpBrowser *browser = [[HelpBrowser new] autorelease];
		[self.navigationController pushViewController:browser animated:YES];
	}
	
	[aTableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark Import

NSString *importDayDataDayName(NSString *file) {
	NSArray *components = [file componentsSeparatedByString:@"_"];
	if ([components count] == 6) {
		NSString *date = [components objectAtIndex:4];
		if ([date length] == 8) {
			return [NSString stringWithFormat:@"%@/%@/%@", [date substringWithRange:NSMakeRange(4, 2)],
					[date substringWithRange:NSMakeRange(6, 2)], [date substringWithRange:NSMakeRange(0, 4)]];
		} else {
			return nil;
		}
	} else {
		return nil;
	}
}

- (void)importExistingDayData
{
	NSArray *daysToSkip = [days allKeys];
	NSArray *weeksToSkip = [weeks allKeys];
	NSMutableDictionary *downloadedDays = [NSMutableDictionary dictionary];
	NSMutableDictionary *downloadedWeeks = [NSMutableDictionary dictionary];
	
	NSString *path = [[NSBundle mainBundle] bundlePath];
	NSFileManager *fman = [NSFileManager defaultManager];
	NSArray *dir = [fman directoryContentsAtPath:path];
	for (NSString *file in dir) {
		if ([file hasPrefix:@"S_D_"]) {
			NSString *dayString = importDayDataDayName(file);
			if (![daysToSkip containsObject:dayString]) {
				Day *day = ImportDayData([NSData dataWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", path, file]], [file hasSuffix:@".gz"]);
				if (day != nil) {
					NSLog(@"IMPORTED DAY %@", day);
					[downloadedDays setObject:day forKey:dayString];
					day.name = dayString;
				} else {
					NSLog(@"FAILED %@", file);
				}
			} else {
				NSLog(@"SKIPPING %@", dayString);
			}
		}
		else if ([file hasPrefix:@"S_W_"]) {
			NSString *weekString = importDayDataDayName(file);
			if (![weeksToSkip containsObject:weekString]) {
				Day *week = ImportDayData([NSData dataWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", path, file]], [file hasSuffix:@".gz"]);
				if (week != nil) {
					NSLog(@"IMPORTED WEEK %@", week);
					[downloadedWeeks setObject:week forKey:weekString];
					week.name = weekString;
					week.isWeek = YES;
				} else {
					NSLog(@"FAILED %@", file);
				}
			} else {
				NSLog(@"SKIPPING %@", weekString);
			}
		}
	}
	
	[self performSelectorOnMainThread:@selector(successfullyDownloadedDays:) withObject:downloadedDays waitUntilDone:YES];
	[self performSelectorOnMainThread:@selector(successfullyDownloadedWeeks:) withObject:downloadedWeeks waitUntilDone:YES];
}

@end

