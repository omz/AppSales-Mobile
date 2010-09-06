//
//  ReportManager.m
//  AppSalesMobile
//
//  Created by Ole Zorn on 10.09.09.
//  Copyright 2009 omz:software. All rights reserved.
//

#import <zlib.h>

#import "ReportManager.h"
#import "NSDictionary+HTTP.h"
#import "Day.h"
#import "Country.h"
#import "Entry.h"
#import "CurrencyManager.h"
#import "SFHFKeychainUtils.h"
#import "App.h"
#import "Review.h"
#import "NSData+Compression.h"
#import "ProgressHUD.h"
#import "AppManager.h"


@implementation ReportManager

@synthesize days, weeks, reportDownloadStatus;

+ (ReportManager *)sharedManager
{
	static ReportManager *sharedManager = nil;
	if (sharedManager == nil) {
		sharedManager = [ReportManager new];
	}
	return sharedManager;
}

- (id)init
{
	self = [super init];
	if (self) {
		days = [NSMutableDictionary new];
		weeks = [NSMutableDictionary new];

		BOOL cacheLoaded = [self loadReportCache];
		if (!cacheLoaded) {
			[[ProgressHUD sharedHUD] setText:NSLocalizedString(@"Updating Cache...",nil)];
			[[ProgressHUD sharedHUD] show];
			NSString *reportCacheFile = [self reportCachePath];
			[self performSelectorInBackground:@selector(generateReportCache:) withObject:reportCacheFile];
		}
		
		[[CurrencyManager sharedManager] refreshIfNeeded];
	}
	
	return self;
}


- (BOOL)loadReportCache
{
	NSString *reportCacheFile = [self reportCachePath];
	if (![[NSFileManager defaultManager] fileExistsAtPath:reportCacheFile]) {
		return NO;
	}
	NSDictionary *reportCache = [NSKeyedUnarchiver unarchiveObjectWithFile:reportCacheFile];
	if (!reportCache) {
		return NO;
	}
	
	for (NSDictionary *weekSummary in [[reportCache objectForKey:@"weeks"] allValues]) {
		Day *weekReport = [Day dayWithSummary:weekSummary];
		[weeks setObject:weekReport forKey:weekReport.date];
	}
	for (NSDictionary *daySummary in [[reportCache objectForKey:@"days"] allValues]) {
		Day *dayReport = [Day dayWithSummary:daySummary];
		[days setObject:dayReport forKey:dayReport.date];
	}
	
	return YES;
}

- (void)generateReportCache:(NSString *)reportCacheFile
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	NSLog(@"Generating report cache for the first time");
	
	NSString *docPath = [reportCacheFile stringByDeletingLastPathComponent];
	
	NSMutableDictionary *daysCache = [NSMutableDictionary dictionary];
	NSMutableDictionary *weeksCache = [NSMutableDictionary dictionary];
	NSArray *filenames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:docPath error:NULL];
	for (NSString *filename in filenames) {
		if (![[filename pathExtension] isEqual:@"dat"]) continue;
		NSString *fullPath = [docPath stringByAppendingPathComponent:filename];
		Day *report = [NSKeyedUnarchiver unarchiveObjectWithFile:fullPath];
		if (report != nil) {
			[report generateSummary];
			if (report.date) {
				if (report.isWeek) {
					[weeksCache setObject:report.summary forKey:report.date];
				} else  {
					[daysCache setObject:report.summary forKey:report.date];
				}
			}
		}
	}
	NSDictionary *reportCache = [NSDictionary dictionaryWithObjectsAndKeys:
								 weeksCache, @"weeks",
								 daysCache, @"days", nil];
	[NSKeyedArchiver archiveRootObject:reportCache toFile:reportCacheFile];
	[self performSelectorOnMainThread:@selector(finishGenerateReportCache:) withObject:reportCache waitUntilDone:NO];
	[pool release];
}

