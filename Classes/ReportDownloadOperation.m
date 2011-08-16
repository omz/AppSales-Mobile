//
//  ReportDownloadOperation.m
//  AppSales
//
//  Created by Ole Zorn on 01.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "ReportDownloadOperation.h"
#import "ASAccount.h"
#import "Report.h"
#import "RegexKitLite.h"
#import "NSData+Compression.h"
#import "NSDictionary+HTTP.h"
#import "JSONKit.h"

@interface ReportDownloadOperation ()

- (NSData *)dataFromSynchronousPostRequestWithURL:(NSURL *)URL bodyDictionary:(NSDictionary *)bodyDictionary response:(NSHTTPURLResponse **)response;
- (NSString *)stringFromSynchronousPostRequestWithURL:(NSURL *)URL bodyDictionary:(NSDictionary *)bodyDictionary;
- (NSArray *)extractFormOptionsFromPage:(NSString *)htmlPage formID:(NSString *)formID;
- (NSData *)downloadReportFromiTCWithInfo:(NSDictionary *)downloadInfo viewState:(NSString **)viewState originalFilename:(NSString **)filename;
- (NSDate *)dateFromPopupMenuItemName:(NSString *)menuItemName;
- (void)parsePaymentsPage:(NSString *)paymentsPage inAccount:(ASAccount *)account vendorID:(NSString *)vendorID;

@end


@implementation ReportDownloadOperation

@synthesize downloadCount, accountObjectID;

- (id)initWithAccount:(ASAccount *)account
{
    self = [super init];
    if (self) {
		username = [[account username] copy];
		password = [[account password] copy];
		_account = [account retain];
		accountObjectID = [[account objectID] copy];
		psc = [[[account managedObjectContext] persistentStoreCoordinator] retain];
    }
    return self;
}

