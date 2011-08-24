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
#import "WeeklyReport.h"
#import "RegexKitLite.h"
#import "NSData+Compression.h"
#import "NSDictionary+HTTP.h"
#import "JSONKit.h"

@interface ReportDownloadOperation ()

- (NSData *)dataFromSynchronousPostRequestWithURL:(NSURL *)URL bodyDictionary:(NSDictionary *)bodyDictionary response:(NSHTTPURLResponse **)response;
- (NSString *)stringFromSynchronousPostRequestWithURL:(NSURL *)URL bodyDictionary:(NSDictionary *)bodyDictionary;
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
	
	int numberOfReportsDownloaded = 0;
	dispatch_async(dispatch_get_main_queue(), ^ {
		_account.downloadStatus = NSLocalizedString(@"Starting download", nil);
		_account.downloadProgress = 0.0;
	});
	
	NSManagedObjectContext *moc = [[[NSManagedObjectContext alloc] init] autorelease];
	[moc setPersistentStoreCoordinator:psc];
	[moc setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
	
	ASAccount *account = (ASAccount *)[moc objectWithID:accountObjectID];
	NSInteger previousBadge = [account.reportsBadge integerValue];
	NSString *vendorID = account.vendorID;
	
	for (NSString *dateType in [NSArray arrayWithObjects:@"Daily", @"Weekly", nil]) {
		//Determine which reports should be available for download:
		NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
		[dateFormatter setDateFormat:@"yyyyMMdd"];
		[dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
		NSCalendar *calendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
		[calendar setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]]; 
		
		NSDate *today = [NSDate date];
		if ([dateType isEqualToString:@"Weekly"]) {
			//Find the next sunday:
			NSInteger weekday = -1;
			while (YES) {
				NSDateComponents *weekdayComponents = [calendar components:NSWeekdayCalendarUnit fromDate:today];
				weekday = [weekdayComponents weekday];
				if (weekday == 1) {
					break;
				} else {
					today = [today dateByAddingTimeInterval:24 * 60 * 60];
				}
			}
		}
		
		NSMutableArray *availableReportDateStrings = [NSMutableArray array];
		NSMutableSet *availableReportDates = [NSMutableSet set];
		
		NSInteger maxNumberOfAvailableReports = [dateType isEqualToString:@"Daily"] ? 14 : 13;
		for (int i=1; i<=maxNumberOfAvailableReports; i++) {
			NSDate *date = nil;
			if ([dateType isEqualToString:@"Daily"]) {
				date = [today dateByAddingTimeInterval:i * -24 * 60 * 60];
			} else { //weekly
				date = [today dateByAddingTimeInterval:i * -7 * 24 * 60 * 60];
			}
			NSDateComponents *components = [calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:date];
			NSDate *normalizedDate = [calendar dateFromComponents:components];
			NSString *dateString = [dateFormatter stringFromDate:normalizedDate];
			[availableReportDateStrings insertObject:dateString atIndex:0];
			[availableReportDates addObject:normalizedDate];
		}
		
		//Filter out reports we already have:
		NSFetchRequest *existingReportsFetchRequest = [[[NSFetchRequest alloc] init] autorelease];
		if ([dateType isEqualToString:@"Daily"]) {
			[existingReportsFetchRequest setEntity:[NSEntityDescription entityForName:@"DailyReport" inManagedObjectContext:moc]];
			[existingReportsFetchRequest setPredicate:[NSPredicate predicateWithFormat:@"account == %@ AND startDate IN %@", account, availableReportDates]];
		} else {
			[existingReportsFetchRequest setEntity:[NSEntityDescription entityForName:@"WeeklyReport" inManagedObjectContext:moc]];
			[existingReportsFetchRequest setPredicate:[NSPredicate predicateWithFormat:@"account == %@ AND endDate IN %@", account, availableReportDates]];
		}
		NSArray *existingReports = [moc executeFetchRequest:existingReportsFetchRequest error:NULL];
		
		for (Report *report in existingReports) {
			if ([dateType isEqualToString:@"Daily"]) {
				NSDate *startDate = report.startDate;
				NSString *startDateString = [dateFormatter stringFromDate:startDate];
				[availableReportDateStrings removeObject:startDateString];
			} else {
				NSDate *endDate = ((WeeklyReport *)report).endDate;
				NSString *endDateString = [dateFormatter stringFromDate:endDate];
				[availableReportDateStrings removeObject:endDateString];
			}
		}
		
		int i = 0;
		int numberOfReportsAvailable = [availableReportDateStrings count];
		for (NSString *reportDateString in availableReportDateStrings) {
			if ([self isCancelled]) {
				[pool release];
				return;
			}
			if (i == 0) {
				if ([dateType isEqualToString:@"Daily"]) {
					dispatch_async(dispatch_get_main_queue(), ^ {
						_account.downloadStatus = NSLocalizedString(@"Checking for daily reports...", nil);
						_account.downloadProgress = 0.1;
					});
				} else {
					dispatch_async(dispatch_get_main_queue(), ^ {
						_account.downloadStatus = NSLocalizedString(@"Checking for weekly reports...", nil);
						_account.downloadProgress = 0.5;
					});
				}
			} else {
				if ([dateType isEqualToString:@"Daily"]) {
					float progress = 0.5 * ((float)i / (float)numberOfReportsAvailable);
					dispatch_async(dispatch_get_main_queue(), ^ {
						_account.downloadStatus = [NSString stringWithFormat:NSLocalizedString(@"Loading daily report %i / %i", nil), i+1, numberOfReportsAvailable];
						_account.downloadProgress = progress;
					});
				} else {
					float progress = 0.5 + 0.4 * ((float)i / (float)numberOfReportsAvailable);
					dispatch_async(dispatch_get_main_queue(), ^ {
						_account.downloadStatus = [NSString stringWithFormat:NSLocalizedString(@"Loading weekly report %i / %i", nil), i+1, numberOfReportsAvailable];
						_account.downloadProgress = progress;
					});
				}
			}
			
			NSString *escapedUsername = [(NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)username, NULL, CFSTR("!*'();:@&=+$,/?%#[]"), kCFStringEncodingUTF8) autorelease];
			NSString *escapedPassword = [(NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)password, NULL, CFSTR("!*'();:@&=+$,/?%#[]"), kCFStringEncodingUTF8) autorelease];
			NSString *reportDownloadBodyString = [NSString stringWithFormat:@"USERNAME=%@&PASSWORD=%@&VNDNUMBER=%@&TYPEOFREPORT=%@&DATETYPE=%@&REPORTTYPE=%@&REPORTDATE=%@",
												  escapedUsername, escapedPassword, vendorID, @"Sales", dateType, @"Summary", reportDateString];
			
			NSData *reportDownloadBodyData = [reportDownloadBodyString dataUsingEncoding:NSUTF8StringEncoding];
			NSMutableURLRequest *reportDownloadRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://reportingitc.apple.com/autoingestion.tft"]];
			[reportDownloadRequest setHTTPMethod:@"POST"];
			[reportDownloadRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
			[reportDownloadRequest setValue:@"java/1.6.0_26" forHTTPHeaderField:@"User-Agent"];
			[reportDownloadRequest setHTTPBody:reportDownloadBodyData];
			
			NSHTTPURLResponse *response = nil;
			NSData *reportData = [NSURLConnection sendSynchronousRequest:reportDownloadRequest returningResponse:&response error:NULL];
			
			NSString *errorMessage = [[response allHeaderFields] objectForKey:@"Errormsg"];
			if (errorMessage) {
				NSLog(@"  %@", errorMessage);
			} else if (reportData) {
				NSString *originalFilename = [[response allHeaderFields] objectForKey:@"Filename"];
				NSData *inflatedReportData = [reportData gzipInflate];
				NSString *reportCSV = [[[NSString alloc] initWithData:inflatedReportData encoding:NSUTF8StringEncoding] autorelease];
				if (originalFilename && [reportCSV length] > 0) {
					//Parse report CSV:
					Report *report = [Report insertNewReportWithCSV:reportCSV inAccount:account];
					if (report && originalFilename) {
						NSManagedObject *originalReport = [NSEntityDescription insertNewObjectForEntityForName:@"ReportCSV" inManagedObjectContext:moc];
						[originalReport setValue:reportCSV forKey:@"content"];
						[originalReport setValue:report forKey:@"report"];
						[originalReport setValue:originalFilename forKey:@"filename"];
						[report generateCache];
						numberOfReportsDownloaded++;
						account.reportsBadge = [NSNumber numberWithInteger:previousBadge + numberOfReportsDownloaded];
					} else {
						NSLog(@"Could not parse report %@", originalFilename);
					}
					//Save data:
					[psc lock];
					NSError *saveError = nil;
					[moc save:&saveError];
					if (saveError) {
						NSLog(@"Could not save context: %@", saveError);
					}
					[psc unlock];
				}
			}
			i++;
		}
	}
	if ([self isCancelled]) {
		[pool release];
		return;
	}
	
	if (numberOfReportsDownloaded > 0 || [account.payments count] == 0) {
		//==== Payments
		NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
		NSArray *cookies = [cookieStorage cookiesForURL:[NSURL URLWithString:@"https://itunesconnect.apple.com"]];
		for (NSHTTPCookie *cookie in cookies) {
			[cookieStorage deleteCookie:cookie];
		}

		cookies = [cookieStorage cookiesForURL:[NSURL URLWithString:@"https://reportingitc.apple.com"]];    
		for (NSHTTPCookie *cookie in cookies) {
			[cookieStorage deleteCookie:cookie];
		}
		
		dispatch_async(dispatch_get_main_queue(), ^ {
			_account.downloadStatus = NSLocalizedString(@"Loading payments...", nil);
			_account.downloadProgress = 0.9;
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
			_account.downloadStatus = NSLocalizedString(@"Loading payments...", nil);
			_account.downloadProgress = 0.95;
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
		
				NSScanner *logoutFormScanner = [NSScanner scannerWithString:paymentsPage];
				NSString *signoutFormAction = nil;
				[logoutFormScanner scanUpToString:@"<form name=\"signOutForm\"" intoString:NULL];
				[logoutFormScanner scanUpToString:@"action=\"" intoString:NULL];
				if ([logoutFormScanner scanString:@"action=\"" intoString:NULL]) {
					[logoutFormScanner scanUpToString:@"\"" intoString:&signoutFormAction];
					NSURL *logoutURL = [NSURL URLWithString:[ittsBaseURL stringByAppendingString:signoutFormAction]];
					NSError *logoutPageError = nil;
					[NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:logoutURL] returningResponse:nil error:&logoutPageError];
				}
			}
		}
		
		//==== /Payments
	}
	
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