- (void)finishGenerateReportCache:(NSDictionary *)generatedCache
{
	[[ProgressHUD sharedHUD] hide];
	[self loadReportCache];
}

- (void)dealloc
{
	[days release];
	[weeks release];
	[reportDownloadStatus release];
	
	[super dealloc];
}

- (void)setProgress:(NSString *)status
{
	[status retain];
	[reportDownloadStatus release];
	reportDownloadStatus = status;
	[[NSNotificationCenter defaultCenter] postNotificationName:ReportManagerUpdatedDownloadProgressNotification object:self];
}

#pragma mark -
#pragma mark Report Download

- (BOOL)isDownloadingReports
{
	return isRefreshing;
}

- (void)downloadReports
{
	if (isRefreshing) {
		return;
	}
	
	[UIApplication sharedApplication].idleTimerDisabled = YES;
	
	NSError *error = nil;
	NSString *username = [[NSUserDefaults standardUserDefaults] stringForKey:@"iTunesConnectUsername"];
	NSString *password = nil;
	if (username) {
		password = [SFHFKeychainUtils getPasswordForUsername:username 
											  andServiceName:@"omz:software AppSales Mobile Service" error:&error];
	}
	if (username.length == 0 || password.length == 0) {
		UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Username / Password Missing",nil) 
														 message:NSLocalizedString(@"Please enter a username and a password in the settings.",nil) 
														delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil] autorelease];
		[alert show];
		return;
	}
	
	isRefreshing = YES;

	NSArray *daysToSkip = [days allKeys];
	NSArray *weeksToSkip = [weeks allKeys];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
							  username, @"username", 
							  password, @"password", 
							  weeksToSkip, @"weeksToSkip", 
							  daysToSkip, @"daysToSkip", 
							  [self originalReportsPath], @"originalReportsPath", nil];
	[self performSelectorInBackground:@selector(fetchReportsWithUserInfo:) withObject:userInfo];
}