- (void)main
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	dispatch_async(dispatch_get_main_queue(), ^ {
		_account.downloadStatus = NSLocalizedString(@"Starting download", nil);
		_account.downloadProgress = 0.0;
	});
	
	NSManagedObjectContext *moc = [[[NSManagedObjectContext alloc] init] autorelease];
	[moc setPersistentStoreCoordinator:psc];
	[moc setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
	
	ASAccount *account = (ASAccount *)[moc objectWithID:accountObjectID];
	
	NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	NSArray *cookies = [cookieStorage cookiesForURL:[NSURL URLWithString:@"https://itunesconnect.apple.com"]];
	for (NSHTTPCookie *cookie in cookies) {
		[cookieStorage deleteCookie:cookie];
	}
	
	dispatch_async(dispatch_get_main_queue(), ^ {
		_account.downloadStatus = NSLocalizedString(@"Logging in...", nil);
		_account.downloadProgress = 0.0;
	});
	
	NSString *ittsBaseURL = @"https://itunesconnect.apple.com";
	NSString *ittsLoginPageAction = @"/WebObjects/iTunesConnect.woa";
	NSString *signoutSentinel = @"name=\"signOutForm\"";
    
	NSURL *loginURL = [NSURL URLWithString:[ittsBaseURL stringByAppendingString:ittsLoginPageAction]];
	NSHTTPURLResponse *loginPageResponse = nil;
	NSError *loginPageError = nil;
	NSData *loginPageData = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:loginURL] returningResponse:&loginPageResponse error:&loginPageError];
	NSString *loginPage = [[[NSString alloc] initWithData:loginPageData encoding:NSUTF8StringEncoding] autorelease];
	
	if ([loginPage rangeOfString:signoutSentinel].location == NSNotFound) {
		// find the login action
        NSScanner *loginPageScanner = [NSScanner scannerWithString:loginPage];
        [loginPageScanner scanUpToString:@"action=\"" intoString:nil];
		if (![loginPageScanner scanString:@"action=\"" intoString:nil]) {
			dispatch_async(dispatch_get_main_queue(), ^ {
				[[NSNotificationCenter defaultCenter] postNotificationName:ASReportDownloadFailedNotification 
																	object:self 
																  userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"Could not parse iTunes Connect login page", nil)
																									   forKey:kASReportDownloadErrorDescription]];
			});
			[pool release];
			return;
		}
		NSString *loginAction = nil;
		[loginPageScanner scanUpToString:@"\"" intoString:&loginAction];
		
		NSDictionary *postDict = [NSDictionary dictionaryWithObjectsAndKeys:
								  username, @"theAccountName",
								  password, @"theAccountPW", 
								  @"39", @"1.Continue.x", // coordinates of submit button on screen.  any values seem to work
								  @"7", @"1.Continue.y",
								  nil];
		loginPage = [self stringFromSynchronousPostRequestWithURL:[NSURL URLWithString:[ittsBaseURL stringByAppendingString:loginAction]] bodyDictionary:postDict];
		
		if (loginPage == nil || [loginPage rangeOfString:signoutSentinel].location == NSNotFound) {
			dispatch_async(dispatch_get_main_queue(), ^ {
				[[NSNotificationCenter defaultCenter] postNotificationName:ASReportDownloadFailedNotification 
																	object:self 
																  userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"Could not login. Please check your username and password.", nil) 
																									   forKey:kASReportDownloadErrorDescription]];
			});
			[pool release];
			return;
		}
	}
	
	if ([self isCancelled]) {
		[pool release];
		return;
	}
	
	dispatch_async(dispatch_get_main_queue(), ^ {
		_account.downloadStatus = NSLocalizedString(@"Checking for new reports...", nil);
		_account.downloadProgress = 0.1;
	});
	
	// load sales/trends page.
	NSError *error = nil;
	NSString *salesAction = @"https://reportingitc.apple.com";
	NSString *salesRedirectPage = [NSString stringWithContentsOfURL:[NSURL URLWithString:salesAction] usedEncoding:NULL error:&error];
	if (error) {
		dispatch_async(dispatch_get_main_queue(), ^ {
			[[NSNotificationCenter defaultCenter] postNotificationName:ASReportDownloadFailedNotification 
																object:self 
															  userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"The sales redirect page could not be loaded. Please try again later.", nil)
																								   forKey:kASReportDownloadErrorDescription]];
		});
		[pool release];
		return;
	}
	
	NSScanner *salesRedirectScanner = [NSScanner scannerWithString:salesRedirectPage];
	NSString *viewState = [salesRedirectPage stringByMatching:@"\"javax.faces.ViewState\" value=\"(.*?)\"" capture:1];
	[salesRedirectScanner scanUpToString:@"script id=\"defaultVendorPage:" intoString:nil];
	if (![salesRedirectScanner scanString:@"script id=\"defaultVendorPage:" intoString:nil]) {
		dispatch_async(dispatch_get_main_queue(), ^ {
			[[NSNotificationCenter defaultCenter] postNotificationName:ASReportDownloadFailedNotification 
																object:self 
															  userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"The sales redirect page could not be parsed.", nil)
																								   forKey:kASReportDownloadErrorDescription]];
		});
		[pool release];
		return;
	}
	NSString *defaultVendorPage = nil;
	[salesRedirectScanner scanUpToString:@"\"" intoString:&defaultVendorPage];
	
	// click though from the dashboard to the sales page
    NSDictionary *reportPostData = [NSDictionary dictionaryWithObjectsAndKeys:
									[defaultVendorPage stringByReplacingOccurrencesOfString:@"_2" withString:@"_0"], @"AJAXREQUEST",
									viewState, @"javax.faces.ViewState",
									defaultVendorPage, @"defaultVendorPage",
									[@"defaultVendorPage:" stringByAppendingString:defaultVendorPage],[@"defaultVendorPage:" stringByAppendingString:defaultVendorPage],
									nil];
	
	if ([self isCancelled]) {
		[pool release];
		return;
	}
	
	[self dataFromSynchronousPostRequestWithURL:[NSURL URLWithString:@"https://reportingitc.apple.com/vendor_default.faces"] bodyDictionary:reportPostData response:NULL];
	
	// get the form field names needed to download the report
	NSString *salesPage = [NSString stringWithContentsOfURL:[NSURL URLWithString:@"https://reportingitc.apple.com/sales.faces"] usedEncoding:NULL error:NULL];
	if (salesPage.length == 0) {
		dispatch_async(dispatch_get_main_queue(), ^ {
			[[NSNotificationCenter defaultCenter] postNotificationName:ASReportDownloadFailedNotification 
																object:self 
															  userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"Could not parse iTunes Connect login page", nil)
																								   forKey:kASReportDownloadErrorDescription]];
		});
		[pool release];
		return;
	}
	
	if ([self isCancelled]) {
		[pool release];
		return;
	}
	
	viewState = [salesPage stringByMatching:@"\"javax.faces.ViewState\" value=\"(.*?)\"" capture:1];
	NSString *dailyName = [salesPage stringByMatching:@"theForm:j_id_jsp_[0-9]*_6"];
	NSRange lastTwoChars = NSMakeRange([dailyName length] - 2, 2);
	//NSString *weeklyName = [dailyName stringByReplacingOccurrencesOfString:@"_6" withString:@"_22" options:0 range:lastTwoChars];
	NSString *ajaxName = [dailyName stringByReplacingOccurrencesOfString:@"_6" withString:@"_2" options:0 range:lastTwoChars];
	NSString *daySelectName = [dailyName stringByReplacingOccurrencesOfString:@"_6" withString:@"_47" options:0 range:lastTwoChars];
	NSString *weekSelectName = [dailyName stringByReplacingOccurrencesOfString:@"_6" withString:@"_52" options:0 range:lastTwoChars];
    
	// parse days available
	NSMutableArray *availableDays = [[[self extractFormOptionsFromPage:salesPage formID:@"theForm:datePickerSourceSelectElement"] mutableCopy] autorelease];
	if (availableDays == nil) {
		dispatch_async(dispatch_get_main_queue(), ^ {
			[[NSNotificationCenter defaultCenter] postNotificationName:ASReportDownloadFailedNotification 
																object:self 
															  userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"Unexpected date selector form.", nil)
																								   forKey:kASReportDownloadErrorDescription]];
		});
		[pool release];
		return;
    }
	NSString *arbitraryDay = [availableDays objectAtIndex:0];
	
	[availableDays sortUsingSelector:@selector(compare:)]; // download older reports first
	
	NSMutableArray *availableDates = [NSMutableArray array];
	for (NSString *availableDayName in availableDays) {
		NSDate *date = [self dateFromPopupMenuItemName:availableDayName];
		[availableDates addObject:date];
	}
	
	NSMutableArray *availableWeeks = [[[self extractFormOptionsFromPage:salesPage formID:@"theForm:weekPickerSourceSelectElement"] mutableCopy] autorelease];
	NSMutableArray *availableWeekDates = [NSMutableArray array];
	for (NSString *availableWeekName in availableWeeks) {
		NSDate *date = [self dateFromPopupMenuItemName:availableWeekName];
		[availableWeekDates addObject:date];
	}
	
	if (availableWeeks == nil) {
		dispatch_async(dispatch_get_main_queue(), ^ {
			[[NSNotificationCenter defaultCenter] postNotificationName:ASReportDownloadFailedNotification 
																object:self 
															  userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"Unexpected week selector form.", nil)
																								   forKey:kASReportDownloadErrorDescription]];
		});
		[pool release];
		return;
	}
	NSString *arbitraryWeek = [availableWeeks objectAtIndex:0];
	
	[availableWeeks sortUsingSelector:@selector(compare:)];
	
	if ([self isCancelled]) {
		[pool release];
		return;
	}
	
	// click though from the dashboard to the sales page
	NSDictionary *postDict = [NSDictionary dictionaryWithObjectsAndKeys:
							  ajaxName, @"AJAXREQUEST",
							  @"theForm", @"theForm",
							  @"notnormal", @"theForm:xyz",
							  @"Y", @"theForm:vendorType",
							  viewState, @"javax.faces.ViewState",
							  dailyName, dailyName,
							  nil];
	NSString *responseString = [self stringFromSynchronousPostRequestWithURL:[NSURL URLWithString:@"https://reportingitc.apple.com/sales.faces"] bodyDictionary:postDict];
	
	viewState = [responseString stringByMatching:@"\"javax.faces.ViewState\" value=\"(.*?)\"" capture:1];
	
	int numberOfReportsDownloaded = 0;
	
	// Fetch existing daily reports to not download them again:
	NSFetchRequest *existingDailyReportsRequest = [[[NSFetchRequest alloc] init] autorelease];
	[existingDailyReportsRequest setEntity:[NSEntityDescription entityForName:@"DailyReport" inManagedObjectContext:moc]];
	[existingDailyReportsRequest setPredicate:[NSPredicate predicateWithFormat:@"account == %@ AND startDate IN %@", account, [NSSet setWithArray:availableDates]]];
	[existingDailyReportsRequest setPropertiesToFetch:[NSArray arrayWithObject:@"startDate"]];
	[existingDailyReportsRequest setResultType:NSDictionaryResultType];
	[existingDailyReportsRequest setSortDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"startDate" ascending:YES] autorelease]]];
	NSArray *existingDailyReportDates = [[moc executeFetchRequest:existingDailyReportsRequest error:NULL] valueForKey:@"startDate"];
	
	NSMutableArray *existingDailyReportLabels = [NSMutableArray array];
	for (NSDate *existingReportDate in existingDailyReportDates) {
		NSString *label = [Report identifierForDate:existingReportDate];
		[existingDailyReportLabels addObject:label];
	}
	[availableDays removeObjectsInArray:existingDailyReportLabels];
	
	NSFetchRequest *existingWeeklyReportsRequest = [[[NSFetchRequest alloc] init] autorelease];
	[existingWeeklyReportsRequest setEntity:[NSEntityDescription entityForName:@"WeeklyReport" inManagedObjectContext:moc]];
	[existingWeeklyReportsRequest setPredicate:[NSPredicate predicateWithFormat:@"account == %@ AND endDate IN %@", account, [NSSet setWithArray:availableWeekDates]]];
	[existingWeeklyReportsRequest setPropertiesToFetch:[NSArray arrayWithObject:@"endDate"]];
	[existingWeeklyReportsRequest setResultType:NSDictionaryResultType];
	[existingWeeklyReportsRequest setSortDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"endDate" ascending:YES] autorelease]]];
	NSArray *existingWeeklyReportDates = [[moc executeFetchRequest:existingWeeklyReportsRequest error:NULL] valueForKey:@"endDate"];
	
	NSMutableArray *existingWeeklyReportLabels = [NSMutableArray array];
	for (NSDate *existingWeeklyReportDate in existingWeeklyReportDates) {
		NSString *label = [Report identifierForDate:existingWeeklyReportDate];
		[existingWeeklyReportLabels addObject:label];
	}
	[availableWeeks removeObjectsInArray:existingWeeklyReportLabels];
	
	NSInteger previousBadge = [account.reportsBadge integerValue];	
	
	// download new daily reports
	int numReportsActuallyAvailable = availableDays.count;
	int count = 1;
	for (NSString *dayString in availableDays) {
		if ([self isCancelled]) {
			[pool release];
			return;
		}
		dispatch_async(dispatch_get_main_queue(), ^ {
			float progress = (float)(count - 1) / (float)numReportsActuallyAvailable;
			_account.downloadStatus = [NSString stringWithFormat:NSLocalizedString(@"Downloading day %i / %i", nil), count, numReportsActuallyAvailable];
			_account.downloadProgress = 0.2 + (0.35 * progress);
		});
		count++;
		
		NSDictionary *downloadInfo = [NSDictionary dictionaryWithObjectsAndKeys:
									  ajaxName, @"ajaxName", 
									  dayString, @"dayString", 
									  arbitraryWeek, @"weekString", 
									  daySelectName, @"selectName", nil];
		
		NSString *originalFilename = nil;
		NSData *dailyReportData = [self downloadReportFromiTCWithInfo:downloadInfo viewState:&viewState originalFilename:&originalFilename];
		NSData *uncompressedDailyReportData = [dailyReportData gzipInflate];
		NSString *dailyReportCSV = [[[NSString alloc] initWithData:uncompressedDailyReportData encoding:NSUTF8StringEncoding] autorelease];
		
		Report *report = [Report insertNewReportWithCSV:dailyReportCSV inAccount:account];
		if (report && originalFilename) {
			//report.identifier = dayString;
			NSManagedObject *originalReport = [NSEntityDescription insertNewObjectForEntityForName:@"ReportCSV" inManagedObjectContext:moc];
			[originalReport setValue:dailyReportCSV forKey:@"content"];
			[originalReport setValue:report forKey:@"report"];
			[originalReport setValue:originalFilename forKey:@"filename"];
			[report generateCache];
		} else {
			NSLog(@"Could not parse report %@", dayString);
		}
		
		if (dailyReportCSV) {
			numberOfReportsDownloaded++;
			account.reportsBadge = [NSNumber numberWithInteger:previousBadge + numberOfReportsDownloaded];
		}
		
		[psc lock];
		NSError *saveError = nil;
		[moc save:&saveError];
		if (saveError) {
			NSLog(@"Could not save context: %@", saveError);
		}
		[psc unlock];
    }
	
	// download weekly reports
	numReportsActuallyAvailable = availableWeeks.count;
	count = 1;
	for (NSString *weekString in availableWeeks) {
		if ([self isCancelled]) {
			[pool release];
			return;
		}
		dispatch_async(dispatch_get_main_queue(), ^ {
			float progress = (float)(count - 1) / (float)numReportsActuallyAvailable;
			_account.downloadStatus = [NSString stringWithFormat:NSLocalizedString(@"Downloading week %i / %i", nil), count, numReportsActuallyAvailable];
			_account.downloadProgress = 0.55 + (0.35 * progress);
		});
		count++;
		
		NSDictionary *downloadInfo = [NSDictionary dictionaryWithObjectsAndKeys:
									  ajaxName, @"ajaxName", 
									  arbitraryDay, @"dayString", 
									  weekString, @"weekString", 
									  weekSelectName, @"selectName", nil];
		
		NSString *originalFilename = nil;
		NSData *weeklyReportData = [self downloadReportFromiTCWithInfo:downloadInfo viewState:&viewState originalFilename:&originalFilename];
		NSData *uncompressedWeeklyReportData = [weeklyReportData gzipInflate];
		NSString *weeklyReportCSV = [[[NSString alloc] initWithData:uncompressedWeeklyReportData encoding:NSUTF8StringEncoding] autorelease];
		
		Report *report = [Report insertNewReportWithCSV:weeklyReportCSV inAccount:account];
		if (report && originalFilename) {
			//report.identifier = dayString;
			NSManagedObject *originalReport = [NSEntityDescription insertNewObjectForEntityForName:@"ReportCSV" inManagedObjectContext:moc];
			[originalReport setValue:weeklyReportCSV forKey:@"content"];
			[originalReport setValue:report forKey:@"report"];
			[originalReport setValue:originalFilename forKey:@"filename"];
			[report generateCache];
		} else {
			NSLog(@"Could not parse report %@", weekString);
		}
		
		if (weeklyReportCSV) {
			numberOfReportsDownloaded++;
			account.reportsBadge = [NSNumber numberWithInteger:previousBadge + numberOfReportsDownloaded];
		}
		
		[psc lock];
		NSError *saveError = nil;
		[moc save:&saveError];
		if (saveError) {
			NSLog(@"Could not save context: %@", saveError);
		}
		[psc unlock];
		
    }
	if ([self isCancelled]) {
		[pool release];
		return;
	}
	//==== Payments
	if (numberOfReportsDownloaded > 0 || [account.payments count] == 0) {
		dispatch_async(dispatch_get_main_queue(), ^ {
			_account.downloadStatus = NSLocalizedString(@"Loading Payments...", nil);
			_account.downloadProgress = 0.9;
		});
		NSScanner *paymentsScanner = [NSScanner scannerWithString:loginPage];
		NSString *paymentsAction = nil;
		[paymentsScanner scanUpToString:@"alt=\"Payments and Financial Reports" intoString:NULL];
		[paymentsScanner scanUpToString:@"<a href=\"" intoString:NULL];
		[paymentsScanner scanString:@"<a href=\"" intoString:NULL];
		[paymentsScanner scanUpToString:@"\"" intoString:&paymentsAction];
		if (paymentsAction) {
			NSString *paymentsURLString = [NSString stringWithFormat:@"https://itunesconnect.apple.com%@", paymentsAction];
			
			NSData *paymentsPageData = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:paymentsURLString]] returningResponse:NULL error:NULL];
			
			if (paymentsPageData) {
				NSString *paymentsPage = [[[NSString alloc] initWithData:paymentsPageData encoding:NSUTF8StringEncoding] autorelease];
				
				NSMutableArray *vendorOptions = [NSMutableArray array];
				NSString *vendorSelectName = nil;
				NSString *switchVendorAction = nil;
				NSScanner *vendorFormScanner = [NSScanner scannerWithString:paymentsPage];
				[vendorFormScanner scanUpToString:@"<form name=\"mainForm\"" intoString:NULL];
				[vendorFormScanner scanUpToString:@"action=\"" intoString:NULL];
				if ([vendorFormScanner scanString:@"action=\"" intoString:NULL]) {
					[vendorFormScanner scanUpToString:@"\"" intoString:&switchVendorAction];
					if ([vendorFormScanner scanUpToString:@"<div class=\"vendor-id-container\">" intoString:NULL]) {
						NSString *vendorIDContainer = nil;
						[vendorFormScanner scanUpToString:@"</div" intoString:&vendorIDContainer];
						if (vendorIDContainer) {
							vendorFormScanner = [NSScanner scannerWithString:vendorIDContainer];
							[vendorFormScanner scanUpToString:@"<select" intoString:NULL];
							[vendorFormScanner scanUpToString:@"name=\"" intoString:NULL];
							[vendorFormScanner scanString:@"name=\"" intoString:NULL];
							[vendorFormScanner scanUpToString:@"\"" intoString:&vendorSelectName];
							
							while (![vendorFormScanner isAtEnd]) {
								if ([vendorFormScanner scanUpToString:@"<option" intoString:NULL]) {
									NSString *vendorOption = nil;
									[vendorFormScanner scanUpToString:@"</option" intoString:&vendorOption];
									if ([vendorOption rangeOfString:@"selected"].location == NSNotFound) {
										NSString *optionValue = nil;
										NSScanner *optionScanner = [NSScanner scannerWithString:vendorOption];
										[optionScanner scanUpToString:@"value=\"" intoString:NULL];
										[optionScanner scanString:@"value=\"" intoString:NULL];
										[optionScanner scanUpToString:@"\"" intoString:&optionValue];
										if (optionValue) {
											[vendorOptions addObject:optionValue];
										}
									}
								}
							}
						}
					}
				}
				
				[self parsePaymentsPage:paymentsPage inAccount:account vendorID:@""];
				for (NSString *additionalVendorOption in vendorOptions) {
					NSString *paymentsFormURLString = [NSString stringWithFormat:@"https://itunesconnect.apple.com%@", switchVendorAction];
                    
					NSData *additionalPaymentsPageData = [self dataFromSynchronousPostRequestWithURL:[NSURL URLWithString:paymentsFormURLString] 
																					  bodyDictionary:[NSDictionary dictionaryWithObjectsAndKeys:additionalVendorOption, vendorSelectName, nil]
																							response:NULL];
					NSString *additionalPaymentsPage = [[[NSString alloc] initWithData:additionalPaymentsPageData encoding:NSUTF8StringEncoding] autorelease];
					[self parsePaymentsPage:additionalPaymentsPage inAccount:account vendorID:additionalVendorOption];
				}
			}
		}
	}
	//==== /Payments
	
	downloadCount = numberOfReportsDownloaded;
	
	if ([moc hasChanges]) {
		[psc lock];
		NSError *saveError = nil;
		[moc save:&saveError];
		if (saveError) {
			NSLog(@"Could not save context: %@", saveError);
		}
		[psc unlock];
	}
	
	if (numberOfReportsDownloaded > 0) {
		dispatch_async(dispatch_get_main_queue(), ^ {
			_account.downloadStatus = NSLocalizedString(@"Finished", nil);
			_account.downloadProgress = 1.0;
		});
	} else {
		dispatch_async(dispatch_get_main_queue(), ^ {
			_account.downloadStatus = NSLocalizedString(@"No new reports found", nil);
			_account.downloadProgress = 1.0;
		});
	}
    
	[pool release];
}

