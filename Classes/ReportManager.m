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
#import "RegexKitLite.h"


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
		NSString *weekName = [nameFormatter stringFromDate:toDate];
		[weeksToSkip addObject:weekName];
	}
		
	[self performSelectorOnMainThread:@selector(setProgress:) withObject:NSLocalizedString(@"Starting Download...",nil) waitUntilDone:NO];
	
	NSString *originalReportsPath = [userInfo objectForKey:@"originalReportsPath"];
	NSString *username = [userInfo objectForKey:@"username"];
	NSString *password = [userInfo objectForKey:@"password"];
	
    NSString *ittsBaseURL = @"https://itunesconnect.apple.com";
	NSString *ittsLoginPageAction = @"/WebObjects/iTunesConnect.woa";
	    
    NSURL *loginURL = [NSURL URLWithString:[ittsBaseURL stringByAppendingString:ittsLoginPageAction]];
    NSString *loginPage = [NSString stringWithContentsOfURL:loginURL usedEncoding:NULL error:NULL];
    NSScanner *scanner = [NSScanner scannerWithString:loginPage];
    [scanner scanUpToString:@"action=\"" intoString:nil];
    if (! [scanner scanString:@"action=\"" intoString:nil]) {
        [self performSelectorOnMainThread:@selector(downloadFailed:) withObject:@"could not parse iTunes Connect login page" waitUntilDone:NO];
        [pool release];
        return;
    }
    NSString *loginAction = nil;
    [scanner scanUpToString:@"\"" intoString:&loginAction];

    // login
	[self performSelectorOnMainThread:@selector(setProgress:) withObject:NSLocalizedString(@"Logging in...",nil) waitUntilDone:NO];
    loginURL = [NSURL URLWithString:[ittsBaseURL stringByAppendingString:loginAction]];
    NSDictionary *postDict = [NSDictionary dictionaryWithObjectsAndKeys:
                              username, @"theAccountName",
                              password, @"theAccountPW", 
                              @"0", @"1.Continue.x",
                              @"0", @"1.Continue.y",
                              nil];
    NSString *postDictString = [postDict formatForHTTP];
    NSData *httpBody = [postDictString dataUsingEncoding:NSASCIIStringEncoding];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:loginURL];
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setHTTPBody:httpBody];
    NSData *requestResponseData = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:NULL error:NULL];
    if (requestResponseData == nil) {
        [self performSelectorOnMainThread:@selector(downloadFailed:) withObject:@"could not load iTunes Connect login page" waitUntilDone:NO];
        [pool release];
        return;
    }
    
    
    // load sales/trends page
    NSString *salesAction = @"/WebObjects/iTunesConnect.woa/wo/2.0.9.7.2.9.1.0.0.3";
    NSError *error = nil;
    NSString *salesRedirectPage = [NSString stringWithContentsOfURL:[NSURL URLWithString:[ittsBaseURL stringByAppendingString:salesAction]]
                                                       usedEncoding:NULL error:&error];
    if (error) {
        NSLog(@"unexpected error: %@", salesRedirectPage);
        [self performSelectorOnMainThread:@selector(downloadFailed:) withObject:@"could not load iTunes Connect sales/trend page" waitUntilDone:NO];
        [pool release];
        return;
    }
    
    NSString *ittsSalesPageURL = @"https://reportingitc.apple.com/sales.faces";
    NSString *salesPage = [NSString stringWithContentsOfURL:[NSURL URLWithString:ittsSalesPageURL] usedEncoding:NULL error:NULL];
	