- (void)fetchReportsWithUserInfo:(NSDictionary *)userInfo
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	NSArray *daysToSkipDates = [userInfo objectForKey:@"daysToSkip"];
	NSArray *weeksToSkipDates = [userInfo objectForKey:@"weeksToSkip"];
	NSMutableArray *daysToSkip = [NSMutableArray array];
	NSMutableArray *weeksToSkip = [NSMutableArray array];
	NSDateFormatter *nameFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[nameFormatter setDateFormat:@"MM/dd/yyyy"];
	for (NSDate *date in daysToSkipDates) {
		NSString *dayName = [nameFormatter stringFromDate:date];
		[daysToSkip addObject:dayName];
	}
	for (NSDate *date in weeksToSkipDates) {
		NSDate *toDate = [[[NSDate alloc] initWithTimeInterval:60*60*24*6.5 sinceDate:date] autorelease];
		NSString *weekName = [nameFormatter stringFromDate:toDate];//[NSString stringWithFormat:@"%@ To %@", [nameFormatter stringFromDate:date], [nameFormatter stringFromDate:toDate]];
		[weeksToSkip addObject:weekName];
	}
	
	NSMutableDictionary *downloadedDays = [NSMutableDictionary dictionary];
	
	[self performSelectorOnMainThread:@selector(setProgress:) withObject:NSLocalizedString(@"Starting Download...",nil) waitUntilDone:NO];
	
	NSString *originalReportsPath = [userInfo objectForKey:@"originalReportsPath"];
	NSString *username = [userInfo objectForKey:@"username"];
	NSString *password = [userInfo objectForKey:@"password"];
	
	NSString *ittsBaseURL = @"https://itts.apple.com";
	NSString *ittsLoginPageURL = @"https://itts.apple.com/cgi-bin/WebObjects/Piano.woa";
	NSString *loginPage = [NSString stringWithContentsOfURL:[NSURL URLWithString:ittsLoginPageURL] usedEncoding:NULL error:NULL];
	
	[self performSelectorOnMainThread:@selector(setProgress:) withObject:NSLocalizedString(@"Logging in...",nil) waitUntilDone:NO];
	
	if (!loginPage)
		NSLog(@"No login page");
	NSScanner *scanner = [NSScanner scannerWithString:loginPage];
	NSString *loginAction = nil;
	[scanner scanUpToString:@"method=\"post\" action=\"" intoString:NULL];
	[scanner scanString:@"method=\"post\" action=\"" intoString:NULL];
	[scanner scanUpToString:@"\"" intoString:&loginAction];
	NSString *dateTypeSelectionPage;
	if (loginAction) { //not logged in yet
		NSString *loginURLString = [ittsBaseURL stringByAppendingString:loginAction];
		NSURL *loginURL = [NSURL URLWithString:loginURLString];
		NSDictionary *loginDict = [NSDictionary dictionaryWithObjectsAndKeys:username, @"theAccountName", password, @"theAccountPW", @"0", @"1.Continue.x", @"0", @"1.Continue.y", nil];
		NSString *encodedLoginDict = [loginDict formatForHTTP];
		NSData *httpBody = [encodedLoginDict dataUsingEncoding:NSASCIIStringEncoding];
		NSMutableURLRequest *loginRequest = [NSMutableURLRequest requestWithURL:loginURL];
		[loginRequest setHTTPMethod:@"POST"];
		[loginRequest setHTTPBody:httpBody];
		NSData *dateTypeSelectionPageData = [NSURLConnection sendSynchronousRequest:loginRequest returningResponse:NULL error:NULL];
		if (dateTypeSelectionPageData == nil) {
			[self performSelectorOnMainThread:@selector(downloadFailed:) withObject:@"could not login" waitUntilDone:NO];
			[pool release];
			return;
		}
		dateTypeSelectionPage = [[[NSString alloc] initWithData:dateTypeSelectionPageData encoding:NSUTF8StringEncoding] autorelease];
	}
	else
		dateTypeSelectionPage = loginPage; //already logged in
	
	if (!dateTypeSelectionPage)
		NSLog(@"No dateTypeSelectionPage");
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
				[self performSelectorOnMainThread:@selector(downloadFailed:) withObject:@"could not choose vendor" waitUntilDone:NO];
				[pool release];
				return;
			}
			NSString *chooseVendorSelectionPage = [[[NSString alloc] initWithData:chooseVendorSelectionPageData encoding:NSUTF8StringEncoding] autorelease];
			
			if (!chooseVendorSelectionPage)
				NSLog(@"No chooseVendorSelectionPage");

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
			if (chooseVendorSelectionPageData == nil) {;
				[self performSelectorOnMainThread:@selector(downloadFailed:) withObject:@"could not choose vendor page 2" waitUntilDone:NO];
				[pool release];
				return;
			}
			chooseVendorSelectionPage = [[[NSString alloc] initWithData:chooseVendorSelectionPageData encoding:NSUTF8StringEncoding] autorelease];			
			
			if (!chooseVendorSelectionPage)
				NSLog(@"No chooseVendorSelectionPage");

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
				[self performSelectorOnMainThread:@selector(downloadFailed:) withObject:@"could not open trend report page" waitUntilDone:NO];
				[pool release];
				return;
			}
			dateTypeSelectionPage = [[[NSString alloc] initWithData:chooseVendorSelectionPageData encoding:NSUTF8StringEncoding] autorelease];
		}
	}
	
	//NSLog(@"%@", dateTypeSelectionPage);
	if (!dateTypeSelectionPage)
		NSLog(@"No dateTypeSelectionPage");

	scanner = [NSScanner scannerWithString:dateTypeSelectionPage];
	NSString *dateTypeAction = nil;
	[scanner scanUpToString:@"name=\"frmVendorPage\" action=\"" intoString:NULL];
	[scanner scanString:@"name=\"frmVendorPage\" action=\"" intoString:NULL];
	[scanner scanUpToString:@"\"" intoString:&dateTypeAction];
	if (dateTypeAction == nil) {
		//Check if we are on the "Sales/Trend Reporting Maintenance Notice" page, if so,
		//follow the "Click here to continue with Sales/Trend Module" link...
		[scanner setScanLocation:0];
		[scanner scanUpToString:@"<a href=\"/cgi-bin/WebObjects/Piano" intoString:NULL];
		[scanner scanUpToString:@"\"" intoString:NULL];
		[scanner scanString:@"\"" intoString:NULL];
		NSString *salesModuleURL = nil;
		[scanner scanUpToString:@"\"" intoString:&salesModuleURL];
		if (salesModuleURL) {
			salesModuleURL = [ittsBaseURL stringByAppendingString:salesModuleURL];
			NSData *salesModuleData = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:salesModuleURL]] returningResponse:NULL error:NULL];
			dateTypeSelectionPage = [[[NSString alloc] initWithData:salesModuleData encoding:NSUTF8StringEncoding] autorelease];
			
			if (!dateTypeSelectionPage)
				NSLog(@"No dateTypeSelectionPage");
			
			scanner = [NSScanner scannerWithString:dateTypeSelectionPage];
			[scanner scanUpToString:@"name=\"frmVendorPage\" action=\"" intoString:NULL];
			[scanner scanString:@"name=\"frmVendorPage\" action=\"" intoString:NULL];
			[scanner scanUpToString:@"\"" intoString:&dateTypeAction];
		}
		if (dateTypeAction == nil) {
			[self performSelectorOnMainThread:@selector(downloadFailed:) withObject:@"Could not select date type" waitUntilDone:NO];
			[pool release];
			return;
		}
	}
	
	NSString *errorMessageString = nil;
	[scanner setScanLocation:0];
	BOOL errorMessagePresent = [scanner scanUpToString:@"<font color=\"red\">" intoString:NULL];
	if (errorMessagePresent) {
		[scanner scanString:@"<font color=\"red\">" intoString:NULL];
		[scanner scanUpToString:@"</font>" intoString:&errorMessageString];
	}
	
	int numberOfNewReports = 0;
	for (int i=0; i<=1; i++) {
		NSString *downloadType;
		NSString *downloadActionName;
		if (i==0) {
			downloadType = @"Daily";
			downloadActionName = @"19.15.1";
		}
		else {
			downloadType = @"Weekly";
			downloadActionName = @"19.17.1";
		}
		
		NSString *dateTypeSelectionURLString = [ittsBaseURL stringByAppendingString:dateTypeAction]; 
		NSDictionary *dateTypeDict = [NSDictionary dictionaryWithObjectsAndKeys:
									  downloadType, @"19.13", 
									  downloadType, @"hiddenDayOrWeekSelection", 
									  @"Summary", @"19.11", 
									  @"ShowDropDown", @"hiddenSubmitTypeName", nil];
		NSString *encodedDateTypeDict = [dateTypeDict formatForHTTP];
		NSData *httpBody = [encodedDateTypeDict dataUsingEncoding:NSASCIIStringEncoding];
		NSMutableURLRequest *dateTypeRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:dateTypeSelectionURLString]];
		[dateTypeRequest setHTTPMethod:@"POST"];
		[dateTypeRequest setHTTPBody:httpBody];
		NSData *daySelectionPageData = [NSURLConnection sendSynchronousRequest:dateTypeRequest returningResponse:NULL error:NULL];
		
		if (daySelectionPageData == nil) {
			[self performSelectorOnMainThread:@selector(downloadFailed:) withObject:@"Could not load day selection page" waitUntilDone:NO];
			[pool release];
			return;
		}
		NSString *daySelectionPage = [[[NSString alloc] initWithData:daySelectionPageData encoding:NSUTF8StringEncoding] autorelease];
		//NSLog(@"day selection page: %@", daySelectionPage);
		if (!daySelectionPage)
			NSLog(@"No daySelectionPage");

		scanner = [NSScanner scannerWithString:daySelectionPage];
		NSMutableArray *availableDays = [NSMutableArray array];
		BOOL scannedDay = YES;
		while (scannedDay) {
			NSString *dayString = nil;
			[scanner scanUpToString:@"<option value=\"" intoString:NULL];
			[scanner scanString:@"<option value=\"" intoString:NULL];
			[scanner scanUpToString:@"\"" intoString:&dayString];
			if (dayString) {
				if ([dayString rangeOfString:@"/"].location != NSNotFound)
					[availableDays addObject:dayString];
				scannedDay = YES;
			}
			else {
				scannedDay = NO;
			}
		}
		//NSLog(@"Available %@: %@", ((i==0) ? (@"Days") : (@"Weeks")), availableDays);
		//NSLog(@"To skip: %@", ((i==0) ? (daysToSkip) : (weeksToSkip)));
		if (i==0) { //daily
			[availableDays removeObjectsInArray:daysToSkip];			
		}
		else { //weekly
			[availableDays removeObjectsInArray:weeksToSkip];
		}
		int numberOfDays = [availableDays count];
		
		if (!daySelectionPage)
			NSLog(@"No daySelectionPage");

		scanner = [NSScanner scannerWithString:daySelectionPage];
		NSString *dayDownloadAction = nil;
		[scanner scanUpToString:@"name=\"frmVendorPage\" action=\"" intoString:NULL];
		[scanner scanString:@"name=\"frmVendorPage\" action=\"" intoString:NULL];
		[scanner scanUpToString:@"\"" intoString:&dayDownloadAction];
		if (dayDownloadAction == nil) {
			[self performSelectorOnMainThread:@selector(downloadFailed:) withObject:@"could not find day download action" waitUntilDone:NO];
			[pool release];
			return;
		}
		NSString *dayDownloadActionURLString = [ittsBaseURL stringByAppendingString:dayDownloadAction];
		int dayNumber = 1;
		for (NSString *dayString in availableDays) {
			NSAutoreleasePool *innerPool = [NSAutoreleasePool new];
			NSString *status;
			if (i != 0) {
				status = [NSString stringWithFormat:NSLocalizedString(@"Weekly Report %i of %i", nil), dayNumber, numberOfDays];
			} else {
				status = [NSString stringWithFormat:NSLocalizedString(@"Daily Report %i of %i", nil), dayNumber, numberOfDays];
			}
			[self performSelectorOnMainThread:@selector(setProgress:) withObject:status waitUntilDone:NO];
			NSDictionary *dayDownloadDict = [NSDictionary dictionaryWithObjectsAndKeys:
											 downloadType, @"19.13", 
											 dayString, @"hiddenDayOrWeekSelection",
											 @"Download", @"hiddenSubmitTypeName",
											 @"ShowDropDown", @"hiddenSubmitTypeName",
											 @"Summary", @"19.11",
											 dayString, downloadActionName, 
											 @"Download", @"download", nil];
			NSString *encodedDayDownloadDict = [dayDownloadDict formatForHTTP];
			httpBody = [encodedDayDownloadDict dataUsingEncoding:NSASCIIStringEncoding];
			NSMutableURLRequest *dayDownloadRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:dayDownloadActionURLString]];
			[dayDownloadRequest setHTTPMethod:@"POST"];
			[dayDownloadRequest setHTTPBody:httpBody];
			NSHTTPURLResponse *reportDownloadResponse = nil;
			NSData *dayData = [NSURLConnection sendSynchronousRequest:dayDownloadRequest returningResponse:&reportDownloadResponse error:NULL];
			if (reportDownloadResponse) {
				NSString *originalFilename = [[reportDownloadResponse allHeaderFields] objectForKey:@"Filename"];
				if (originalFilename) {
					[dayData writeToFile:[originalReportsPath stringByAppendingPathComponent:originalFilename] atomically:YES];
				}
			}
			
			if (dayData == nil) {
				[self performSelectorOnMainThread:@selector(downloadFailed:) withObject:@"could not download raw day data" waitUntilDone:NO];
				[innerPool release];
				[pool release];
				return;
			}
			
			Day *day = [self dayWithData:dayData compressed:YES];
			if (day != nil) {
				[downloadedDays setObject:day forKey:day.date];
			}
			
			dayNumber++;
			[innerPool release];
		}
		numberOfNewReports += [downloadedDays count];
		if (i == 0) {
			// must make a copy, since we're still using the collection and we're not waiting until done
			[self performSelectorOnMainThread:@selector(successfullyDownloadedDays:) withObject:[[downloadedDays copy] autorelease] waitUntilDone:NO];
			[downloadedDays removeAllObjects];
		} else {
			[self performSelectorOnMainThread:@selector(successfullyDownloadedWeeks:) withObject:downloadedDays waitUntilDone:NO];
		}
	}
	if (numberOfNewReports == 0) {
		[self performSelectorOnMainThread:@selector(setProgress:) withObject:NSLocalizedString(@"No new reports found",nil) waitUntilDone:NO];
	} else {
		cacheChanged = YES;
		[self performSelectorOnMainThread:@selector(setProgress:) withObject:@"" waitUntilDone:NO];
		[self performSelectorOnMainThread:@selector(saveData) withObject:nil waitUntilDone:NO];
	} 
	if (errorMessageString) {
		[self performSelectorOnMainThread:@selector(presentErrorMessage:) withObject:errorMessageString waitUntilDone:NO];
	}
	[self performSelectorOnMainThread:@selector(finishFetchingReports) withObject:nil waitUntilDone:NO];
	[pool release];
}

