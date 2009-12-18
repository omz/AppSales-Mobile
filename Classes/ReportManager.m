//
//  ReportManager.m
//  AppSalesMobile
//
//  Created by Ole Zorn on 10.09.09.
//  Copyright 2009 omz:software. All rights reserved.
//

#import "ReportManager.h"
#import <zlib.h>
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

#error BACKUP_HOSTNAME -- Set macro appropriate for your setup 
#define BACKUP_HOSTNAME \
	@"http://<computer-name>.local/~<username>/upload_appsales.php"


@implementation ReportManager

@synthesize days, weeks, backupList, reportDownloadStatus;

- (id)init
{
	[super init];
	
	self.days = [NSMutableDictionary dictionary];
	self.weeks = [NSMutableDictionary dictionary];
	self.backupList = [NSMutableArray array];

	NSString *docPath = getDocPath();
	NSString *prefetchedPath = getPrefetchedPath();
	
	NSArray *filenames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:docPath error:NULL];

	NSCalendar *calendar = [NSCalendar currentCalendar];
	
	for (NSString *filename in filenames) {
		if (![[filename pathExtension] isEqual:@"dat"])
			continue;
		
		Day *loadedDay = [Day dayFromFile:filename atPath:docPath];
		
		if (loadedDay != nil) {
			if (loadedDay.isWeek)
				[self.weeks setObject:loadedDay forKey:[loadedDay name]];
			else
			{
				if (loadedDay.date)
				{
					NSDateComponents *components = [calendar components:(NSWeekdayCalendarUnit | NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit) fromDate:loadedDay.date];
					NSDate *loadedDate = [calendar dateFromComponents:components];
					NSDateFormatter * lFormat = [NSDateFormatter new];
					[lFormat setDateFormat:@"MM/dd/yyyy"];
					NSDate *lDate = [lFormat dateFromString:[loadedDay name]];
					[lFormat release];
					if ([lDate isEqual:loadedDate])
						[self.days setObject:loadedDay forKey:[loadedDay name]];
				}
			}
		}
	}

	filenames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:prefetchedPath error:NULL];

	for (NSString *filename in filenames) {
		if (![[filename pathExtension] isEqual:@"dat"])
			continue;
		
		Day *loadedDay = [Day dayFromFile:filename atPath:prefetchedPath];
		
		if (loadedDay != nil) {
			if (loadedDay.isWeek)
				[self.weeks setObject:loadedDay forKey:[loadedDay name]];
			else
			{
				if (loadedDay.date)
				{
					NSDateFormatter * lFormat = [NSDateFormatter new];
					[lFormat setDateFormat:@"MM/dd/yyyy"];
					NSDate *lDate = [lFormat dateFromString:[loadedDay name]];
					[lFormat release];
					if ([lDate isEqual:loadedDay.date])
						[self.days setObject:loadedDay forKey:[loadedDay name]];
				}
			}
		}
	}
	
	[[CurrencyManager sharedManager] refreshIfNeeded];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveData) name:UIApplicationWillTerminateNotification object:nil];
	
	return self;
}

+ (ReportManager *)sharedManager
{
	static ReportManager *sharedManager = nil;
	if (sharedManager == nil) {
		sharedManager = [ReportManager new];
	}
	return sharedManager;
}

- (void)deleteDay:(Day *)dayToDelete
{
	NSString *fullPath = [getDocPath() stringByAppendingPathComponent:[dayToDelete proposedFilename]];
	[[NSFileManager defaultManager] removeItemAtPath:fullPath error:NULL];
	if (dayToDelete.isWeek) {
		[self.weeks removeObjectForKey:dayToDelete.name];
	}
	else {
		[self.days removeObjectForKey:dayToDelete.name];
	}
}

- (BOOL)isDownloadingReports
{
	return isRefreshing;
}

- (void)downloadReports
{
	if (isRefreshing)
		return;
	
	[UIApplication sharedApplication].idleTimerDisabled = YES;
	
	NSError *error = nil;
	NSString *username = [[NSUserDefaults standardUserDefaults] stringForKey:@"iTunesConnectUsername"];
	NSString *password = nil;
	if (username) {
		password = [SFHFKeychainUtils getPasswordForUsername:username andServiceName:@"omz:software AppSales Mobile Service" error:&error];
	}
	if (!username || !password || [username isEqual:@""] || [password isEqual:@""]) {
		UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Username / Password Missing",nil) message:NSLocalizedString(@"Please enter a username and a password in the settings.",nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil] autorelease];
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
							  daysToSkip, @"daysToSkip", nil];
	[self performSelectorInBackground:@selector(fetchReportsWithUserInfo:) withObject:userInfo];
}

