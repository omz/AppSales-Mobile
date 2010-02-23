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
#import "ASIFormDataRequest.h"
#import "ReviewManager.h"


static NSString* decompressAsGzipString(NSData *dayData) // could be a method on NSData
{
	NSString *zipFile = [NSTemporaryDirectory() stringByAppendingPathComponent:@"temp.gz"];
	NSString *textFile = [NSTemporaryDirectory() stringByAppendingPathComponent:@"temp.txt"];
	[dayData writeToFile:zipFile atomically:YES];
	gzFile file = gzopen(zipFile.UTF8String, "rb");
	FILE *dest = fopen(textFile.UTF8String, "w");
	unsigned char buffer[262144]; // magic number FIXME: why is this exact size needed?
	int uncompressedLength = gzread(file, buffer, 262144);
	if(fwrite(buffer, 1, uncompressedLength, dest) != uncompressedLength || ferror(dest)) {
		NSLog(@"error writing data");
	}
	fclose(dest);
	gzclose(file);
	
	NSError *error = nil;
	NSString *text = [NSString stringWithContentsOfFile:textFile encoding:NSUTF8StringEncoding error:&error];
	if (error) {
		NSLog(@"%@", error);
	}
	if (! [[NSFileManager defaultManager] removeItemAtPath:zipFile error:&error]) {
		NSLog(@"%@", error);
	}
	if (! [[NSFileManager defaultManager] removeItemAtPath:textFile error:&error]) {
		NSLog(@"%@", error);
	}
	return text;
}

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

- (void) addDay:(Day*)day
{
	if ([days objectForKey:day.name] == nil) {
		[days setObject:day forKey:day.name];
		needsDataSavedToDisk = YES;
	}
	
	// check with review manager since the app name may have recently changed
	ReviewManager *reviewManager = [ReviewManager sharedManager];
	for (Country *c in day.countries.allValues) {
		for (Entry *e in c.entries) {
			[reviewManager createOrUpdateAppIfNeededWithID:e.productIdentifier name:e.productName];
		}
	}
}

- (void) addWeek:(Day*)week
{
	if ([weeks objectForKey:week.name] == nil) {
		[weeks setObject:week forKey:week.name];
		needsDataSavedToDisk = YES;	
	}
}

- (void)saveDataIfNeeded
{
	if (! needsDataSavedToDisk) {
		return; // everythings up to date
	}
	needsDataSavedToDisk = NO;
	
	// save all days/weeks in separate files
	NSString *docPath = getDocPath();
	for (Day *d in days.allValues) {
		[d archiveToDocumentPathIfNeeded:docPath];
	}
	for (Day *w in weeks.allValues) {
		[w archiveToDocumentPathIfNeeded:docPath];
	}
}

- (void)loadSavedFilesFromPath:(NSString*)docPath 
{
	NSFileManager *manager = [NSFileManager defaultManager];
	NSArray *fileNames = [manager contentsOfDirectoryAtPath:docPath error:NULL];
	
	for (NSString *filename in fileNames) {
		NSString *pathExtension = [filename pathExtension];
		Day *loaded = nil;
		if ([pathExtension isEqual:@"txt"] || [pathExtension isEqual:@"csv"]) {
			// load any CVS files manually added	
			loaded = [Day dayFromCSVFile:filename atPath:docPath];
		} else if ([pathExtension isEqual:@"dat"]) {
			// saved from backup data
			loaded = [Day dayFromFile:filename atPath:docPath];
		}
		if (loaded != nil) {
			if (loaded.isWeek) {
				[self addWeek:loaded];
			} else {
				[self addDay:loaded];
			}
		}
	}	
}

#define LOAD_PREFETCH_PREVIOUSLY_RAN @"PrefetchPreviouslyLoaded"
- (void) loadSavedFiles {
	NSAssert(! [NSThread isMainThread], nil);
	
	// files included in bundle.  Only load once since the data is re-saved in documents path
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if (! [defaults boolForKey:LOAD_PREFETCH_PREVIOUSLY_RAN]) {
#if APPSALES_DEBUG
		NSLog(@"loading old data");
#endif
		[self loadSavedFilesFromPath:getPrefetchedPath()];
		[self saveDataIfNeeded];
		[defaults setBool:YES forKey:LOAD_PREFETCH_PREVIOUSLY_RAN];
		[defaults synchronize];
	}
	
	[self loadSavedFilesFromPath:getDocPath()]; // files saved by app
}