- (void) finishFetchingReports {
	NSAssert([NSThread isMainThread], nil);
	
	isRefreshing = NO;
	[UIApplication sharedApplication].idleTimerDisabled = NO;
	[[NSNotificationCenter defaultCenter] postNotificationName:ReportManagerUpdatedDownloadProgressNotification object:self];
}



- (void)downloadFailed:(NSString*)error
{
	[UIApplication sharedApplication].idleTimerDisabled = NO;
	NSString *message = NSLocalizedString(
@"Sorry, an error occured when trying to download the report files. Please check your username, password and internet connection.",nil);
	if (error) {
		message = [message stringByAppendingFormat:@"\n%@", error];
	}
	
	isRefreshing = NO;
	[self setProgress:@""];
	UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Download Failed",nil) 
													 message:message
													delegate:nil 
										   cancelButtonTitle:NSLocalizedString(@"OK",nil)
										   otherButtonTitles:nil] autorelease];
	[alert show];
}


- (void)presentErrorMessage:(NSString *)message
{
	UIAlertView *errorAlert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Note",nil) 
														  message:message 
														 delegate:nil 
												cancelButtonTitle:NSLocalizedString(@"OK",nil) 
												otherButtonTitles:nil] autorelease];
	[errorAlert show];
}

- (void)successfullyDownloadedDays:(NSDictionary *)newDays
{
	[days addEntriesFromDictionary:newDays];
	
	AppManager *manager = [AppManager sharedManager];
	for (Day *d in [newDays allValues]) {
		for (Country *c in [d.countries allValues]) {
			for (Entry *e in c.entries) {
				[manager createOrUpdateAppIfNeededWithID:e.productIdentifier name:e.productName];
			}
		}
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ReportManagerDownloadedDailyReportsNotification object:self];
}