- (void)parsePaymentsPage:(NSString *)paymentsPage inAccount:(ASAccount *)account vendorID:(NSString *)vendorID
{
	NSManagedObjectContext *moc = [account managedObjectContext];
	
	NSScanner *graphDataScanner = [NSScanner scannerWithString:paymentsPage];
	NSString *graphDataJSON = nil;
	[graphDataScanner scanUpToString:@"var graph_data_salesGraph_24_months = " intoString:NULL];
	[graphDataScanner scanString:@"var graph_data_salesGraph_24_months = " intoString:NULL];
	[graphDataScanner scanUpToString:@"}" intoString:&graphDataJSON];
	if (graphDataJSON) {
		graphDataJSON = [graphDataJSON stringByAppendingString:@"}"];
		graphDataJSON = [graphDataJSON stringByReplacingOccurrencesOfString:@"'" withString:@"\""];
		NSError *jsonError = nil;
		NSDictionary *graphDict = [graphDataJSON objectFromJSONStringWithParseOptions:JKParseOptionUnicodeNewlines | JKParseOptionLooseUnicode error:&jsonError];
		if (graphDict) {
			NSSet *allExistingPayments = account.payments;
			NSMutableSet *existingPaymentIdentifiers = [NSMutableSet set];
			for (NSManagedObject *payment in allExistingPayments) {
				[existingPaymentIdentifiers addObject:[NSString stringWithFormat:@"%@-%@-%@", [payment valueForKey:@"vendorID"], [payment valueForKey:@"month"], [payment valueForKey:@"year"]]];
			}
			NSDateFormatter *paymentMonthFormatter = [[[NSDateFormatter alloc] init] autorelease];
			[paymentMonthFormatter setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"en-us"] autorelease]];
			[paymentMonthFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
			[paymentMonthFormatter setDateFormat:@"MMM yy"];
			NSCalendar *calendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
			[calendar setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
			NSArray *amounts = [[graphDict objectForKey:@"data"] objectAtIndex:1];
			NSArray *labels = [graphDict objectForKey:@"labels"];
			NSArray *legend = [graphDict objectForKey:@"legend"];
			if (legend && [legend isKindOfClass:[NSArray class]] && [legend count] == 2) {
				NSString *currencyLegend = [legend objectAtIndex:1];
				NSString *currency = [currencyLegend stringByTrimmingCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]];
				NSInteger numberOfPaymentsLoaded = 0;
				if ([amounts count] == [labels count]) {
					for (int i=0; i<[labels count]; i++) {
						NSString *label = [labels objectAtIndex:i];
						NSNumber *amount = [amounts objectAtIndex:i];
						if (![amount isKindOfClass:[NSNumber class]] || ![label isKindOfClass:[NSString class]]) {
							continue;
						}
						if ([amount integerValue] == 0) {
							continue;
						}
						NSDate *labelDate = [paymentMonthFormatter dateFromString:label];
						if (labelDate) {
							NSDateComponents *dateComponents = [calendar components:NSMonthCalendarUnit | NSYearCalendarUnit fromDate:labelDate];
							NSInteger month = [dateComponents month];
							NSInteger year = [dateComponents year];
							NSString *paymentIdentifier = [NSString stringWithFormat:@"%@-%i-%i", vendorID, month, year];
							if (![existingPaymentIdentifiers containsObject:paymentIdentifier]) {
								NSManagedObject *payment = [NSEntityDescription insertNewObjectForEntityForName:@"Payment" inManagedObjectContext:moc];
								[payment setValue:account forKey:@"account"];
								[payment setValue:[NSNumber numberWithInteger:month] forKey:@"month"];
								[payment setValue:[NSNumber numberWithInteger:year] forKey:@"year"];
								[payment setValue:amount forKey:@"amount"];
								[payment setValue:currency forKey:@"currency"];
								[payment setValue:vendorID forKey:@"vendorID"];
								numberOfPaymentsLoaded++;
							}
						}
					}
				}
				account.paymentsBadge = [NSNumber numberWithInteger:[account.paymentsBadge integerValue] + numberOfPaymentsLoaded];
			}
		}
	}
}