- (id)init {
	self = [super init];
	if (self) {	
		days = [[NSMutableDictionary alloc] init];
		weeks = [[NSMutableDictionary alloc] init];
		backupList = [[NSMutableArray alloc] init];
		
		[[CurrencyManager sharedManager] refreshIfNeeded];
	}
	return self;
}

- (void)dealloc
{
	[days release];
	[weeks release];
	[backupList release];
	[reportDownloadStatus release];
	[username release];
	[password release];
	[weeksToSkip release];
	[daysToSkip release];	
	
	[super dealloc];
}

- (void)deleteDay:(Day *)dayToDelete
{
	NSString *fullPath = [getDocPath() stringByAppendingPathComponent:dayToDelete.proposedFilename];
	NSError *error = nil;
	if (! [[NSFileManager defaultManager] removeItemAtPath:fullPath error:&error]) {
		NSLog(@"error encountered: %@", error);
	}
	
	if (dayToDelete.isWeek) {
		[weeks removeObjectForKey:dayToDelete.name];
	} else {
		[days removeObjectForKey:dayToDelete.name];
	}
}

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
	username = [[[NSUserDefaults standardUserDefaults] stringForKey:@"iTunesConnectUsername"] retain];
	password = nil;
	if (username) {
		password = [[SFHFKeychainUtils getPasswordForUsername:username 
											   andServiceName:@"omz:software AppSales Mobile Service" error:&error] retain];
	}
	if (username.length == 0 || password.length == 0) {
		[username release];
		[password release];
		UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Username / Password Missing",nil) 
														 message:NSLocalizedString(@"Please enter a username and a password in the settings.",nil) 
														delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil] autorelease];
		[alert show];
		return;
	}
	
	isRefreshing = YES;
	daysToSkip = [days.allKeys retain];
	weeksToSkip = [[weeks.allValues valueForKey:@"weekEndDateString"] retain];
	
	[self performSelectorInBackground:@selector(fetchReportsWithUserInfo) withObject:nil];
}