//	XXX this likely doesn't work with the Sept 2010 changes, and needs updating
//	// check if page is "choose vendor" page (Patch by Christian Beer, thanks!)
//	if ([scanner scanUpToString:@"enctype=\"multipart/form-data\" action=\"" intoString:NULL]) {
//		NSString *chooseVendorAction = nil;
//		[scanner scanString:@"enctype=\"multipart/form-data\" action=\"" intoString:NULL];
//		[scanner scanUpToString:@"\"" intoString:&chooseVendorAction];
//		
//		// get vendor Id
//		[scanner scanUpToString:@"<option value=\"null\">" intoString:NULL];
//		[scanner scanString:@"<option value=\"null\">" intoString:NULL];
//		[scanner scanUpToString:@"<option value=\"" intoString:NULL];
//		[scanner scanString:@"<option value=\"" intoString:NULL];
//		NSString *vendorId = nil;
//		[scanner scanUpToString:@"\"" intoString:&vendorId];
//		
//		if (chooseVendorAction != nil) {
//			NSString *chooseVendorURLString = [ittsBaseURL stringByAppendingString:chooseVendorAction];
//			NSURL *chooseVendorURL = [NSURL URLWithString:chooseVendorURLString];
//			NSDictionary *chooseVendorDict = [NSDictionary dictionaryWithObjectsAndKeys:
//											  vendorId, @"9.6.0", 
//											  vendorId, @"vndrid", 
//											  @"1", @"Select1", 
//											  @"", @"9.18", nil];
//			NSString *encodedChooseVendorDict = [chooseVendorDict formatForHTTP];
//			NSData *httpBody = [encodedChooseVendorDict dataUsingEncoding:NSASCIIStringEncoding];
//			NSMutableURLRequest *chooseVendorRequest = [NSMutableURLRequest requestWithURL:chooseVendorURL];
//			[chooseVendorRequest setHTTPMethod:@"POST"];
//			[chooseVendorRequest setHTTPBody:httpBody];
//			NSData *chooseVendorSelectionPageData = [NSURLConnection sendSynchronousRequest:chooseVendorRequest returningResponse:NULL error:NULL];
//			if (chooseVendorSelectionPageData == nil) {
//				[self performSelectorOnMainThread:@selector(downloadFailed:) withObject:@"could not choose vendor" waitUntilDone:NO];
//				[pool release];
//				return;
//			}
//			NSString *chooseVendorSelectionPage = [[[NSString alloc] initWithData:chooseVendorSelectionPageData encoding:NSUTF8StringEncoding] autorelease];
//			
//			if (!chooseVendorSelectionPage)
//				NSLog(@"No chooseVendorSelectionPage");
//
//			scanner = [NSScanner scannerWithString:chooseVendorSelectionPage];
//			[scanner scanUpToString:@"enctype=\"multipart/form-data\" action=\"" intoString:NULL];
//			NSString *chooseVendorAction2 = nil;
//			[scanner scanString:@"enctype=\"multipart/form-data\" action=\"" intoString:NULL];
//			[scanner scanUpToString:@"\"" intoString:&chooseVendorAction2];
//			
//			chooseVendorURLString = [ittsBaseURL stringByAppendingString:chooseVendorAction2];
//			chooseVendorURL = [NSURL URLWithString:chooseVendorURLString];
//			chooseVendorDict = [NSDictionary dictionaryWithObjectsAndKeys:
//								vendorId, @"9.6.0", 
//								vendorId, @"vndrid", 
//								@"999998", @"Select1", 
//								@"", @"9.18", 
//								@"Submit", @"SubmitBtn", nil];
//			encodedChooseVendorDict = [chooseVendorDict formatForHTTP];
//			httpBody = [encodedChooseVendorDict dataUsingEncoding:NSASCIIStringEncoding];
//			chooseVendorRequest = [NSMutableURLRequest requestWithURL:chooseVendorURL];
//			[chooseVendorRequest setHTTPMethod:@"POST"];
//			[chooseVendorRequest setHTTPBody:httpBody];
//			chooseVendorSelectionPageData = [NSURLConnection sendSynchronousRequest:chooseVendorRequest returningResponse:NULL error:NULL];
//			if (chooseVendorSelectionPageData == nil) {;
//				[self performSelectorOnMainThread:@selector(downloadFailed:) withObject:@"could not choose vendor page 2" waitUntilDone:NO];
//				[pool release];
//				return;
//			}
//			chooseVendorSelectionPage = [[[NSString alloc] initWithData:chooseVendorSelectionPageData encoding:NSUTF8StringEncoding] autorelease];	
//			
//			if (!chooseVendorSelectionPage)
//				NSLog(@"No chooseVendorSelectionPage");
//
//			scanner = [NSScanner scannerWithString:chooseVendorSelectionPage];
//			[scanner scanUpToString:@"<td class=\"content\">" intoString:NULL];
//			[scanner scanUpToString:@"<a href=\"" intoString:NULL];
//			[scanner scanString:@"<a href=\"" intoString:NULL];
//			NSString *trendReportsAction = nil;
//			[scanner scanUpToString:@"\"" intoString:&trendReportsAction];
//			NSString *trendReportsURLString = [ittsBaseURL stringByAppendingString:trendReportsAction];
//			NSURL *trendReportsURL = [NSURL URLWithString:trendReportsURLString];
//			NSMutableURLRequest *trendReportsRequest = [NSMutableURLRequest requestWithURL:trendReportsURL];
//			[trendReportsRequest setHTTPMethod:@"GET"];
//			chooseVendorSelectionPageData = [NSURLConnection sendSynchronousRequest:trendReportsRequest returningResponse:NULL error:NULL];
//			if (chooseVendorSelectionPageData == nil) {
//				[self performSelectorOnMainThread:@selector(downloadFailed:) withObject:@"could not open trend report page" waitUntilDone:NO];
//				[pool release];
//				return;
//			}
//			dateTypeSelectionPage = [[[NSString alloc] initWithData:chooseVendorSelectionPageData encoding:NSUTF8StringEncoding] autorelease];
//		}
//	}
    
    // get the form field names needed to download the report
    NSString *viewState = [salesPage stringByMatching:@"\"javax.faces.ViewState\" value=\"(.*?)\"" capture:1];   
    
    NSString *dailyName = [salesPage stringByMatching:@"theForm:j_id_jsp_[0-9]*_21"];
    NSString *ajaxName = [dailyName stringByReplacingOccurrencesOfString:@"_21" withString:@"_2"];