- (void)successfullyDownloadedWeeks:(NSDictionary *)newDays
{
	[weeks addEntriesFromDictionary:newDays];
	[[NSNotificationCenter defaultCenter] postNotificationName:ReportManagerDownloadedWeeklyReportsNotification object:self];
}


- (Day *)dayWithData:(NSData *)dayData compressed:(BOOL)compressed
{
	NSString *text = nil;
	if (compressed) {
		NSData *uncompressedData = [dayData gzipInflate];
		text = [[NSString alloc] initWithData:uncompressedData encoding:NSUTF8StringEncoding];
	} else {
		text = [[NSString alloc] initWithData:dayData encoding:NSUTF8StringEncoding];
	}
	Day *day = [[[Day alloc] initWithCSV:text] autorelease];
	[text release];
	return day;
}

- (void)importReport:(Day *)report
{
	AppManager *manager = [AppManager sharedManager];
	for (Country *c in [report.countries allValues]) {
		for (Entry *e in c.entries) {
			[manager createOrUpdateAppIfNeededWithID:e.productIdentifier name:e.productName];
		}
	}
	
	if (report.isWeek) {
		[weeks setObject:report forKey:report.date];
	} else {
		[days setObject:report forKey:report.date];
	}
}

#pragma mark -
#pragma mark Persistence


