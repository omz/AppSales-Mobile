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
#import "NSData+Compression.h"
#import "NSDictionary+HTTP.h"

@interface ReportDownloadOperation ()

- (NSData *)dataFromSynchronousPostRequestWithURL:(NSURL *)URL bodyDictionary:(NSDictionary *)bodyDictionary response:(NSHTTPURLResponse **)response;
- (NSString *)stringFromSynchronousPostRequestWithURL:(NSURL *)URL bodyDictionary:(NSDictionary *)bodyDictionary;
- (void)parsePaymentsPage:(NSString *)paymentsPage inAccount:(ASAccount *)account vendorID:(NSString *)vendorID;

@end


@implementation ReportDownloadOperation

@synthesize downloadCount, accountObjectID;

- (id)initWithAccount:(ASAccount *)account {
	self = [super init];
	if (self) {
		username = [account.username copy];
		password = [account.password copy];
		appPassword = [account.appPassword copy];
		_account = account;
		accountObjectID = [account.objectID copy];
		psc = [account.managedObjectContext persistentStoreCoordinator];
	}
	return self;
}

- (void)main {
	@autoreleasepool {
		
		int numberOfReportsDownloaded = 0;
		dispatch_async(dispatch_get_main_queue(), ^ {
			_account.downloadStatus = NSLocalizedString(@"Starting download", nil);
			_account.downloadProgress = 0.0;
		});
		
		NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] init];
		[moc setPersistentStoreCoordinator:psc];
		[moc setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
		
		ASAccount *account = (ASAccount *)[moc objectWithID:accountObjectID];
		NSInteger previousBadge = [account.reportsBadge integerValue];
		NSString *vendorID = account.vendorID;
		
		NSMutableDictionary *errors = [[NSMutableDictionary alloc] init];
		for (NSString *dateType in [NSArray arrayWithObjects:@"Daily", @"Weekly", nil]) {
			//Determine which reports should be available for download:
			NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
			[dateFormatter setDateFormat:@"yyyyMMdd"];
			[dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
			NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
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
			
			NSInteger maxNumberOfAvailableReports = [dateType isEqualToString:@"Daily"] ? 30 : 13;
			for (int i = 1; i <= maxNumberOfAvailableReports; i++) {
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
			NSFetchRequest *existingReportsFetchRequest = [[NSFetchRequest alloc] init];
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
			NSUInteger numberOfReportsAvailable = [availableReportDateStrings count];
			for (NSString *reportDateString in availableReportDateStrings) {
				if ([self isCancelled]) {
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
				
				NSString *reportDownloadBodyString = [NSString stringWithFormat:@"USERNAME=%@&PASSWORD=%@&VNDNUMBER=%@&TYPEOFREPORT=%@&DATETYPE=%@&REPORTTYPE=%@&REPORTDATE=%@", NSStringPercentEscaped(username), NSStringPercentEscaped(appPassword), vendorID, @"Sales", dateType, @"Summary", reportDateString];
				
				NSData *reportDownloadBodyData = [reportDownloadBodyString dataUsingEncoding:NSUTF8StringEncoding];
				NSMutableURLRequest *reportDownloadRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://reportingitc.apple.com/autoingestion.tft"]];
				[reportDownloadRequest setHTTPMethod:@"POST"];
				[reportDownloadRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
				[reportDownloadRequest setValue:@"java/1.6.0_26" forHTTPHeaderField:@"User-Agent"];
				[reportDownloadRequest setHTTPBody:reportDownloadBodyData];
				
				NSHTTPURLResponse *response = nil;
				NSData *reportData = [NSURLConnection sendSynchronousRequest:reportDownloadRequest returningResponse:&response error:NULL];
				
				NSString *errorMessage = [[response allHeaderFields] objectForKey:@"Errormsg"];
				// The message "Daily Reports are only available for past 365 days. Please enter a new date."
				// just means that the report in question has not yet been released.
				// We can safely ignore this error and move on.
				if ([errorMessage rangeOfString:@"past 365 days"].location == NSNotFound) {
					NSLog(@"%@ -> %@", reportDateString, errorMessage);
					
					NSInteger year = [[reportDateString substringWithRange:NSMakeRange(0, 4)] intValue];
					NSInteger month = [[reportDateString substringWithRange:NSMakeRange(4, 2)] intValue];
					NSInteger day = [[reportDateString substringWithRange:NSMakeRange(6, 2)] intValue];
					
					NSDateComponents *components = [[NSDateComponents alloc] init];
					[components setYear:year];
					[components setMonth:month];
					[components setDay:day];
					
					NSDate *reportDate = [[NSCalendar currentCalendar] dateFromComponents:components];
					
					NSMutableDictionary *reportTypes = [[NSMutableDictionary alloc] initWithDictionary:errors[errorMessage]];
					
					NSMutableArray *reports = [[NSMutableArray alloc] initWithArray:reportTypes[dateType]];
					[reports addObject:reportDate];
					reportTypes[dateType] = reports;
					
					errors[errorMessage] = reportTypes;
				} else if (reportData) {
					NSString *originalFilename = [[response allHeaderFields] objectForKey:@"Filename"];
					NSData *inflatedReportData = [reportData gzipInflate];
					NSString *reportCSV = [[NSString alloc] initWithData:inflatedReportData encoding:NSUTF8StringEncoding];
					if (originalFilename && [reportCSV length] > 0) {
						//Parse report CSV:
						Report *report = [Report insertNewReportWithCSV:reportCSV inAccount:account];
						
						//Check if the downloaded report is actually the one we expect
						//(mostly to work around a bug in iTC that causes the wrong weekly report to be downloaded):
						NSString *downloadedReportDateString = nil;
						if ([report isKindOfClass:[WeeklyReport class]]) {
							WeeklyReport *weeklyReport = (WeeklyReport *)report;
							downloadedReportDateString = [dateFormatter stringFromDate:weeklyReport.endDate];
						} else {
							downloadedReportDateString = [dateFormatter stringFromDate:report.startDate];
						}
						if (![reportDateString isEqualToString:downloadedReportDateString]) {
							NSLog(@"Downloaded report has incorrect date, ignoring");
							[[report managedObjectContext] deleteObject:report];
							report = nil;
							continue;
						}
						
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
			return;
		}
	
		dispatch_async(dispatch_get_main_queue(), ^{
			NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
			dateFormatter.timeStyle = NSDateFormatterNoStyle;
			dateFormatter.dateStyle = NSDateFormatterShortStyle;
			for (NSString *error in errors.allKeys) {
				NSString *message = error;
				
				NSDictionary *reportTypes = errors[error];
				for (NSString *reportType in reportTypes.allKeys) {
					message = [message stringByAppendingFormat:@"\n\n%@ Reports:", reportType];
					for (NSDate *reportDate in reportTypes[reportType]) {
						message = [message stringByAppendingFormat:@"\n%@", [dateFormatter stringFromDate:reportDate]];
					}
				}
				
				UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
																	message:message
																   delegate:nil
														  cancelButtonTitle:NSLocalizedString(@"OK", nil)
														  otherButtonTitles:nil];
				[alertView show];
			}
		});
		
		BOOL downloadPayments = [[NSUserDefaults standardUserDefaults] boolForKey:kSettingDownloadPayments];
		if (downloadPayments && (numberOfReportsDownloaded > 0 || [account.payments count] == 0)) {
			dispatch_async(dispatch_get_main_queue(), ^ {
				_account.downloadStatus = NSLocalizedString(@"Loading payments...", nil);
				_account.downloadProgress = 0.9;
			});
			
			LoginManager *loginManager = [[LoginManager alloc] initWithAccount:_account];
			loginManager.shouldDeleteCookies = [[NSUserDefaults standardUserDefaults] boolForKey:kSettingDeleteCookies];
			loginManager.delegate = self;
			[loginManager logIn];
		} else {
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
	}
}

- (void)loginSucceeded {
	@autoreleasepool {
		
		dispatch_async(dispatch_get_main_queue(), ^ {
			_account.downloadStatus = NSLocalizedString(@"Loading payments...", nil);
			_account.downloadProgress = 0.95;
		});
		
		NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] init];
		[moc setPersistentStoreCoordinator:psc];
		[moc setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
		
		ASAccount *account = (ASAccount *)[moc objectWithID:accountObjectID];
		
		//==== Payments
		
		NSURL *paymentsPageURL = [NSURL URLWithString:[kITCBaseURL stringByAppendingString:kITCPaymentsPageAction]];
		NSData *paymentsPageData = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:paymentsPageURL] returningResponse:NULL error:NULL];
		
		if (paymentsPageData) {
			NSString *paymentsPage = [[NSString alloc] initWithData:paymentsPageData encoding:NSUTF8StringEncoding];
			
			NSString *switchVendorAction = nil;
			NSString *switchVendorSelectName = nil;
			NSMutableArray *vendorOptions = [NSMutableArray array];
			NSScanner *vendorFormScanner = [NSScanner scannerWithString:paymentsPage];
			[vendorFormScanner scanUpToString:@"<form name=\"mainForm\"" intoString:NULL];
			[vendorFormScanner scanString:@"<form name=\"mainForm\"" intoString:NULL];
			if ([vendorFormScanner scanUpToString:@"action=\"" intoString:NULL]) {
				[vendorFormScanner scanString:@"action=\"" intoString:NULL];
				[vendorFormScanner scanUpToString:@"\"" intoString:&switchVendorAction];
				if ([vendorFormScanner scanUpToString:@"<div class=\"vendor-id-container\">" intoString:NULL]) {
					[vendorFormScanner scanString:@"<div class=\"vendor-id-container\">" intoString:NULL];
					NSString *vendorIDContainer = nil;
					[vendorFormScanner scanUpToString:@"</div>" intoString:&vendorIDContainer];
					if (vendorIDContainer) {
						vendorFormScanner = [NSScanner scannerWithString:vendorIDContainer];
						
						if ([vendorFormScanner scanUpToString:@"name=\"" intoString:NULL]) {
							[vendorFormScanner scanString:@"name=\"" intoString:NULL];
							[vendorFormScanner scanUpToString:@"\"" intoString:&switchVendorSelectName];
							[vendorFormScanner scanUpToString:@"<option" intoString:NULL];
							while ([vendorFormScanner scanString:@"<option" intoString:NULL]) {
								NSString *value = nil;
								NSString *vendorID = nil;
								
								// Parse vendor index.
								[vendorFormScanner scanUpToString:@"value=\"" intoString:NULL];
								[vendorFormScanner scanString:@"value=\"" intoString:NULL];
								[vendorFormScanner scanUpToString:@"\"" intoString:&value];
								
								// Parse vendor ID.
								[vendorFormScanner scanUpToString:@">" intoString:NULL];
								[vendorFormScanner scanString:@">" intoString:NULL];
								[vendorFormScanner scanUpToString:@"- " intoString:NULL];
								[vendorFormScanner scanString:@"- " intoString:NULL];
								[vendorFormScanner scanUpToString:@"</option>" intoString:&vendorID];
								
								NSMutableDictionary *vendorOption = [[NSMutableDictionary alloc] init];
								vendorOption[@"id"] = vendorID;
								vendorOption[@"value"] = value;
								[vendorOptions addObject:vendorOption];
								
								[vendorFormScanner scanUpToString:@"<option" intoString:NULL];
							}
						}
					}
				}
			}
			
			[self parsePaymentsPage:paymentsPage inAccount:account vendorID:@""];
			for (NSDictionary *additionalVendorOption in vendorOptions) {
				NSString *bodyString = [NSString stringWithFormat:@"%@=%@", switchVendorSelectName, additionalVendorOption[@"value"]];
				NSData *bodyData = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
				
				NSURL *paymentsFormURL = [NSURL URLWithString:[kITCBaseURL stringByAppendingString:switchVendorAction]];
				NSMutableURLRequest *paymentsFormRequest = [NSMutableURLRequest requestWithURL:paymentsFormURL];
				[paymentsFormRequest setHTTPMethod:@"POST"];
				[paymentsFormRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
				[paymentsFormRequest setHTTPBody:bodyData];
				
				NSHTTPURLResponse *response = nil;
				NSData *additionalPaymentsPageData = [NSURLConnection sendSynchronousRequest:paymentsFormRequest returningResponse:&response error:NULL];
				NSString *additionalPaymentsPage = [[NSString alloc] initWithData:additionalPaymentsPageData encoding:NSUTF8StringEncoding];
				
				[self parsePaymentsPage:additionalPaymentsPage inAccount:account vendorID:additionalVendorOption[@"id"]];
			}
			
			NSScanner *logoutFormScanner = [NSScanner scannerWithString:paymentsPage];
			NSString *signoutFormAction = nil;
			[logoutFormScanner scanUpToString:@"<li role=\"menuitem\" class=\"session-nav-link\">" intoString:NULL];
			[logoutFormScanner scanString:@"<li role=\"menuitem\" class=\"session-nav-link\">" intoString:NULL];
			[logoutFormScanner scanUpToString:@"<a href=\"" intoString:NULL];
			if ([logoutFormScanner scanString:@"<a href=\"" intoString:NULL]) {
				[logoutFormScanner scanUpToString:@"\"" intoString:&signoutFormAction];
				NSURL *logoutURL = [NSURL URLWithString:[kITCBaseURL stringByAppendingString:signoutFormAction]];
				[NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:logoutURL] returningResponse:nil error:nil];
			}
		}
		
		//==== /Payments
		
		if ([moc hasChanges]) {
			[psc lock];
			NSError *saveError = nil;
			[moc save:&saveError];
			if (saveError) {
				NSLog(@"Could not save context: %@", saveError);
			}
			[psc unlock];
		}
		
		dispatch_async(dispatch_get_main_queue(), ^ {
			_account.downloadStatus = NSLocalizedString(@"Finished", nil);
			_account.downloadProgress = 1.0;
		});
	}
}

- (void)loginFailed {
	dispatch_async(dispatch_get_main_queue(), ^ {
		_account.downloadStatus = NSLocalizedString(@"Finished", nil);
		_account.downloadProgress = 1.0;
	});
}

- (void)parsePaymentsPage:(NSString *)paymentsPage inAccount:(ASAccount *)account vendorID:(NSString *)vendorID {
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
		
		NSDictionary *graphDict = [NSJSONSerialization JSONObjectWithData:[graphDataJSON dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&jsonError];
		if (graphDict) {
			NSSet *allExistingPayments = account.payments;
			NSMutableSet *existingPaymentIdentifiers = [NSMutableSet set];
			for (NSManagedObject *payment in allExistingPayments) {
				[existingPaymentIdentifiers addObject:[NSString stringWithFormat:@"%@-%@-%@", [payment valueForKey:@"vendorID"], [payment valueForKey:@"month"], [payment valueForKey:@"year"]]];
			}
			NSDateFormatter *paymentMonthFormatter = [[NSDateFormatter alloc] init];
			[paymentMonthFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en-us"]];
			[paymentMonthFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
			[paymentMonthFormatter setDateFormat:@"MMM yy"];
			NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
			[calendar setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
			NSArray *amounts = ([[graphDict objectForKey:@"data"] count] >= 2) ? [[graphDict objectForKey:@"data"] objectAtIndex:1] : nil;
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
							NSString *paymentIdentifier = [NSString stringWithFormat:@"%@-%li-%li", vendorID, (long)month, (long)year];
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

- (NSData *)dataFromSynchronousPostRequestWithURL:(NSURL *)URL bodyDictionary:(NSDictionary *)bodyDictionary response:(NSHTTPURLResponse **)response {
	NSString *postDictString = [bodyDictionary formatForHTTP];
	NSData *httpBody = [postDictString dataUsingEncoding:NSASCIIStringEncoding];
	NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:URL];
	[urlRequest setHTTPMethod:@"POST"];
	[urlRequest setHTTPBody:httpBody];
	NSData *data = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:response error:NULL];
	return data;
}

- (NSString *)stringFromSynchronousPostRequestWithURL:(NSURL *)URL bodyDictionary:(NSDictionary *)bodyDictionary {
	NSData *data = [self dataFromSynchronousPostRequestWithURL:URL bodyDictionary:bodyDictionary response:NULL];
	if (data) {
		return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	}
	return nil;
}


@end