- (void)fetchReportsWithUserInfo
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	@try {		
		NSMutableArray *downloadedDays = [NSMutableArray array];
		
		[self performSelectorOnMainThread:@selector(setProgress:) withObject:NSLocalizedString(@"Starting Download...",nil) waitUntilDone:NO];
		
		NSString *ittsBaseURL = @"https://itts.apple.com";
		NSString *ittsLoginPageURL = @"https://itts.apple.com/cgi-bin/WebObjects/Piano.woa";
		NSString *loginPage = [NSString stringWithContentsOfURL:[NSURL URLWithString:ittsLoginPageURL] usedEncoding:NULL error:NULL];
		
		[self performSelectorOnMainThread:@selector(setProgress:) withObject:NSLocalizedString(@"Logging in...",nil) waitUntilDone:NO];
		
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
				[self performSelectorOnMainThread:@selector(downloadFailed:) withObject:nil waitUntilDone:YES];
				return;
			}
			dateTypeSelectionPage = [[[NSString alloc] initWithData:dateTypeSelectionPageData encoding:NSUTF8StringEncoding] autorelease];
		} else {
			dateTypeSelectionPage = loginPage; //already logged in
		}
		
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
					[self performSelectorOnMainThread:@selector(downloadFailed:) withObject:@"could not choose vendor" waitUntilDone:YES];
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
					[self performSelectorOnMainThread:@selector(downloadFailed:) withObject:@"could not choose vendor page 2" waitUntilDone:YES];
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
					[self performSelectorOnMainThread:@selector(downloadFailed:) withObject:@"could not open trend report page" waitUntilDone:YES];
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
			[self performSelectorOnMainThread:@selector(downloadFailed:) withObject:@"could not select date type" waitUntilDone:YES];
			return;
		}
		
		NSString *errorMessageString = nil;
		[scanner setScanLocation:0];
		const BOOL errorMessagePresent = [scanner scanUpToString:@"<font color=\"red\">" intoString:NULL];
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
				downloadActionName = @"17.13.1";
			}
			else {
				downloadType = @"Weekly";
				downloadActionName = @"17.15.1";
			}
			
			NSString *dateTypeSelectionURLString = [ittsBaseURL stringByAppendingString:dateTypeAction]; 
			NSDictionary *dateTypeDict = [NSDictionary dictionaryWithObjectsAndKeys:
										  downloadType, @"17.11", 
										  downloadType, @"hiddenDayOrWeekSelection", 
										  @"Summary", @"17.9", 
										  @"ShowDropDown", @"hiddenSubmitTypeName", nil];
			NSString *encodedDateTypeDict = [dateTypeDict formatForHTTP];
			NSData *httpBody = [encodedDateTypeDict dataUsingEncoding:NSASCIIStringEncoding];
			NSMutableURLRequest *dateTypeRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:dateTypeSelectionURLString]];
			[dateTypeRequest setHTTPMethod:@"POST"];
			[dateTypeRequest setHTTPBody:httpBody];
			NSData *daySelectionPageData = [NSURLConnection sendSynchronousRequest:dateTypeRequest returningResponse:NULL error:NULL];
			
			if (daySelectionPageData == nil) {
				[self performSelectorOnMainThread:@selector(downloadFailed:) withObject:@"could not select day page" waitUntilDone:YES];
				return;
			}
			NSString *daySelectionPage = [[[NSString alloc] initWithData:daySelectionPageData encoding:NSUTF8StringEncoding] autorelease];
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
			
			if (i==0) { //daily
				[availableDays removeObjectsInArray:daysToSkip];			
			} else { //weekly
				[availableDays removeObjectsInArray:weeksToSkip];
			}
			
			const int numberOfDays = availableDays.count;
			if (numberOfDays) {
				scanner = [NSScanner scannerWithString:daySelectionPage];
				NSString *dayDownloadAction = nil;
				[scanner scanUpToString:@"name=\"frmVendorPage\" action=\"" intoString:NULL];
				[scanner scanString:@"name=\"frmVendorPage\" action=\"" intoString:NULL];
				[scanner scanUpToString:@"\"" intoString:&dayDownloadAction];
				if (dayDownloadAction == nil) {
					[self performSelectorOnMainThread:@selector(downloadFailed:) withObject:@"could not find day download action" waitUntilDone:YES];
					return;
				}
				NSString *dayDownloadActionURLString = [ittsBaseURL stringByAppendingString:dayDownloadAction];
				int dayNumber = 1;
				for (NSString *dayString in availableDays) {
					NSDictionary *dayDownloadDict = [NSDictionary dictionaryWithObjectsAndKeys:
													 downloadType, @"17.11", 
													 dayString, @"hiddenDayOrWeekSelection",
													 @"Download", @"hiddenSubmitTypeName",
													 @"ShowDropDown", @"hiddenSubmitTypeName",
													 @"Summary", @"17.9",
													 dayString, downloadActionName,
													 @"Download", @"download", nil];
					NSString *encodedDayDownloadDict = [dayDownloadDict formatForHTTP];
					httpBody = [encodedDayDownloadDict dataUsingEncoding:NSASCIIStringEncoding];
					NSMutableURLRequest *dayDownloadRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:dayDownloadActionURLString]];
					[dayDownloadRequest setHTTPMethod:@"POST"];
					[dayDownloadRequest setHTTPBody:httpBody];
					NSError *error = nil;
					NSData *dayData = [NSURLConnection sendSynchronousRequest:dayDownloadRequest returningResponse:NULL error:&error];
					if (dayData == nil || error) {
						[self performSelectorOnMainThread:@selector(downloadFailed:) withObject:error.description waitUntilDone:YES];
						return;
					}
					
					NSString *csv = decompressAsGzipString(dayData);
					
					// save off the original CSV for the backup function
					// this code for naming 
					NSString *csvFilePath = [getDocPath() stringByAppendingPathComponent:
											 [Day fileNameForString:dayString extension:@"csv" isWeek:(i != 0)]];
					if (! [csv writeToFile:csvFilePath atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
						[self performSelectorOnMainThread:@selector(downloadFailed:) withObject:@"could not save raw CSV file" waitUntilDone:YES];
						return;
					}
					Day *day = [[[Day alloc] initWithCSV:csv] autorelease];
					if (day == nil) {
						[self performSelectorOnMainThread:@selector(downloadFailed:) withObject:@"report data did not parse correctly" waitUntilDone:YES];
						return;
					}
					[downloadedDays addObject:day];
					NSString *status;
					if (i == 0) {
						status = [NSString stringWithFormat:NSLocalizedString(@"Daily Report %i of %i", nil), dayNumber, numberOfDays];
					} else {
						status = [NSString stringWithFormat:NSLocalizedString(@"Weekly Report %i of %i", nil), dayNumber, numberOfDays];
					}
					[self performSelectorOnMainThread:@selector(setProgress:) withObject:status waitUntilDone:NO];
					dayNumber++;
				}
				
				numberOfNewReports += downloadedDays.count;
				// must make a copy, since the main thread will iterate through it while we're still using it.
				// could wait until done, but instead we'll give a copy so this thread can keep working
				NSArray *downloadedDaysCopy = [NSArray arrayWithArray:downloadedDays];
				[downloadedDays removeAllObjects];
				if (i == 0) {
					[self performSelectorOnMainThread:@selector(successfullyDownloadedDays:) withObject:downloadedDaysCopy waitUntilDone:NO];
				} else {
					[self performSelectorOnMainThread:@selector(successfullyDownloadedWeeks:) withObject:downloadedDaysCopy waitUntilDone:NO];
				}
			}
		}
		
		[self performSelectorOnMainThread:@selector(finishDownloadingReports) withObject:nil waitUntilDone:NO]; // all done!
		
		if (numberOfNewReports == 0) {
			[self performSelectorOnMainThread:@selector(setProgress:) withObject:NSLocalizedString(@"No new reports found",nil) waitUntilDone:NO];
		} else { 
			[self performSelectorOnMainThread:@selector(setProgress:) withObject:@"" waitUntilDone:NO];
		}
		if (errorMessageString) {
			[self performSelectorOnMainThread:@selector(presentErrorMessage:) withObject:errorMessageString waitUntilDone:NO];
		}
	} @finally {
		[username release];
		username = nil;
		[password release];
		password = nil;
		[daysToSkip release];
		daysToSkip = nil;
		[weeksToSkip release];
		weeksToSkip = nil;
		[pool release];
	}
}

