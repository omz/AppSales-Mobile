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

@implementation ReportDownloadOperation

@synthesize accountObjectID;

- (instancetype)initWithAccount:(ASAccount *)account {
	self = [super init];
	if (self) {
		username = [account.username copy];
		password = [account.password copy];
		appPassword = [account.appPassword copy];
		_account = account;
		accountObjectID = [account.objectID copy];
		psc = [account.managedObjectContext persistentStoreCoordinator];
		
		[UIApplication sharedApplication].idleTimerDisabled = YES;
		backgroundTaskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^(void) {
			NSLog(@"Background task for downloading reports has expired!");
		}];
	}
	return self;
}

- (void)main {
	@autoreleasepool {
		
		NSInteger numberOfReportsDownloaded = 0;
		[self downloadProgress:0.0f withStatus:NSLocalizedString(@"Starting download", nil)];
		
		NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] init];
		moc.persistentStoreCoordinator = psc;
		moc.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
		
		ASAccount *account = (ASAccount *)[moc objectWithID:accountObjectID];
		NSInteger previousBadge = account.reportsBadge.integerValue;
		NSString *vendorID = account.vendorID;
		
		NSMutableDictionary *errors = [[NSMutableDictionary alloc] init];
		for (NSString *dateType in @[@"Daily", @"Weekly"]) {
			// Determine which reports should be available for download.
			NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
			[dateFormatter setDateFormat:@"yyyyMMdd"];
			[dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
			NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
			[calendar setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]]; 
			
			NSDate *today = [NSDate date];
			if ([dateType isEqualToString:@"Weekly"]) {
				// Find the next Sunday.
				NSInteger weekday = -1;
				while (YES) {
					NSDateComponents *weekdayComponents = [calendar components:NSCalendarUnitWeekday fromDate:today];
					weekday = weekdayComponents.weekday;
					if (weekday == 1) {
						break;
					} else {
						today = [today dateByAddingTimeInterval:24 * 60 * 60];
					}
				}
			}
			
			NSMutableArray *availableReportDateStrings = [NSMutableArray array];
			NSMutableSet *availableReportDates = [NSMutableSet set];
			
			NSInteger maxNumberOfAvailableReports = [dateType isEqualToString:@"Daily"] ? 31 : 20;
			for (int i = 1; i <= maxNumberOfAvailableReports; i++) {
				NSDate *date = nil;
				if ([dateType isEqualToString:@"Daily"]) {
					date = [today dateByAddingTimeInterval:i * -24 * 60 * 60];
				} else { // Weekly
					date = [today dateByAddingTimeInterval:i * -7 * 24 * 60 * 60];
				}
				NSDateComponents *components = [calendar components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:date];
				NSDate *normalizedDate = [calendar dateFromComponents:components];
				NSString *dateString = [dateFormatter stringFromDate:normalizedDate];
				[availableReportDateStrings insertObject:dateString atIndex:0];
				[availableReportDates addObject:normalizedDate];
			}
			
			// Filter out reports we already have.
			NSFetchRequest *existingReportsFetchRequest = [[NSFetchRequest alloc] init];
			if ([dateType isEqualToString:@"Daily"]) {
				[existingReportsFetchRequest setEntity:[NSEntityDescription entityForName:@"DailyReport" inManagedObjectContext:moc]];
				[existingReportsFetchRequest setPredicate:[NSPredicate predicateWithFormat:@"account == %@ AND startDate IN %@", account, availableReportDates]];
			} else {
				[existingReportsFetchRequest setEntity:[NSEntityDescription entityForName:@"WeeklyReport" inManagedObjectContext:moc]];
				[existingReportsFetchRequest setPredicate:[NSPredicate predicateWithFormat:@"account == %@ AND endDate IN %@", account, availableReportDates]];
			}
			NSArray *existingReports = [moc executeFetchRequest:existingReportsFetchRequest error:nil];
			
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
				if (self.isCancelled) {
					[self completeDownloadWithStatus:NSLocalizedString(@"Canceled", nil)];
					return;
				}
				if (i == 0) {
					if ([dateType isEqualToString:@"Daily"]) {
						[self downloadProgress:0.1f withStatus:NSLocalizedString(@"Checking for daily reports...", nil)];
					} else {
						[self downloadProgress:0.5f withStatus:NSLocalizedString(@"Checking for weekly reports...", nil)];
					}
				} else {
					if ([dateType isEqualToString:@"Daily"]) {
						CGFloat progress = 0.5f * ((CGFloat)i / (CGFloat)numberOfReportsAvailable);
						NSString *status = [NSString stringWithFormat:NSLocalizedString(@"Loading daily report %i / %i", nil), i + 1, numberOfReportsAvailable];
						[self downloadProgress:progress withStatus:status];
					} else {
						CGFloat progress = 0.5f + 0.4f * ((CGFloat)i / (CGFloat)numberOfReportsAvailable);
						NSString *status = [NSString stringWithFormat:NSLocalizedString(@"Loading weekly report %i / %i", nil), i + 1, numberOfReportsAvailable];
						[self downloadProgress:progress withStatus:status];
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
				NSData *reportData = [NSURLConnection sendSynchronousRequest:reportDownloadRequest returningResponse:&response error:nil];
				
				NSString *errorMessage = response.allHeaderFields[@"Errormsg"];
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
					NSString *originalFilename = response.allHeaderFields[@"Filename"];
					NSData *inflatedReportData = [reportData gzipInflate];
					NSString *reportCSV = [[NSString alloc] initWithData:inflatedReportData encoding:NSUTF8StringEncoding];
					if (originalFilename && [reportCSV length] > 0) {
						// Parse report CSV.
						Report *report = [Report insertNewReportWithCSV:reportCSV inAccount:account];
						
						// Check if the downloaded report is actually the one we expect.
						// (mostly to work around a bug in ITC that causes the wrong weekly report to be downloaded).
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
							account.reportsBadge = @(previousBadge + numberOfReportsDownloaded);
						} else {
							NSLog(@"Could not parse report %@", originalFilename);
						}
						// Save data.
						[psc performBlockAndWait:^{
							NSError *saveError = nil;
							[moc save:&saveError];
							if (saveError) {
								NSLog(@"Could not save context: %@", saveError);
							}
						}];
					}
				}
				i++;
			}
		}
		if (self.isCancelled) {
			[self completeDownloadWithStatus:NSLocalizedString(@"Canceled", nil)];
			return;
		}
	
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
			
			[self showErrorWithMessage:message];
		}
		
		BOOL downloadPayments = [[NSUserDefaults standardUserDefaults] boolForKey:kSettingDownloadPayments];
		if (downloadPayments && ((numberOfReportsDownloaded > 0) || (account.payments.count == 0))) {
			[self downloadProgress:0.9f withStatus:NSLocalizedString(@"Loading payments...", nil)];
			
			LoginManager *loginManager = [[LoginManager alloc] initWithAccount:_account];
			loginManager.shouldDeleteCookies = [[NSUserDefaults standardUserDefaults] boolForKey:kSettingDeleteCookies];
			loginManager.delegate = self;
			[loginManager logIn];
		} else {
			if (numberOfReportsDownloaded > 0) {
				[self completeDownload];
			} else {
				[self completeDownloadWithStatus:NSLocalizedString(@"No new reports found", nil)];
			}
		}
		
		if ([moc hasChanges]) {
			[psc performBlockAndWait:^{
				NSError *saveError = nil;
				[moc save:&saveError];
				if (saveError) {
					NSLog(@"Could not save context: %@", saveError);
				}
			}];
		}
	}
}