- (NSData *)dataFromSynchronousPostRequestWithURL:(NSURL *)URL bodyDictionary:(NSDictionary *)bodyDictionary response:(NSHTTPURLResponse **)response
{
	NSString *postDictString = [bodyDictionary formatForHTTP];
	NSData *httpBody = [postDictString dataUsingEncoding:NSASCIIStringEncoding];
	NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:URL];
	[urlRequest setHTTPMethod:@"POST"];
	[urlRequest setHTTPBody:httpBody];
	NSData *data = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:response error:NULL];
	return data;
}

- (NSString *)stringFromSynchronousPostRequestWithURL:(NSURL *)URL bodyDictionary:(NSDictionary *)bodyDictionary
{
	NSData *data = [self dataFromSynchronousPostRequestWithURL:URL bodyDictionary:bodyDictionary response:NULL];
	if (data) {
		return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	}
	return nil;
}

- (NSArray *)extractFormOptionsFromPage:(NSString *)htmlPage formID:(NSString *)formID
{
	NSScanner *scanner = [NSScanner scannerWithString:htmlPage];
	NSString *selectionForm = nil;
	[scanner scanUpToString:formID intoString:nil];
	if (! [scanner scanString:formID intoString:nil]) {
		return nil;
	}
	[scanner scanUpToString:@"</select>" intoString:&selectionForm];
	if (![scanner scanString:@"</select>" intoString:nil]) {
		return nil;
	}
    
	NSMutableArray *options = [NSMutableArray array];
	NSScanner *selectionScanner = [NSScanner scannerWithString:selectionForm];
	while ([selectionScanner scanUpToString:@"<option value=\"" intoString:nil] && [selectionScanner scanString:@"<option value=\"" intoString:nil]) {
		NSString *selectorValue = nil;
		[selectionScanner scanUpToString:@"\"" intoString:&selectorValue];
		if (![selectionScanner scanString:@"\"" intoString:nil]) {
			return nil;
		}
		[options addObject:selectorValue];
	}
	return [NSArray arrayWithArray:options];
}

