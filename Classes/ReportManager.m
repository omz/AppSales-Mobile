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

@implementation ReportManager

@synthesize days, weeks, appsByID, reviewDownloadStatus, reportDownloadStatus;

- (id)init
{
	[super init];
	
	self.days = [NSMutableDictionary dictionary];
	self.weeks = [NSMutableDictionary dictionary];

	NSString *docPath = [self docPath];
	
	NSString *reviewsFile = [docPath stringByAppendingPathComponent:@"ReviewApps.rev"];
	if ([[NSFileManager defaultManager] fileExistsAtPath:reviewsFile]) {
		self.appsByID = [NSKeyedUnarchiver unarchiveObjectWithFile:reviewsFile];
	}
	else {
		self.appsByID = [NSMutableDictionary dictionary];
	}
	
	NSArray *filenames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:docPath error:NULL];
	
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
	NSString *fullPath = [[self docPath] stringByAppendingPathComponent:[dayToDelete proposedFilename]];
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
		if (i == 0) {
			[self performSelectorOnMainThread:@selector(successfullyDownloadedDays:) withObject:downloadedDays waitUntilDone:YES];
			[downloadedDays removeAllObjects];
		}
		else
			[self performSelectorOnMainThread:@selector(successfullyDownloadedWeeks:) withObject:downloadedDays waitUntilDone:YES];
	}
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
		
	for (Day *d in [newDays allValues]) {
		for (Country *c in [d.countries allValues]) {
			for (Entry *e in c.entries) {
				NSString *appID = e.productIdentifier;
				NSString *appName = e.productName;
				if (![self.appsByID objectForKey:appID]) {
					App *app = [[App new] autorelease];
					app.appID = appID;
					app.appName = appName;
					app.reviewsByUser = [NSMutableDictionary dictionary];
					[appsByID setObject:app forKey:appID];
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

- (NSString *)docPath
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	return documentsDirectory;
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
	
	NSString *reviewsFile = [[self docPath] stringByAppendingPathComponent:@"ReviewApps.rev"];
	[NSKeyedArchiver archiveRootObject:self.appsByID toFile:reviewsFile];
}

- (void)downloadReviewsForTopCountriesOnly:(BOOL)topCountriesOnly
{
	if (isDownloadingReviews)
		return;
	
	[UIApplication sharedApplication].idleTimerDisabled = YES;
	
	isDownloadingReviews = YES;
	[self updateReviewDownloadProgress:NSLocalizedString(@"Downloading reviews...",nil)];
	
	NSMutableDictionary *appIDs = [NSMutableDictionary dictionary];
	for (NSString *appID in [self.appsByID allKeys]) {
		App *a = [appsByID objectForKey:appID];
		[appIDs setObject:a.appName forKey:appID];
	}
	NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:appIDs, @"appIDs", [NSNumber numberWithBool:topCountriesOnly], @"downloadOnlyTopCountries", nil];
	[self performSelectorInBackground:@selector(fetchReviewsWithInfo:) withObject:info];
}

- (BOOL)isDownloadingReviews
{
	return isDownloadingReviews;
}

- (void)updateReviewDownloadProgress:(NSString *)status
{
	self.reviewDownloadStatus = status;
	[[NSNotificationCenter defaultCenter] postNotificationName:ReportManagerUpdatedReviewDownloadProgressNotification object:self];
}

- (void)fetchReviewsWithInfo:(NSDictionary *)info
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	NSDictionary *appIDs = [info objectForKey:@"appIDs"];
	BOOL downloadOnlyTopCountries = [[info objectForKey:@"downloadOnlyTopCountries"] boolValue];
	
	NSMutableDictionary *reviewsByAppID = [NSMutableDictionary dictionary];
	for (NSString *appID in appIDs) {
		[reviewsByAppID setObject:[NSMutableArray array] forKey:appID];
	}
	
	//setup store fronts, this should probably go into a plist...:
	NSDateFormatter *frenchDateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	NSLocale *frenchLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"fr"] autorelease];
	[frenchDateFormatter setLocale:frenchLocale];
	[frenchDateFormatter setDateFormat:@"dd MMM yyyy"];
	NSDateFormatter *germanDateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[germanDateFormatter setDateFormat:@"dd.MM.yyyy"];
	NSDateFormatter *usDateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	NSLocale *usLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en-us"] autorelease];
	[usDateFormatter setLocale:usLocale];
	[usDateFormatter setDateFormat:@"MMM dd, yyyy"];
	NSDateFormatter *defaultDateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[defaultDateFormatter setDateFormat:@"dd-MMM-yyyy"];
	NSLocale *defaultLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en-us"] autorelease];
	NSMutableArray *storeInfos = [NSMutableArray array];
	do {
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Australia", @"countryName", 
							   @"au", @"countryCode",
							   @"143460", @"storeFrontID", 
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Canada", @"countryName", 
							   @"ca", @"countryCode",
							   @"143455", @"storeFrontID", 
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"United States", @"countryName", 
							   @"us", @"countryCode",
							   @"143441", @"storeFrontID",
							   usDateFormatter, @"dateFormatter",
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Germany", @"countryName", 
							   @"de", @"countryCode",
							   @"143443", @"storeFrontID",
							   germanDateFormatter, @"dateFormatter",
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Spain", @"countryName", 
							   @"es", @"countryCode",
							   @"143454", @"storeFrontID", 
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"France", @"countryName", 
							   @"fr", @"countryCode",
							   @"143442", @"storeFrontID", 
							   frenchDateFormatter, @"dateFormatter",
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Italy", @"countryName", 
							   @"it", @"countryCode",
							   @"143450", @"storeFrontID", 
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Netherlands", @"countryName", 
							   @"nl", @"countryCode",
							   @"143452", @"storeFrontID", 
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"United Kingdom", @"countryName", 
							   @"gb", @"countryCode",
							   @"143444", @"storeFrontID", 
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Japan", @"countryName", 
							   @"jp", @"countryCode",
							   @"143462", @"storeFrontID", 
							   nil]];
	
		if (downloadOnlyTopCountries)
			break;
		
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Argentina", @"countryName", 
							   @"ar", @"countryCode",
							   @"143505", @"storeFrontID", 
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Belgium", @"countryName", 
							   @"be", @"countryCode",
							   @"143446", @"storeFrontID", 
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Brazil", @"countryName", 
							   @"br", @"countryCode",
							   @"143503", @"storeFrontID", 
							   nil]];
		
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Chile", @"countryName", 
							   @"cl", @"countryCode",
							   @"143483", @"storeFrontID", 
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"China", @"countryName", 
							   @"cn", @"countryCode",
							   @"143465", @"storeFrontID", 
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Colombia", @"countryName", 
							   @"co", @"countryCode",
							   @"143501", @"storeFrontID", 
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Costa Rica", @"countryName", 
							   @"cr", @"countryCode",
							   @"143495", @"storeFrontID", 
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Czech Republic", @"countryName", 
							   @"cz", @"countryCode",
							   @"143489", @"storeFrontID", 
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Denmark", @"countryName", 
							   @"dk", @"countryCode",
							   @"143458", @"storeFrontID", 
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"El Salvador", @"countryName", 
							   @"sv", @"countryCode",
							   @"143506", @"storeFrontID", 
							   nil]];
		
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Finland", @"countryName", 
							   @"fi", @"countryCode",
							   @"143447", @"storeFrontID", 
							   nil]];
		
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Greece", @"countryName", 
							   @"gr", @"countryCode",
							   @"143448", @"storeFrontID", 
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Guatemala", @"countryName", 
							   @"gt", @"countryCode",
							   @"143504", @"storeFrontID", 
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Hong Kong", @"countryName", 
							   @"hk", @"countryCode",
							   @"143463", @"storeFrontID", 
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Hungary", @"countryName", 
							   @"hu", @"countryCode",
							   @"143482", @"storeFrontID", 
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"India", @"countryName", 
							   @"in", @"countryCode",
							   @"143467", @"storeFrontID", 
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Indonesia", @"countryName", 
							   @"id", @"countryCode",
							   @"143476", @"storeFrontID", 
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Ireland", @"countryName", 
							   @"ie", @"countryCode",
							   @"143449", @"storeFrontID", 
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Israel", @"countryName", 
							   @"il", @"countryCode",
							   @"143491", @"storeFrontID", 
							   nil]];
		
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Korea", @"countryName", 
							   @"kr", @"countryCode",
							   @"143466", @"storeFrontID", 
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Kuwait", @"countryName", 
							   @"kw", @"countryCode",
							   @"143493", @"storeFrontID", 
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Lebanon", @"countryName", 
							   @"lb", @"countryCode",
							   @"143497", @"storeFrontID", 
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Luxemburg", @"countryName", 
							   @"lu", @"countryCode",
							   @"143451", @"storeFrontID", 
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Malaysia", @"countryName", 
							   @"my", @"countryCode",
							   @"143473", @"storeFrontID", 
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Mexico", @"countryName", 
							   @"mx", @"countryCode",
							   @"143468", @"storeFrontID", 
							   nil]];
		
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"New Zealand", @"countryName", 
							   @"nz", @"countryCode",
							   @"143461", @"storeFrontID", 
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Norway", @"countryName", 
							   @"no", @"countryCode",
							   @"143457", @"storeFrontID", 
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Austria", @"countryName", 
							   @"at", @"countryCode",
							   @"143445", @"storeFrontID", 
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Pakistan", @"countryName", 
							   @"pk", @"countryCode",
							   @"143477", @"storeFrontID", 
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Panama", @"countryName", 
							   @"pa", @"countryCode",
							   @"143485", @"storeFrontID", 
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Peru", @"countryName", 
							   @"pe", @"countryCode",
							   @"143507", @"storeFrontID", 
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Phillipines", @"countryName", 
							   @"ph", @"countryCode",
							   @"143474", @"storeFrontID", 
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Poland", @"countryName", 
							   @"pl", @"countryCode",
							   @"143478", @"storeFrontID", 
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Portugal", @"countryName", 
							   @"pt", @"countryCode",
							   @"143453", @"storeFrontID", 
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Qatar", @"countryName", 
							   @"qa", @"countryCode",
							   @"143498", @"storeFrontID", 
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Romania", @"countryName", 
							   @"ro", @"countryCode",
							   @"143487", @"storeFrontID", 
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Russia", @"countryName", 
							   @"ru", @"countryCode",
							   @"143469", @"storeFrontID", 
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Saudi Arabia", @"countryName", 
							   @"sa", @"countryCode",
							   @"143479", @"storeFrontID", 
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Switzerland", @"countryName", 
							   @"ch", @"countryCode",
							   @"143459", @"storeFrontID", 
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Singapore", @"countryName", 
							   @"sg", @"countryCode",
							   @"143464", @"storeFrontID", 
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Slovakia", @"countryName", 
							   @"sk", @"countryCode",
							   @"143496", @"storeFrontID", 
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Slovenia", @"countryName", 
							   @"si", @"countryCode",
							   @"143499", @"storeFrontID", 
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"South Africa", @"countryName", 
							   @"za", @"countryCode",
							   @"143472", @"storeFrontID", 
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Sri Lanka", @"countryName", 
							   @"lk", @"countryCode",
							   @"143486", @"storeFrontID", 
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Sweden", @"countryName", 
							   @"se", @"countryCode",
							   @"143456", @"storeFrontID", 
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Taiwan", @"countryName", 
							   @"tw", @"countryCode",
							   @"143470", @"storeFrontID", 
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Thailand", @"countryName", 
							   @"th", @"countryCode",
							   @"143475", @"storeFrontID", 
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Turkey", @"countryName", 
							   @"tr", @"countryCode",
							   @"143480", @"storeFrontID", 
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"United Arab Emirates", @"countryName", 
							   @"ae", @"countryCode",
							   @"143481", @"storeFrontID", 
							   nil]];
		
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Venezuela", @"countryName", 
							   @"ve", @"countryCode",
							   @"143502", @"storeFrontID", 
							   nil]];
		[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   @"Vietnam", @"countryName", 
							   @"vn", @"countryCode",
							   @"143471", @"storeFrontID", 
							   nil]];
		
	} while (NO);
	
	
	NSTimeInterval t = [[NSDate date] timeIntervalSince1970];
	for (NSString *appID in appIDs) {
		NSString *appName = [appIDs objectForKey:appID];
		for (NSDictionary *storeInfo in storeInfos) {
			NSAutoreleasePool *innerPool = [NSAutoreleasePool new];
			NSString *countryName = [storeInfo objectForKey:@"countryName"];
			NSString *countryCode = [storeInfo objectForKey:@"countryCode"];
			//NSLog(@"Downloading reviews for app %@ in %@", appID, countryName);
			NSString *status = [NSString stringWithFormat:@"%@: %@", appName, countryName];
			[self performSelectorOnMainThread:@selector(updateReviewDownloadProgress:) withObject:status waitUntilDone:YES];
			
			NSDateFormatter *dateFormatter = [storeInfo objectForKey:@"dateFormatter"];
			if (!dateFormatter) {
				dateFormatter = defaultDateFormatter;
				if ([countryCode isEqual:@"it"]) {
					NSLocale *currentLocale = [[[NSLocale alloc] initWithLocaleIdentifier:countryCode] autorelease];
					[dateFormatter setLocale:currentLocale];
				}
				else {
					[dateFormatter setLocale:defaultLocale];
				}
			}
			
			NSString *storeFrontID = [storeInfo objectForKey:@"storeFrontID"];
			NSString *storeFront = [NSString stringWithFormat:@"%@-1", storeFrontID];
			NSString *reviewsURLString = [NSString stringWithFormat:@"http://ax.phobos.apple.com.edgesuite.net/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=%@&pageNumber=0&sortOrdering=4&type=Purple+Software", appID];
			NSURL *reviewsURL = [NSURL URLWithString:reviewsURLString];
			NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:reviewsURL];
			NSMutableDictionary *headers = [NSMutableDictionary dictionary];
			[headers setObject:storeFront forKey:@"X-Apple-Store-Front"];
			[headers setObject:@"iTunes/4.2 (Macintosh; U; PPC Mac OS X 10.2)" forKey:@"User-Agent"];
			[request setAllHTTPHeaderFields:headers];
			
			NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:NULL error:NULL];
			NSString *xml = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
			
			NSScanner *scanner = [NSScanner scannerWithString:xml];
			int i = 0;
			do {
				NSString *reviewTitle = nil;
				NSString *reviewDateAndVersion = nil;
				NSString *reviewUser = nil;
				NSString *reviewText = nil;
				NSString *reviewStars = nil;
				NSString *reviewVersion = nil;
				NSDate *reviewDate = nil;;
				
				[scanner scanUpToString:@"<TextView topInset=\"0\" truncation=\"right\" leftInset=\"0\" squishiness=\"1\" styleSet=\"basic13\" textJust=\"left\" maxLines=\"1\">" intoString:NULL];
				[scanner scanUpToString:@"<b>" intoString:NULL];
				[scanner scanString:@"<b>" intoString:NULL];
				[scanner scanUpToString:@"</b>" intoString:&reviewTitle];
								
				[scanner scanUpToString:@"<HBoxView topInset=\"1\" alt=\"" intoString:NULL];
				[scanner scanString:@"<HBoxView topInset=\"1\" alt=\"" intoString:NULL];
				[scanner scanUpToString:@" " intoString:&reviewStars];
								
				[scanner scanUpToString:@"<b>" intoString:NULL];
				[scanner scanString:@"<b>" intoString:NULL];
				[scanner scanUpToString:@"<b>" intoString:NULL];
				[scanner scanString:@"<b>" intoString:NULL];
				[scanner scanUpToString:@"</b>" intoString:&reviewUser];
				reviewUser = [reviewUser stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
				
				[scanner scanUpToString:@" - " intoString:NULL];
				[scanner scanString:@" - " intoString:NULL];
				[scanner scanUpToString:@"</SetFontStyle>" intoString:&reviewDateAndVersion];
				reviewDateAndVersion = [reviewDateAndVersion stringByReplacingOccurrencesOfString:@"\n" withString:@""];
				NSArray *dateVersionSplitted = [reviewDateAndVersion componentsSeparatedByString:@"- "];
				if ([dateVersionSplitted count] == 3) {
					NSString *version = [dateVersionSplitted objectAtIndex:1];
					reviewVersion = [version stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
					NSString *date = [dateVersionSplitted objectAtIndex:2];
					date = [date stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
					reviewDate = [dateFormatter dateFromString:date];
				}
								
				[scanner scanUpToString:@"<SetFontStyle normalStyle=\"textColor\">" intoString:NULL];
				[scanner scanString:@"<SetFontStyle normalStyle=\"textColor\">" intoString:NULL];
				[scanner scanUpToString:@"</SetFontStyle>" intoString:&reviewText];
				
				if (reviewUser && reviewTitle && reviewText && reviewStars) {
					Review *review = [[Review new] autorelease];
					review.downloadDate = [NSDate dateWithTimeIntervalSince1970:t - i];
					review.reviewDate = reviewDate;
					review.user = reviewUser;
					review.title = reviewTitle;
					review.stars = [reviewStars intValue];
					review.text = reviewText;
					review.version = reviewVersion;
					review.countryCode = countryCode;
					[[reviewsByAppID objectForKey:appID] addObject:review];
				}
				i++;
			} while (![scanner isAtEnd]);
			[innerPool release];
		}
	}
	[self performSelectorOnMainThread:@selector(finishDownloadingReviews:) withObject:reviewsByAppID waitUntilDone:YES];
	
	[pool release];
}

- (void)finishDownloadingReviews:(NSDictionary *)reviews
{
	[UIApplication sharedApplication].idleTimerDisabled = NO;
	
	//NSLog(@"%@", reviews);
	isDownloadingReviews = NO;
	for (NSString *appID in [reviews allKeys]) {
		App *app = [appsByID objectForKey:appID];
		NSArray *allReviewsForApp = [reviews objectForKey:appID];
		int oldNumberOfReviews = [app.reviewsByUser count];
		for (Review *review in allReviewsForApp) {
			Review *oldReview = [app.reviewsByUser objectForKey:review.user];
			if ((oldReview == nil) || (![oldReview.text isEqual:review.text])) {
				[app.reviewsByUser setObject:review forKey:review.user];
			}
		}
		app.newReviewsCount = [app.reviewsByUser count] - oldNumberOfReviews;
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ReportManagerDownloadedReviewsNotification object:self];
	[self updateReviewDownloadProgress:@""];
}

@end