- (void)loginSucceeded {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
		@autoreleasepool {
			
			[self downloadProgress:0.95f withStatus:NSLocalizedString(@"Loading payments...", nil)];
			
			//==== Payments
			
			NSURL *userDetailURL = [NSURL URLWithString:[kITCBaseURL stringByAppendingString:kITCUserDetailAction]];
			NSData *userDetailData = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:userDetailURL] returningResponse:nil error:nil];
			NSDictionary *userDetail = [NSJSONSerialization JSONObjectWithData:userDetailData options:0 error:nil];
			contentProviderId = userDetail[@"data"][@"contentProviderId"];
			
			if (self.isCancelled) {
				[self completeDownloadWithStatus:NSLocalizedString(@"Canceled", nil)];
			} else if (contentProviderId.length > 0) {
				NSURL *paymentVendorsURL = [NSURL URLWithString:[kITCBaseURL stringByAppendingFormat:kITCPaymentVendorsAction, contentProviderId]];
				NSData *paymentVendorsData = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:paymentVendorsURL] returningResponse:nil error:nil];
				NSDictionary *paymentVendors = [NSJSONSerialization JSONObjectWithData:paymentVendorsData options:0 error:nil];
				NSArray *sapVendors = paymentVendors[@"data"];
				
				if (self.isCancelled) {
					[self completeDownloadWithStatus:NSLocalizedString(@"Canceled", nil)];
				} else if (sapVendors.count > 0) {
					if (downloadedVendors == nil) {
						downloadedVendors = [[NSMutableDictionary alloc] init];
					} else {
						[downloadedVendors removeAllObjects];
					}
					for (NSDictionary *vendor in sapVendors) {
						NSNumber *vendorID = vendor[@"sapVendorNumber"];
						downloadedVendors[vendorID.description] = @(0);
					}
					for (NSString *vendorID in downloadedVendors.allKeys) {
						[self fetchPaymentsForVendorID:vendorID];
					}
				} else {
					[self completeDownload];
				}
			}
			
			//==== /Payments
		}
	});
}

- (void)loginFailed {
	[self completeDownload];
}