- (NSData *)downloadReportFromiTCWithInfo:(NSDictionary *)downloadInfo viewState:(NSString **)viewState originalFilename:(NSString **)filename
{
	// set the date within the web page
    NSDictionary *postDict = [NSDictionary dictionaryWithObjectsAndKeys:
                              [downloadInfo objectForKey:@"ajaxName"], @"AJAXREQUEST",
                              @"theForm", @"theForm",
                              @"theForm:xyz", @"notnormal",
                              @"Y", @"theForm:vendorType",
                              [downloadInfo objectForKey:@"dayString"], @"theForm:datePickerSourceSelectElementSales",
                              [downloadInfo objectForKey:@"weekString"], @"theForm:weekPickerSourceSelectElement",
                              *viewState, @"javax.faces.ViewState",
							  [downloadInfo objectForKey:@"selectName"], [downloadInfo objectForKey:@"selectName"],
                              nil];
	NSString *responseString = [self stringFromSynchronousPostRequestWithURL:[NSURL URLWithString:@"https://reportingitc.apple.com/sales.faces"] 
															  bodyDictionary:postDict];
	*viewState = [responseString stringByMatching:@"\"javax.faces.ViewState\" value=\"(.*?)\"" capture:1];
	
	// iTC shows a (fixed?) number of date ranges in the form, even if not all of them are available.
	// When trying to download a report that doesn't exist, it'll return an error page instead of the report
	if ([responseString rangeOfString:@"theForm:errorPanel"].location != NSNotFound) {
		return nil;
	}
    // and finally...we're ready to download the report
    postDict = [NSDictionary dictionaryWithObjectsAndKeys:
				@"theForm", @"theForm",
				@"notnormal", @"theForm:xyz",
				@"Y", @"theForm:vendorType",
				[downloadInfo objectForKey:@"dayString"], @"theForm:datePickerSourceSelectElementSales",
				[downloadInfo objectForKey:@"weekString"], @"theForm:weekPickerSourceSelectElement",
				*viewState, @"javax.faces.ViewState",
				@"theForm:downloadLabel2", @"theForm:downloadLabel2",
				nil];
	NSHTTPURLResponse *downloadResponse = nil;
	NSData *requestResponseData = [self dataFromSynchronousPostRequestWithURL:[NSURL URLWithString:@"https://reportingitc.apple.com/sales.faces"] bodyDictionary:postDict response:&downloadResponse];
	NSDictionary *responseHeaders = [downloadResponse allHeaderFields];
	NSString *originalFilename = [responseHeaders objectForKey:@"Filename"];
	if (!originalFilename) originalFilename = [responseHeaders objectForKey:@"filename"];
	
	if (originalFilename) {
		*filename = originalFilename;
		return requestResponseData;
	}
	return nil;
}

- (NSDate *)dateFromPopupMenuItemName:(NSString *)menuItemName
{
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"MM/dd/yyyy"];
	[formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	NSDate *date = [formatter dateFromString:menuItemName];
	[formatter release];
	return date;
}

- (void)dealloc
{
	[username release];
	[password release];
	[accountObjectID release];
	[_account release];
	[psc release];
	[super dealloc];
}

@end