- (NSString *)originalReportsPath
{
	NSString *path = [getDocPath() stringByAppendingPathComponent:@"OriginalReports"];
	if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
		NSError *error;
		if (! [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error]) {
			[NSException raise:NSGenericException format:@"%@", error];
		}
	}
	return path;
}

- (NSString *)reportCachePath
{
	return [getDocPath() stringByAppendingPathComponent:@"ReportCache"];
}


- (void)deleteDay:(Day *)dayToDelete
{
	NSString *fullPath = [getDocPath() stringByAppendingPathComponent:dayToDelete.proposedFilename];
	NSError *error = nil;
	if (! [[NSFileManager defaultManager] removeItemAtPath:fullPath error:&error]) {
		NSLog(@"error encountered: %@", error);
	}
	
	if (dayToDelete.isWeek) {
		[weeks removeObjectForKey:dayToDelete.date];
		[[NSNotificationCenter defaultCenter] postNotificationName:ReportManagerDownloadedWeeklyReportsNotification object:self];
	} else {
		[days removeObjectForKey:dayToDelete.date];
		[[NSNotificationCenter defaultCenter] postNotificationName:ReportManagerDownloadedDailyReportsNotification object:self];
	}
	cacheChanged = YES;
	[self saveData];
}

- (void)saveData
{
	[[AppManager sharedManager] saveToDisk];
	
	//save all days/weeks in separate files:
	BOOL shouldUpdateCache = cacheChanged;
	NSString *docPath = getDocPath();
	for (Day *d in [self.days allValues]) {
		NSString *fullPath = [docPath stringByAppendingPathComponent:[d proposedFilename]];
		//wasLoadedFromDisk is set to YES in initWithCoder: ...
		if (!d.wasLoadedFromDisk) {
			[NSKeyedArchiver archiveRootObject:d toFile:fullPath];
			shouldUpdateCache = YES;
		}
	}
	for (Day *w in [self.weeks allValues]) {
		NSString *fullPath = [docPath stringByAppendingPathComponent:[w proposedFilename]];
		//wasLoadedFromDisk is set to YES in initWithCoder: ...
		if (!w.wasLoadedFromDisk) {
			[NSKeyedArchiver archiveRootObject:w toFile:fullPath];
			shouldUpdateCache = YES;
		}
	}
	if (shouldUpdateCache) {
		NSMutableDictionary *daysCache = [NSMutableDictionary dictionary];
		NSMutableDictionary *weeksCache = [NSMutableDictionary dictionary];
		for (Day *d in [days allValues]) {
			[daysCache setObject:d.summary forKey:d.date];
		}
		for (Day *w in [weeks allValues]) {
			[weeksCache setObject:w.summary forKey:w.date];
		}
		NSDictionary *reportCache = [NSDictionary dictionaryWithObjectsAndKeys:
									 weeksCache, @"weeks",
									 daysCache, @"days", nil];
		[NSKeyedArchiver archiveRootObject:reportCache toFile:[self reportCachePath]];
	}
	
	cacheChanged = NO;
}

@end