- (void)fetchReportsWithUserInfo:(NSDictionary *)userInfo
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	NSMutableDictionary *downloadedDays = [NSMutableDictionary dictionary];
	
	[self performSelectorOnMainThread:@selector(setProgress:) withObject:NSLocalizedString(@"Starting Download...",nil) waitUntilDone:YES];
	
	NSString *username = [userInfo objectForKey:@"username"];
	NSString *password = [userInfo objectForKey:@"password"];
	
	NSString *ittsBaseURL = @"https://itts.apple.com";
	NSString *ittsLoginPageURL = @"https://itts.apple.com/cgi-bin/WebObjects/Piano.woa";
	NSString *loginPage = [NSString stringWithContentsOfURL:[NSURL URLWithString:ittsLoginPageURL] usedEncoding:NULL error:NULL];
	
	[self performSelectorOnMainThread:@selector(setProgress:) withObject:NSLocalizedString(@"Logging in...",nil) waitUntilDone:YES];
	
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
			NSLog(@"Error: could not login");
			[pool release];
			[self performSelectorOnMainThread:@selector(downloadFailed) withObject:nil waitUntilDone:YES];
			return;
		}
		dateTypeSelectionPage = [[[NSString alloc] initWithData:dateTypeSelectionPageData encoding:NSUTF8StringEncoding] autorelease];
	}
	else
		dateTypeSelectionPage = loginPage; //already logged in
	
	[self performSelectorOnMainThread:@selector(setProgress:) withObject:NSLocalizedString(@"Downloading Daily Reports...",nil) waitUntilDone:YES];
	
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
	
	//NSLog(@"%@", dateTypeSelectionPage);
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
			downloadActionName = @"11.13.1";
		}
		else {
			downloadType = @"Weekly";
			downloadActionName = @"11.15.1";
		}
		
		NSString *dateTypeSelectionURLString = [ittsBaseURL stringByAppendingString:dateTypeAction]; 
		NSDictionary *dateTypeDict = [NSDictionary dictionaryWithObjectsAndKeys:
									  downloadType, @"11.11", 
									  downloadType, @"hiddenDayOrWeekSelection", 
									  @"Summary", @"11.9", 
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
			NSArray *daysToSkip = [userInfo objectForKey:@"daysToSkip"];
			[availableDays removeObjectsInArray:daysToSkip];			
		}
		else { //weekly
			NSArray *weeksToSkip = [userInfo objectForKey:@"weeksToSkip"];
			[availableDays removeObjectsInArray:weeksToSkip];
		}
		int numberOfDays = [availableDays count];
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
		int dayNumber = 1;
		for (NSString *dayString in availableDays) {
			NSDictionary *dayDownloadDict = [NSDictionary dictionaryWithObjectsAndKeys:
											 downloadType, @"11.11", 
											 dayString, @"hiddenDayOrWeekSelection",
											 @"Download", @"hiddenSubmitTypeName",
											 @"ShowDropDown", @"hiddenSubmitTypeName",
											 @"Summary", @"11.9",
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
			
			Day *day = [self dayWithData:dayData compressed:YES];
			if (day != nil) {
				if (i != 0)
					day.isWeek = YES;
				[downloadedDays setObject:day forKey:dayString];
				day.name = dayString;
			}
			NSString *status = @"";
			if (i != 0) {
				status = [NSString stringWithFormat:NSLocalizedString(@"Weekly Report %i of %i", nil), dayNumber, numberOfDays];
			}
			else {
				status = [NSString stringWithFormat:NSLocalizedString(@"Daily Report %i of %i", nil), dayNumber, numberOfDays];
			}
			[self performSelectorOnMainThread:@selector(setProgress:) withObject:status waitUntilDone:YES];
			dayNumber++;
		}
		numberOfNewReports += [downloadedDays count];
		if (i == 0) {
			[self performSelectorOnMainThread:@selector(successfullyDownloadedDays:) withObject:downloadedDays waitUntilDone:YES];
			[downloadedDays removeAllObjects];
		}
		else
			[self performSelectorOnMainThread:@selector(successfullyDownloadedWeeks:) withObject:downloadedDays waitUntilDone:YES];
	}
	if (numberOfNewReports == 0)
		[self performSelectorOnMainThread:@selector(setProgress:) withObject:NSLocalizedString(@"No new reports found",nil) waitUntilDone:YES];
	else
		[self performSelectorOnMainThread:@selector(setProgress:) withObject:@"" waitUntilDone:YES];
	
	if (errorMessageString) {
		[self performSelectorOnMainThread:@selector(presentErrorMessage:) withObject:errorMessageString waitUntilDone:YES];
	}
	[pool release];
}

