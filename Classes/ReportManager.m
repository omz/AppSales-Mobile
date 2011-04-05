//
//  ReportManager.m
//  AppSalesMobile
//
//  Created by Ole Zorn on 10.09.09.
//  Copyright 2009 omz:software. All rights reserved.
//

#import "ReportManager.h"
#import "NSDictionary+HTTP.h"
#import "Day.h"
#import "Country.h"
#import "Entry.h"
#import "CurrencyManager.h"
#import "SFHFKeychainUtils.h"
#import "App.h"
#import "Review.h"
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
							  [self originalReportsPath], @"originalReportsPath",
                              nil];
	[self performSelectorInBackground:@selector(fetchReportsWithUserInfo:) withObject:userInfo];
}
#define ITTS_VENDOR_DEFAULT_URL @"https://reportingitc.apple.com/vendor_default.faces"
#define ITTS_SALES_PAGE_URL @"https://reportingitc.apple.com/sales.faces"

static NSMutableArray* extractFormOptions(NSString *htmlPage, NSString *formID) {
    NSScanner *scanner = [NSScanner scannerWithString:htmlPage];
    NSString *selectionForm = nil;
    [scanner scanUpToString:formID intoString:nil];
    if (! [scanner scanString:formID intoString:nil]) {
        return nil;
    }
    [scanner scanUpToString:@"</select>" intoString:&selectionForm];
    if (! [scanner scanString:@"</select>" intoString:nil]) {
        return nil;
    }
    
    NSMutableArray *options = [NSMutableArray array];
    NSScanner *selectionScanner = [NSScanner scannerWithString:selectionForm];
    while ([selectionScanner scanUpToString:@"<option value=\"" intoString:nil] && [selectionScanner scanString:@"<option value=\"" intoString:nil]) {
        NSString *selectorValue = nil;
        [selectionScanner scanUpToString:@"\"" intoString:&selectorValue];
        if (! [selectionScanner scanString:@"\"" intoString:nil]) {
            return nil;
        }
        
        [options addObject:selectorValue];
    }
    return options;
}

static NSData* getPostRequestAsData(NSString *urlString, NSDictionary *postDict, NSHTTPURLResponse **downloadResponse) {
    NSString *postDictString = [postDict formatForHTTP];
    NSData *httpBody = [postDictString dataUsingEncoding:NSASCIIStringEncoding];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setHTTPBody:httpBody];
    return [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:downloadResponse error:NULL];
}
static NSString* getPostRequestAsString(NSString *urlString, NSDictionary *postDict) {
    return [[[NSString alloc] initWithData:getPostRequestAsData(urlString, postDict, nil) encoding:NSUTF8StringEncoding] autorelease];
}

static NSString* parseViewState(NSString *htmlPage) {
    return [htmlPage stringByMatching:@"\"javax.faces.ViewState\" value=\"(.*?)\"" capture:1];
}

// code path shared for both day and week downloads
static Day* downloadReport(NSString *originalReportsPath, NSString *ajaxName, NSString *dayString, 
                           NSString *weekString, NSString *selectName, NSString **viewState, BOOL *error)  {
    // set the date within the web page
    NSDictionary *postDict = [NSDictionary dictionaryWithObjectsAndKeys:
                              ajaxName, @"AJAXREQUEST",
                              @"theForm", @"theForm",
                              @"theForm:xyz", @"notnormal",
                              @"Y", @"theForm:vendorType",
                              dayString, @"theForm:datePickerSourceSelectElementSales",
                              weekString, @"theForm:weekPickerSourceSelectElement",
                              *viewState, @"javax.faces.ViewState",
                              selectName, selectName,
                              nil];
    NSString *responseString = getPostRequestAsString(ITTS_SALES_PAGE_URL, postDict);
    *viewState = parseViewState(responseString);
    
    // iTC shows a (fixed?) number of date ranges in the form, even if all of them are not available 
    // if trying to download a report that doesn't exist, it'll return an error page instead of the report
    if ([responseString rangeOfString:@"theForm:errorPanel"].location != NSNotFound) {
#if APPSALES_DEBUG
        NSLog(@"report not available for @% @%", dayString, weekString);
#endif
        return nil;
    }
    
    // and finally...we're ready to download the report
    postDict = [NSDictionary dictionaryWithObjectsAndKeys:
                @"theForm", @"theForm",
                @"notnormal", @"theForm:xyz",
                @"Y", @"theForm:vendorType",
                dayString, @"theForm:datePickerSourceSelectElementSales",
                weekString, @"theForm:weekPickerSourceSelectElement",
                *viewState, @"javax.faces.ViewState",
                @"theForm:downloadLabel2", @"theForm:downloadLabel2",
                nil];
    NSHTTPURLResponse *downloadResponse = nil;
    NSData *requestResponseData = getPostRequestAsData(ITTS_SALES_PAGE_URL, postDict, &downloadResponse);
    NSString *originalFilename = [[downloadResponse allHeaderFields] objectForKey:@"Filename"];
    if (originalFilename) {
        [requestResponseData writeToFile:[originalReportsPath stringByAppendingPathComponent:originalFilename] atomically:YES];
        return[Day dayWithData:requestResponseData compressed:YES];
    } else {
        responseString = [[[NSString alloc] initWithData:requestResponseData encoding:NSUTF8StringEncoding] autorelease];
        NSLog(@"unexpected response: %@", responseString);
        *error = YES;
        return nil;
    }   
}