//    NSString *dateName = [dailyName stringByReplacingOccurrencesOfString:@"_21" withString:@"_8"]
    NSString *selectName = [dailyName stringByReplacingOccurrencesOfString:@"_21" withString:@"_30"];
    
    // figure out which reports are available
    scanner = [NSScanner scannerWithString:salesPage];
    NSString *selectionForm = nil;     // extract the date selection form
    [scanner scanUpToString:@"datePickerSourceSelectElement" intoString:nil];
    if (! [scanner scanString:@"datePickerSourceSelectElement" intoString:nil]) {
        [self performSelectorOnMainThread:@selector(downloadFailed:) withObject:@"Could not parse date source selector element" waitUntilDone:NO];
        [pool release];
        return;
    }
    [scanner scanUpToString:@"</select>" intoString:&selectionForm];
    if (! [scanner scanString:@"</select>" intoString:nil]) {
        [self performSelectorOnMainThread:@selector(downloadFailed:) withObject:@"Could not parse date source selector values" waitUntilDone:NO];
        [pool release];
        return;
    }
    
    NSScanner *selectionScanner = [NSScanner scannerWithString:selectionForm];
    NSMutableArray *availableDays = [NSMutableArray array];
    
    while ([selectionScanner scanUpToString:@"<option value=\"" intoString:nil] && [selectionScanner scanString:@"<option value=\"" intoString:nil]) {
        NSString *selectorValue = nil;
        [selectionScanner scanUpToString:@"\"" intoString:&selectorValue];
        if (! [selectionScanner scanString:@"\"" intoString:nil]) {
            [self performSelectorOnMainThread:@selector(downloadFailed:) withObject:@"unexpected date selector html options" waitUntilDone:NO];
            [pool release];
            return;
        }
        
        [availableDays addObject:selectorValue];
    }
    [availableDays removeObjectsInArray:daysToSkip];
    
    
    // parse the weeks available
    [scanner scanUpToString:@"weekPickerSourceSelectElement" intoString:nil];
    if (! [scanner scanString:@"weekPickerSourceSelectElement" intoString:nil]) {
        [self performSelectorOnMainThread:@selector(downloadFailed:) withObject:@"Could not parse week source selector element" waitUntilDone:NO];
        [pool release];
        return;
    }
    [scanner scanUpToString:@"</select>" intoString:&selectionForm];
    if (! [scanner scanString:@"</select>" intoString:nil]) {
        [self performSelectorOnMainThread:@selector(downloadFailed:) withObject:@"Could not parse week source selector values" waitUntilDone:NO];
        [pool release];
        return;
    }
    selectionScanner = [NSScanner scannerWithString:selectionForm];
    NSMutableArray *availableWeeks = [NSMutableArray array];
    
    while ([selectionScanner scanUpToString:@"<option value=\"" intoString:nil] && [selectionScanner scanString:@"<option value=\"" intoString:nil]) {
        NSString *selectorValue = nil;
        [selectionScanner scanUpToString:@"\"" intoString:&selectorValue];
        if (! [selectionScanner scanString:@"\"" intoString:nil]) {
            [self performSelectorOnMainThread:@selector(downloadFailed:) withObject:@"unexpected week selector html options" waitUntilDone:NO];
            [pool release];
            return;
        }
        
        [availableWeeks addObject:selectorValue];
    }
    [availableWeeks removeObjectsInArray:weeksToSkip];

    
    // click though from the dashboard to the sales page
    postDict = [NSDictionary dictionaryWithObjectsAndKeys:
                ajaxName, @"AJAXREQUEST",
                @"theForm", @"theForm",
                @"notnormal", @"theForm:xyz",
                @"Y", @"theForm:vendorType",
                viewState, @"javax.faces.ViewState",
                dailyName, dailyName,
                nil];
    postDictString = [postDict formatForHTTP];
    httpBody = [postDictString dataUsingEncoding:NSASCIIStringEncoding];
    urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:ittsSalesPageURL]];
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setHTTPBody:httpBody];
    NSHTTPURLResponse *downloadResponse = nil;
    requestResponseData = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&downloadResponse error:NULL];
    NSString *responseString = [[[NSString alloc] initWithData:requestResponseData encoding:NSUTF8StringEncoding] autorelease];

    viewState = [responseString stringByMatching:@"\"javax.faces.ViewState\" value=\"(.*?)\"" capture:1];
    
    // download the reports
    const NSInteger numberOfNewReports = availableDays.count + availableWeeks.count;
    NSMutableDictionary *downloadedDays = [NSMutableDictionary dictionary];
    
    int count = 1;
    for (NSString *dayString in availableDays) {
        NSAutoreleasePool *innerPool = [NSAutoreleasePool new];
        NSString *progressMessage = [NSString stringWithFormat:NSLocalizedString(@"Downloading day %d of %d",nil), count, availableDays.count];
        count++;
        [self performSelectorOnMainThread:@selector(setProgress:) withObject:progressMessage waitUntilDone:NO];
        
        // set the date within the web page
        postDict = [NSDictionary dictionaryWithObjectsAndKeys:
                    ajaxName, @"AJAXREQUEST",
                    @"theForm", @"theForm",
                    @"theForm:xyz", @"notnormal",
                    @"Y", @"theForm:vendorType",
                    dayString, @"theForm:datePickerSourceSelectElementSales",
                    dayString, @"theForm:weekPickerSourceSelectElement",
                    viewState, @"javax.faces.ViewState",
                    selectName, selectName,
                    nil];
        postDictString = [postDict formatForHTTP];
        httpBody = [postDictString dataUsingEncoding:NSASCIIStringEncoding];
        urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:ittsSalesPageURL]];
        [urlRequest setHTTPMethod:@"POST"];
        [urlRequest setHTTPBody:httpBody];
        NSHTTPURLResponse *downloadResponse = nil;
        requestResponseData = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&downloadResponse error:NULL];
        responseString = [[[NSString alloc] initWithData:requestResponseData encoding:NSUTF8StringEncoding] autorelease];
        
        viewState = [responseString stringByMatching:@"\"javax.faces.ViewState\" value=\"(.*?)\"" capture:1];
        
        // and finally...we're ready to download the report
        postDict = [NSDictionary dictionaryWithObjectsAndKeys:
                    @"theForm", @"theForm",
                    @"notnormal", @"theForm:xyz",
                    @"Y", @"theForm:vendorType",
                    dayString, @"theForm:datePickerSourceSelectElementSales",
                    dayString, @"theForm:weekPickerSourceSelectElement",
                    viewState, @"javax.faces.ViewState",
                    @"theForm:downloadLabel2", @"theForm:downloadLabel2",
                    nil];
        postDictString = [postDict formatForHTTP];
        httpBody = [postDictString dataUsingEncoding:NSASCIIStringEncoding];
        urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:ittsSalesPageURL]];
        [urlRequest setHTTPMethod:@"POST"];
        [urlRequest setHTTPBody:httpBody];
        downloadResponse = nil;
        requestResponseData = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&downloadResponse error:NULL];
        NSString *originalFilename = [[downloadResponse allHeaderFields] objectForKey:@"Filename"];
        if (originalFilename) {
            Day *day = [self dayWithData:requestResponseData compressed:YES];
            [requestResponseData writeToFile:[originalReportsPath stringByAppendingPathComponent:originalFilename] atomically:YES];
            [downloadedDays setObject:day forKey:day.date];
        } else {
            responseString = [[[NSString alloc] initWithData:requestResponseData encoding:NSUTF8StringEncoding] autorelease];
            NSLog(@"unexpected response: %@", responseString);
            [self performSelectorOnMainThread:@selector(downloadFailed:) withObject:@"could not download report (unexpected server response)" waitUntilDone:NO];
            [innerPool release];
            [pool release];
            return;
        }
        [innerPool release];
    }
    
    [self performSelectorOnMainThread:@selector(successfullyDownloadedDays:) withObject:[[downloadedDays copy] autorelease] waitUntilDone:NO];

//		if (i == 0) {
//			// must make a copy, since we're still using the collection and we're not waiting until done
//			[self performSelectorOnMainThread:@selector(successfullyDownloadedDays:) withObject:[[downloadedDays copy] autorelease] waitUntilDone:NO];
//			[downloadedDays removeAllObjects];
//		} else {
//			[self performSelectorOnMainThread:@selector(successfullyDownloadedWeeks:) withObject:downloadedDays waitUntilDone:NO];
//		}
    
	if (numberOfNewReports == 0) {
		[self performSelectorOnMainThread:@selector(setProgress:) withObject:NSLocalizedString(@"No new reports found",nil) waitUntilDone:NO];
	} else {
		cacheChanged = YES;
		[self performSelectorOnMainThread:@selector(setProgress:) withObject:@"" waitUntilDone:NO];
		[self performSelectorOnMainThread:@selector(saveData) withObject:nil waitUntilDone:NO];
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