- (void)downloadFailed
{
	[UIApplication sharedApplication].idleTimerDisabled = NO;
	
	isRefreshing = NO;
	[self setProgress:@""];
	UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Download Failed",nil) message:NSLocalizedString(@"Sorry, an error occured when trying to download the report files. Please check your username, password and internet connection.",nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil] autorelease];
	[alert show];
}

- (void)presentErrorMessage:(NSString *)message
{
	UIAlertView *errorAlert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Note",nil) message:message delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil] autorelease];
	[errorAlert show];
}

- (void)successfullyDownloadedDays:(NSDictionary *)newDays
{
	[days addEntriesFromDictionary:newDays];
	[[NSNotificationCenter defaultCenter] postNotificationName:ReportManagerUpdatedDownloadProgressNotification object:self];
	
	ReviewManager *reviewManager = [ReviewManager sharedManager];
	for (Day *d in [newDays allValues]) {
		for (Country *c in [d.countries allValues]) {
			for (Entry *e in c.entries) {
				NSString *appID = e.productIdentifier;
				NSString *appName = e.productName;
				if ([reviewManager appWithID:appID] == nil) {
					App *app = [[[App alloc] initWithID:appID name:appName] autorelease];
					[reviewManager addApp:app];
				}
			}
		}
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ReportManagerDownloadedDailyReportsNotification object:self];
}

- (void)successfullyDownloadedWeeks:(NSDictionary *)newDays
{
	[UIApplication sharedApplication].idleTimerDisabled = NO;
	
	isRefreshing = NO;
	[weeks addEntriesFromDictionary:newDays];
	[[NSNotificationCenter defaultCenter] postNotificationName:ReportManagerUpdatedDownloadProgressNotification object:self];
	[[NSNotificationCenter defaultCenter] postNotificationName:ReportManagerDownloadedWeeklyReportsNotification object:self];
}

- (void)setProgress:(NSString *)status
{
	self.reportDownloadStatus = status;
	[[NSNotificationCenter defaultCenter] postNotificationName:ReportManagerUpdatedDownloadProgressNotification object:self];
}

- (Day *)dayWithData:(NSData *)dayData compressed:(BOOL)compressed
{
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

- (void)saveData
{
	//save all days/weeks in separate files:
	for (Day *d in [self.days allValues]) {
		NSString *fullPath = [getDocPath() stringByAppendingPathComponent:[d proposedFilename]];
		//wasLoadedFromDisk is set to YES in initWithCoder: ...
		if (!d.wasLoadedFromDisk) {
			[NSKeyedArchiver archiveRootObject:d toFile:fullPath];
		}
	}
	for (Day *w in [self.weeks allValues]) {
		NSString *fullPath = [getDocPath() stringByAppendingPathComponent:[w proposedFilename]];
		//wasLoadedFromDisk is set to YES in initWithCoder: ...
		if (!w.wasLoadedFromDisk) {
			[NSKeyedArchiver archiveRootObject:w toFile:fullPath];
		}
	}
}

#pragma mark Backup Reports methods

- (void)startUpload
{
	if ([backupList count] > 0) {
		Day *d = [backupList objectAtIndex:0];
		NSURL *url = [NSURL URLWithString:BACKUP_HOSTNAME];
		NSString *fullPath = [getDocPath() stringByAppendingPathComponent:[d proposedFilename]];
		ASIFormDataRequest *request = [[[ASIFormDataRequest alloc] initWithURL:url] autorelease];
		[request setPostValue:[d proposedFilename] forKey:@"filename"];
		if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath])
			[request setFile:fullPath forKey:@"report"];
		[request setDelegate:self];
		[request startAsynchronous];
	} else if (backupReviewsFile) {
		backupReviewsFile = NO;
		NSURL *url = [NSURL URLWithString:BACKUP_HOSTNAME];
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
	if ([backupList count] > 0)
		[backupList removeObjectAtIndex:0];
	if ([backupList count] > 0 || backupReviewsFile) {
		[self setProgress:[NSString stringWithFormat:@"Left to upload: %d", [backupList count]+1]];
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
	[backupList addObjectsFromArray:[self.days allValues]];
	[backupList addObjectsFromArray:[self.weeks allValues]];
	retryIfBackupFailure = 5;
	backupReviewsFile = YES;
	if ([backupList count] > 0) {
		[self setProgress:[NSString stringWithFormat:@"Left to upload: %d", [backupList count]+1]];
		[self startUpload];	
	}	
}

@end