- (void)fetchReportsWithUserInfo:(NSDictionary *)userInfo
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	NSScanner *scanner;
    [self performSelectorOnMainThread:@selector(setProgress:) withObject:NSLocalizedString(@"Starting Download...",nil) waitUntilDone:NO];
    
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
	
	NSString *originalReportsPath = [userInfo objectForKey:@"originalReportsPath"];
	NSString *username = [userInfo objectForKey:@"username"];
	NSString *password = [userInfo objectForKey:@"password"];
	
    NSString *ittsBaseURL = @"https://itunesconnect.apple.com";
	NSString *ittsLoginPageAction = @"/WebObjects/iTunesConnect.woa";
    NSString *signoutSentinel = @"name=\"signOutForm\"";
    
    NSURL *loginURL = [NSURL URLWithString:[ittsBaseURL stringByAppendingString:ittsLoginPageAction]];
    NSString *loginPage = [NSString stringWithContentsOfURL:loginURL usedEncoding:NULL error:NULL];
    if ([loginPage rangeOfString:signoutSentinel].location == NSNotFound) {
        [self performSelectorOnMainThread:@selector(setProgress:) withObject:NSLocalizedString(@"Logging in...",nil) waitUntilDone:NO];
        
        // find the login action
        scanner = [NSScanner scannerWithString:loginPage];
        [scanner scanUpToString:@"action=\"" intoString:nil];
        if (! [scanner scanString:@"action=\"" intoString:nil]) {
            [self performSelectorOnMainThread:@selector(downloadFailed:) withObject:@"could not parse iTunes Connect login page" waitUntilDone:NO];
            [pool release];
            return;
        }
        NSString *loginAction = nil;
        [scanner scanUpToString:@"\"" intoString:&loginAction];
        
        NSDictionary *postDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                  username, @"theAccountName",
                                  password, @"theAccountPW", 
                                  @"39", @"1.Continue.x", // coordinates of submit button on screen.  any values seem to work
                                  @"7", @"1.Continue.y",
                                  nil];
        loginPage = getPostRequestAsString([ittsBaseURL stringByAppendingString:loginAction], postDict);
        if (loginPage == nil || [loginPage rangeOfString:signoutSentinel].location == NSNotFound) {
            [self performSelectorOnMainThread:@selector(downloadFailed:) withObject:@"could not load iTunes Connect login page" waitUntilDone:NO];
            [pool release];
            return;
        }
    } // else, already logged in
	
    // load sales/trends page.
    NSError *error = nil;
	NSString *salesAction = @"https://reportingitc.apple.com";
    NSString *salesRedirectPage = [NSString stringWithContentsOfURL:[NSURL URLWithString:salesAction]
                                                       usedEncoding:NULL error:&error];
    if (error) {
        NSLog(@"unexpected error: %@", salesRedirectPage);
        [self performSelectorOnMainThread:@selector(downloadFailed:) withObject:@"could not load iTunes Connect sales/trend page" waitUntilDone:NO];
        [pool release];
        return;
    }
	
	scanner = [NSScanner scannerWithString:salesRedirectPage];
	NSString *viewState = parseViewState(salesRedirectPage);
	[scanner scanUpToString:@"script id=\"defaultVendorPage:" intoString:nil];
	if (! [scanner scanString:@"script id=\"defaultVendorPage:" intoString:nil]) {
		[self performSelectorOnMainThread:@selector(downloadFailed:) withObject:@"could not parse sales redirect page" waitUntilDone:NO];
		[pool release];
		return;
	}
	NSString *defaultVendorPage = nil;
	[scanner scanUpToString:@"\"" intoString:&defaultVendorPage];
	
	// click though from the dashboard to the sales page
    NSDictionary *reportPostData = [NSDictionary dictionaryWithObjectsAndKeys:
									[defaultVendorPage stringByReplacingOccurrencesOfString:@"_2" withString:@"_0"], @"AJAXREQUEST",
									viewState, @"javax.faces.ViewState",
									defaultVendorPage, @"defaultVendorPage",
									[@"defaultVendorPage:" stringByAppendingString:defaultVendorPage],[@"defaultVendorPage:" stringByAppendingString:defaultVendorPage],
									nil];
    getPostRequestAsData(ITTS_VENDOR_DEFAULT_URL, reportPostData, nil);
	
    // get the form field names needed to download the report
    NSString *salesPage = [NSString stringWithContentsOfURL:[NSURL URLWithString:ITTS_SALES_PAGE_URL] usedEncoding:NULL error:NULL];
    if (salesPage.length == 0) {
        NSLog(@"cannot load sales page: %@", salesPage);
        [self performSelectorOnMainThread:@selector(downloadFailed:) withObject:@"could not load sales/trends page" waitUntilDone:NO];
        [pool release];
        return;
    }
	
    
    viewState = parseViewState(salesPage);    
    NSString *dailyName = [salesPage stringByMatching:@"theForm:j_id_jsp_[0-9]*_6"];
    NSString *weeklyName = [dailyName stringByReplacingOccurrencesOfString:@"_6" withString:@"_22"];
    NSString *ajaxName = [dailyName stringByReplacingOccurrencesOfString:@"_6" withString:@"_2"];
    NSString *daySelectName = [dailyName stringByReplacingOccurrencesOfString:@"_6" withString:@"_43"];
    NSString *weekSelectName = [dailyName stringByReplacingOccurrencesOfString:@"_6" withString:@"_48"];
    
    // parse days available
    NSMutableArray *availableDays = extractFormOptions(salesPage, @"theForm:datePickerSourceSelectElement");
    if (availableDays == nil) {
        NSLog(@"cannot find selection form: %@", salesPage);
        [self performSelectorOnMainThread:@selector(downloadFailed:) withObject:@"unexpected date selector html form" waitUntilDone:NO];
        [pool release];
        return;
    }
    NSString *arbitraryDay = [availableDays objectAtIndex:0];
    [availableDays removeObjectsInArray:daysToSkip];
    [availableDays sortUsingSelector:@selector(compare:)]; // download older reports first
    
    // parse weeks available
    NSMutableArray *availableWeeks = extractFormOptions(salesPage, @"theForm:weekPickerSourceSelectElement");
    if (availableWeeks == nil) {
        NSLog(@"cannot find selection form: %@", salesPage);
        [self performSelectorOnMainThread:@selector(downloadFailed:) withObject:@"unexpected week selector html form" waitUntilDone:NO];
        [pool release];
        return;
    }
    NSString *arbitraryWeek = [availableWeeks objectAtIndex:0];
    [availableWeeks removeObjectsInArray:weeksToSkip];
    [availableWeeks sortUsingSelector:@selector(compare:)];
	
    
    // click though from the dashboard to the sales page
    NSDictionary *postDict = [NSDictionary dictionaryWithObjectsAndKeys:
                              ajaxName, @"AJAXREQUEST",
                              @"theForm", @"theForm",
                              @"notnormal", @"theForm:xyz",
                              @"Y", @"theForm:vendorType",
                              viewState, @"javax.faces.ViewState",
                              dailyName, dailyName,
                              nil];
    NSString *responseString = getPostRequestAsString(ITTS_SALES_PAGE_URL, postDict);
    viewState = parseViewState(responseString);
    
    // download daily reports
    int count = 1;
    for (NSString *dayString in availableDays) {
        NSString *progressMessage = [NSString stringWithFormat:NSLocalizedString(@"Downloading day %d of %d",nil), count, availableDays.count];
        count++;
        [self performSelectorOnMainThread:@selector(setProgress:) withObject:progressMessage waitUntilDone:NO];
        BOOL error = false;
        Day *day = downloadReport(originalReportsPath, ajaxName, dayString, arbitraryWeek, daySelectName, &viewState, &error);
        if (day) {
            [self performSelectorOnMainThread:@selector(successfullyDownloadedReport:) withObject:day waitUntilDone:NO];            
        } else if (error) {
            NSString *message = [@"could not download " stringByAppendingString:dayString];
            [self performSelectorOnMainThread:@selector(downloadFailed:) withObject:message waitUntilDone:NO];
            [pool release];
            return;            
        }
    }
    
    // change to weeks instead of days
    if (false) { // this currently does not appear to be needed
        postDict = [NSDictionary dictionaryWithObjectsAndKeys:
                    ajaxName, @"AJAXREQUEST",
                    @"theForm", @"theForm",
                    @"notnormal", @"theForm:xyz",
                    @"Y", @"theForm:vendorType",
                    viewState, @"javax.faces.ViewState",
                    weeklyName, weeklyName,
                    nil];
        responseString = getPostRequestAsString(ITTS_SALES_PAGE_URL, postDict);
        viewState = parseViewState(responseString);
    }
    
    // download weekly reports
    count = 1;
    for (NSString *weekString in availableWeeks) {
        NSString *progressMessage = [NSString stringWithFormat:NSLocalizedString(@"Downloading week %d of %d",nil), count, availableWeeks.count];
        count++;
        [self performSelectorOnMainThread:@selector(setProgress:) withObject:progressMessage waitUntilDone:NO];
        BOOL error = false;
        Day *week = downloadReport(originalReportsPath, ajaxName, arbitraryDay, weekString, weekSelectName, &viewState, &error);
        if (week) {
            [self performSelectorOnMainThread:@selector(successfullyDownloadedReport:) withObject:week waitUntilDone:NO];   
        } else if (error) {
            NSString *message = [@"could not download " stringByAppendingString:weekString];
            [self performSelectorOnMainThread:@selector(downloadFailed:) withObject:message waitUntilDone:NO];
            [pool release];
            return;
        }
    }
	
	if (availableDays.count == 0 && availableWeeks.count == 0) {
		[self performSelectorOnMainThread:@selector(setProgress:) withObject:NSLocalizedString(@"No new reports found",nil) waitUntilDone:NO];
	} else {
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
    NSAssert([NSThread isMainThread], nil);
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


- (void) successfullyDownloadedReport:(Day*)report {
    if (report.isWeek) {
        [weeks setObject:report forKey:report.date];
        [[NSNotificationCenter defaultCenter] postNotificationName:ReportManagerDownloadedWeeklyReportsNotification object:self];        
    } else {
        [days setObject:report forKey:report.date];
        AppManager *manager = [AppManager sharedManager];
        for (Country *c in [report.countries allValues]) {
            for (Entry *e in c.entries) {
				if (e.transactionType == 2 || e.transactionType == 9) {
                    //skips IAPs in app manager, so IAPs don't duplicate reviews
                    [manager removeAppWithID:e.productIdentifier];
                    continue;
                } 
                [manager createOrUpdateAppIfNeededWithID:e.productIdentifier name:e.productName];
            }
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:ReportManagerDownloadedDailyReportsNotification object:self];
    }
}


- (void)importReport:(Day *)report
{
	AppManager *manager = [AppManager sharedManager];
	for (Country *c in [report.countries allValues]) {
		for (Entry *e in c.entries) {
            if (e.transactionType == 2 || e.transactionType == 9) {
                //skips IAPs in app manager, so IAPs don't duplicate reviews
                [manager removeAppWithID:e.productIdentifier];
                continue;
            } 
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
	[self saveData];
}

- (void)saveData
{
    NSAssert([NSThread isMainThread], nil);
	[[AppManager sharedManager] saveToDisk];
	
	//save all days/weeks in separate files:
	NSString *docPath = getDocPath();
	for (Day *d in [self.days allValues]) {
		NSString *fullPath = [docPath stringByAppendingPathComponent:[d proposedFilename]];
		//wasLoadedFromDisk is set to YES in initWithCoder: ...
		if (!d.wasLoadedFromDisk) {
			[NSKeyedArchiver archiveRootObject:d toFile:fullPath];
		}
	}
	for (Day *w in [self.weeks allValues]) {
		NSString *fullPath = [docPath stringByAppendingPathComponent:[w proposedFilename]];
		//wasLoadedFromDisk is set to YES in initWithCoder: ...
		if (!w.wasLoadedFromDisk) {
			[NSKeyedArchiver archiveRootObject:w toFile:fullPath];
		}
	}
    
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

@end