- (void)fetchPaymentsForVendorID:(NSString *)vendorID {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
		@autoreleasepool {
			
			NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] init];
			[moc setPersistentStoreCoordinator:psc];
			[moc setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
			
			ASAccount *account = (ASAccount *)[moc objectWithID:accountObjectID];
		
			NSSet *allExistingPayments = account.payments;
			NSMutableSet *existingPaymentIdentifiers = [NSMutableSet set];
			for (NSManagedObject *payment in allExistingPayments) {
				[existingPaymentIdentifiers addObject:[NSString stringWithFormat:@"%@-%@", [payment valueForKey:@"year"], [payment valueForKey:@"month"]]];
			}
			
			NSNumberFormatter *currencyFormatter = [[NSNumberFormatter alloc] init];
			currencyFormatter.numberStyle = NSNumberFormatterDecimalStyle;
			
			NSDate *currDate = [NSDate date];
			
			NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
			NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
			offsetComponents.month = -1;
			
			while (YES) {
				currDate = [calendar dateByAddingComponents:offsetComponents toDate:currDate options:0];
				
				NSDateComponents *dateComponents = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth) fromDate:currDate];
				NSInteger year = dateComponents.year;
				NSInteger month = dateComponents.month;
				
				NSString *paymentIdentifier = [NSString stringWithFormat:@"%li-%li", (long)year, (long)month];
				if ([existingPaymentIdentifiers containsObject:paymentIdentifier]) {
					// We've already been here before, so bail out.
					break;
				}
				
				NSURL *paymentURL = [NSURL URLWithString:[kITCBaseURL stringByAppendingFormat:kITCPaymentVendorsPaymentAction, contentProviderId, vendorID, year, month]];
				NSData *paymentData = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:paymentURL] returningResponse:nil error:nil];
				NSDictionary *payment = [NSJSONSerialization JSONObjectWithData:paymentData options:0 error:nil];
				payment = payment[@"data"];
				NSArray *paymentSummaries = payment[@"reportSummaries"];
				
				if (self.isCancelled) {
					[self completeDownloadWithStatus:NSLocalizedString(@"Canceled", nil)];
					break;
				} else if (paymentSummaries.count == 0) {
					@synchronized(downloadedVendors) {
						NSInteger count = [downloadedVendors[vendorID] integerValue];
						count++;
						downloadedVendors[vendorID] = @(count);
						// Bail out if there are no payments for over 12 consecutive months.
						if (count > 12) { break; }
					}
				} else {
					@synchronized(downloadedVendors) {
						downloadedVendors[vendorID] = @(0);
					}
					BOOL shouldSave = NO;
					CGFloat amount = 0.0f;
					NSString *currency = nil;
					for (NSDictionary *payment in paymentSummaries) {
						if ([payment[@"status"] isEqualToString:@"PAID"]) {
							shouldSave = YES;
							amount += [currencyFormatter numberFromString:payment[@"amount"]].floatValue;
							if (currency == nil) {
								currency = payment[@"currency"];
							}
						}
					}
					if (shouldSave) {
						NSManagedObject *payment = [NSEntityDescription insertNewObjectForEntityForName:@"Payment" inManagedObjectContext:moc];
						[payment setValue:account forKey:@"account"];
						[payment setValue:@(year) forKey:@"year"];
						[payment setValue:@(month) forKey:@"month"];
						[payment setValue:@(amount) forKey:@"amount"];
						[payment setValue:currency forKey:@"currency"];
						[payment setValue:vendorID forKey:@"vendorID"];
						
						if ([moc hasChanges]) {
							[psc performBlockAndWait:^{
								NSError *saveError = nil;
								[moc save:&saveError];
								if (saveError) {
									NSLog(@"Could not save context: %@", saveError);
								}
							}];
						}
						
						dispatch_async(dispatch_get_main_queue(), ^{
							@synchronized(account.paymentsBadge) {
								account.paymentsBadge = @(account.paymentsBadge.integerValue + 1);
							}
						});
					}
				}
			}
			
			@synchronized(downloadedVendors) {
				[downloadedVendors removeObjectForKey:vendorID];
				if (downloadedVendors.count == 0) {
					[self completeDownload];
				}
			}
		}
	});
}

#pragma mark - Helper Methods

- (void)showErrorWithMessage:(NSString *)message {
	dispatch_async(dispatch_get_main_queue(), ^{
		UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil)
																				 message:message
																		  preferredStyle:UIAlertControllerStyleAlert];
		[alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:nil]];
		[alertController show];
	});
}

- (void)downloadProgress:(CGFloat)progress withStatus:(NSString *)status {
	dispatch_async(dispatch_get_main_queue(), ^{
		if (status != nil) {
			_account.downloadStatus = status;
		}
		_account.downloadProgress = progress;
	});
}

- (void)completeDownload {
	[self completeDownloadWithStatus:NSLocalizedString(@"Finished", nil)];
}

- (void)completeDownloadWithStatus:(NSString *)status {
	dispatch_async(dispatch_get_main_queue(), ^{
		_account.downloadStatus = status;
		_account.downloadProgress = 1.0f;
		_account.isDownloadingReports = NO;
		[UIApplication sharedApplication].idleTimerDisabled = NO;
		if (backgroundTaskID != UIBackgroundTaskInvalid) {
			[[UIApplication sharedApplication] endBackgroundTask:backgroundTaskID];
		}
	});
}

@end