- (void)finishDownloadingReports {
	[self saveDataIfNeeded];
	isRefreshing = NO;
	[UIApplication sharedApplication].idleTimerDisabled = NO;
}

- (void)setProgress:(NSString *)status
{
	[status retain];
	[reportDownloadStatus release];
	reportDownloadStatus = status;
	[[NSNotificationCenter defaultCenter] postNotificationName:ReportManagerUpdatedDownloadProgressNotification object:self];
}


- (void)downloadFailed:(NSString*)errorMessage
{
	[UIApplication sharedApplication].idleTimerDisabled = NO;
	isRefreshing = NO;
	[self setProgress:@""];
	
	NSString *message = NSLocalizedString(@"Sorry, an error occured when trying to download the report files. Please check your username, password and internet connection.",nil);
	if (errorMessage) {
		message = [message stringByAppendingFormat:@"\n\n%@", errorMessage];
	}
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

- (void)successfullyDownloadedDays:(NSArray*)newDays
{
	for (Day *d in newDays) {
		[self addDay:d];
	}	
	[[NSNotificationCenter defaultCenter] postNotificationName:ReportManagerDownloadedDailyReportsNotification object:self];
}

- (void)successfullyDownloadedWeeks:(NSArray*)newWeeks
{	
	for (Day *week in newWeeks) {
		[self addWeek:week];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ReportManagerDownloadedWeeklyReportsNotification object:self];
}


#pragma mark Backup Reports methods

// TODO?  move this view controller logic into the settings view controller, and leave the FileManager/NSData logic here
- (void) backupRawCSVToEmail:(UIViewController*)viewController {
	NSString *docPath = getDocPath();
	NSFileManager *manager = [NSFileManager defaultManager];
	NSError *error = nil;
	NSArray *dirContents = [manager contentsOfDirectoryAtPath:docPath error:&error];
	if (error) {
		[self presentErrorMessage:[NSString stringWithFormat:@"%@\n%@", NSLocalizedString(@"document error",nil), error]];
		return;
	}
	
	MFMailComposeViewController *picker = [[[[MFMailComposeViewController class] alloc] init] autorelease];
    [picker setSubject:NSLocalizedString(@"AppSales CSV reports", nil)];
    [picker setMailComposeDelegate:self];
	
	int numAttachments = 0;
	
	for (NSString *fileName in dirContents) {
		if ([[fileName pathExtension] isEqualToString:@"csv"]) {
			NSError *error = nil;
			NSString *csvString = [NSString stringWithContentsOfFile:[docPath stringByAppendingPathComponent:fileName] 
															encoding:NSUTF8StringEncoding error:&error];
			if (error) {
				[self presentErrorMessage:error.description];
				return;
			}
			[picker addAttachmentData:[csvString dataUsingEncoding:NSUTF8StringEncoding] 
							 mimeType:@"text/csv" fileName:fileName.lastPathComponent];
			numAttachments++;
		}
	}
	if (numAttachments == 0) {
		// no reports have been downloaded yet, or all reports were previously imported as CSV/DAT files
		[self presentErrorMessage:@"could not find any previously downloaded CSV files"];
		return;
	}
	[viewController presentModalViewController:picker animated:YES];
}

- (void)mailComposeController:(MFMailComposeViewController*)controller 
		  didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
	[controller.parentViewController dismissModalViewControllerAnimated:YES];
	
	if (result == MFMailComposeResultFailed) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"Mail send error", nil)
														message: error.localizedDescription
													   delegate: self
											  cancelButtonTitle: NSLocalizedString(@"OK", nil)
											  otherButtonTitles: nil];
		[alert show];
		[alert release];		
	}
}


- (void)startUpload
{
	NSURL *url;
#ifdef BACKUP_HOSTNAME
	url = [NSURL URLWithString:BACKUP_HOSTNAME];
#else
	NSAssert(false, @"please set BACKUP_HOSTNAME before using");
#endif
	if (backupList.count > 0) {
		Day *d = [backupList objectAtIndex:0];
		
		NSString *fullPath = [getDocPath() stringByAppendingPathComponent:d.proposedFilename];
		ASIFormDataRequest *request = [[[ASIFormDataRequest alloc] initWithURL:url] autorelease];
		[request setPostValue:d.proposedFilename forKey:@"filename"];
		if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath])
			[request setFile:fullPath forKey:@"report"];
		[request setDelegate:self];
		[request startAsynchronous];
	} else if (backupReviewsFile) {
		backupReviewsFile = NO;
		NSString *fullPath = [getDocPath() stringByAppendingPathComponent:@"ReviewApps.rev"];
		ASIFormDataRequest *request = [[[ASIFormDataRequest alloc] initWithURL:url] autorelease];
		[request setPostValue:@"ReviewApps.rev" forKey:@"filename"];
		if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath])
			[request setFile:fullPath forKey:@"report"];
		[request setDelegate:self];
		[request startAsynchronous];
	}
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
	if (backupList.count > 0)
		[backupList removeObjectAtIndex:0];
	if (backupReviewsFile) {
		[self setProgress:[NSString stringWithFormat:@"Left to upload: %d", backupList.count+1]];
		retryIfBackupFailure = 5;
		[self startUpload];
	} else {
		[self setProgress:[NSString stringWithFormat:@"Done backup"]];
	}
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
	//NSError *error = [request error];
	if (retryIfBackupFailure) {
		[self setProgress:[NSString stringWithFormat:@"Failed, retries"]];
		retryIfBackupFailure--;
		backupReviewsFile = YES;
		[self startUpload];
	} else {
		[backupList removeAllObjects];
		backupReviewsFile = NO;
		[self setProgress:[NSString stringWithFormat:@"Failed, gave up"]];
	}
}

- (void)backupData
{
	[backupList removeAllObjects];
	[backupList addObjectsFromArray:self.days.allValues];
	[backupList addObjectsFromArray:self.weeks.allValues];
	retryIfBackupFailure = 5;
	backupReviewsFile = YES;
	if (backupList.count > 0) {
		[self setProgress:[NSString stringWithFormat:@"Left to upload: %d", backupList.count+1]];
		[self startUpload];	
	}	
}

@end
