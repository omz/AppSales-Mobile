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
#import "ReporterParser.h"

// iTunes Connect Reporter API
NSString *const kITCReporterVersion            = @"2.2";
NSString *const kITCReporterMode               = @"Robot.XML";
NSString *const kITCReporterBaseURL            = @"https://reportingitc-reporter.apple.com";
NSString *const kITCReporterServiceAction      = @"/reportservice/%@/v1";
NSString *const kITCReporterServiceTypeSales   = @"sales";
NSString *const kITCReporterServiceTypeFinance = @"finance";
NSString *const kITCReporterServiceBody        = @"[p=Reporter.properties, m=Robot.XML, %@]";

static NSString *NSStringPercentEscaped(NSString *string) {
    return [string stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
}

@implementation ReportDownloadOperation

@synthesize accountObjectID;

- (instancetype)initWithAccount:(ASAccount *)account {
	self = [super init];
	if (self) {
		accessToken = [account.accessToken copy];
		providerID = [account.providerID copy];
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
        
        NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
		moc.persistentStoreCoordinator = psc;
		moc.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;

		ASAccount *account = (ASAccount *)[moc objectWithID:accountObjectID];
		NSInteger previousBadge = account.reportsBadge.integerValue;
		NSString *vendorID = account.vendorID;
		NSString *salesKey = kITCReporterServiceTypeSales.capitalizedString;

		LoginManager *loginManager = [[LoginManager alloc] initWithLoginInfo:nil];
		loginManager.shouldDeleteCookies = NO;
		[loginManager logOut];

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

			NSInteger maxNumberOfAvailableReports = [dateType isEqualToString:@"Daily"] ? 90 : 20;
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
                        NSString *status = [NSString stringWithFormat:NSLocalizedString(@"Loading daily report %i / %lu", nil), i + 1, (unsigned long)numberOfReportsAvailable];
						[self downloadProgress:progress withStatus:status];
					} else {
						CGFloat progress = 0.5f + 0.4f * ((CGFloat)i / (CGFloat)numberOfReportsAvailable);
                        NSString *status = [NSString stringWithFormat:NSLocalizedString(@"Loading weekly report %i / %lu", nil), i + 1, (unsigned long)numberOfReportsAvailable];
						[self downloadProgress:progress withStatus:status];
					}
				}

				NSString *query = [NSString stringWithFormat:@"a=%@, %@.getReport, %@,%@,Summary,%@,%@", providerID, salesKey, vendorID, salesKey, dateType, reportDateString];

				NSDictionary *getReportData = @{@"accesstoken": NSStringPercentEscaped(accessToken),
												@"version":     kITCReporterVersion,
												@"mode":        kITCReporterMode,
												@"queryInput":  NSStringPercentEscaped([NSString stringWithFormat:kITCReporterServiceBody, query]),
												@"salesurl":    NSStringPercentEscaped([kITCReporterBaseURL stringByAppendingFormat:kITCReporterServiceAction, kITCReporterServiceTypeSales]),
												@"financeurl":  NSStringPercentEscaped([kITCReporterBaseURL stringByAppendingFormat:kITCReporterServiceAction, kITCReporterServiceTypeFinance]),
												};
				NSData *jsonData = [NSJSONSerialization dataWithJSONObject:getReportData options:0 error:nil];
				NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
				NSString *getReportBody = [NSString stringWithFormat:@"jsonRequest=%@", jsonString];
				NSData *getReportBodyData = [getReportBody dataUsingEncoding:NSUTF8StringEncoding];

				NSURL *reporterURL = [NSURL URLWithString:[kITCReporterBaseURL stringByAppendingFormat:kITCReporterServiceAction, kITCReporterServiceTypeSales]];
				NSMutableURLRequest *reporterRequest = [NSMutableURLRequest requestWithURL:reporterURL];
				[reporterRequest setHTTPMethod:@"POST"];
				[reporterRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
				[reporterRequest setHTTPBody:getReportBodyData];

				NSHTTPURLResponse *response = nil;
				NSData *reportData = [NSURLConnection sendSynchronousRequest:reporterRequest returningResponse:&response error:nil];

				if ([response.MIMEType isEqualToString:@"text/plain"]) {
					ReporterParser *reporterParser = [[ReporterParser alloc] initWithData:reportData];
					[reporterParser parse];
					NSDictionary *root = reporterParser.root;
					NSDictionary *node = root[kReporterErrorKey];
					if (node != nil) {
						NSNumber *errorCode = node[kReporterCodeKey];
						NSString *errorMessage = node[kReporterMessageKey];
						if ((errorCode.integerValue != 210) && (errorMessage != nil)) {
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
						}
					}
				} else if ([response.MIMEType isEqualToString:@"application/a-gzip"]) {
					NSString *originalFilename = response.allHeaderFields[@"filename"];
					NSData *inflatedReportData = [reportData gzipInflate];
					NSString *reportCSV = [[NSString alloc] initWithData:inflatedReportData encoding:NSUTF8StringEncoding];
					if (originalFilename && (reportCSV.length > 0)) {
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
				} else {
					NSString *content = [[NSString alloc] initWithData:reportData encoding:NSUTF8StringEncoding];
					NSLog(@"Error downloading %@ report for %@.", dateType, reportDateString);
					NSLog(@"%@: %@", response.MIMEType, content);
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

- (void)loginSucceeded:(LoginManager *)loginManager {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
		@autoreleasepool {

			[self downloadProgress:0.95f withStatus:NSLocalizedString(@"Loading payments...", nil)];

			//==== Payments

			if (self.isCancelled) {
				[self completeDownloadWithStatus:NSLocalizedString(@"Canceled", nil)];
            } else if (self->providerID.length > 0) {
                NSURL *paymentVendorsURL = [NSURL URLWithString:[kITCBaseURL stringByAppendingFormat:kITCPaymentVendorsAction, self->providerID]];
                [[NSURLSession.sharedSession dataTaskWithRequest:[NSURLRequest requestWithURL:paymentVendorsURL]
                                               completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                    
                    NSDictionary *paymentVendors = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                    NSArray *sapVendors = paymentVendors[@"data"];

                    if (self.isCancelled) {
                        [self completeDownloadWithStatus:NSLocalizedString(@"Canceled", nil)];
                    } else if ((sapVendors != nil) && ![sapVendors isEqual:[NSNull null]] && (sapVendors.count > 0)) {
                        if (self->downloadedVendors == nil) {
                            self->downloadedVendors = [[NSMutableDictionary alloc] init];
                        } else {
                            [self->downloadedVendors removeAllObjects];
                        }
                        for (NSDictionary *vendor in sapVendors) {
                            NSNumber *vendorID = vendor[@"sapVendorNumber"];
                            self->downloadedVendors[vendorID.description] = @(0);
                        }
                        for (NSString *vendorID in self->downloadedVendors.allKeys) {
                            [self fetchPaymentsForVendorID:vendorID];
                        }
                    } else {
                        [self completeDownload];
                    }
                }] resume];
			}

			//==== /Payments
		}
	});
}

- (void)loginFailed:(LoginManager *)loginManager {
	[self completeDownload];
}

- (void)fetchPaymentsForVendorID:(NSString *)vendorID {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
		@autoreleasepool {

            NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
            [moc setPersistentStoreCoordinator:self->psc];
			[moc setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];

            ASAccount *account = (ASAccount *)[moc objectWithID:self->accountObjectID];

			NSMutableArray *reportsToDelete = [NSMutableArray array];
			NSMutableSet *allExistingPaymentReports = [NSMutableSet setWithSet:account.paymentReports];

			for (NSManagedObject *paymentReport in allExistingPaymentReports) {
				NSSet *payments = [paymentReport valueForKey:@"payments"];
				if (payments.count == 0) {
					[reportsToDelete addObject:paymentReport];
					continue;
				}
				for (NSManagedObject *payment in payments) {
					if ([[payment valueForKey:@"isExpected"] boolValue]) {
						NSDate *expectedPaymentDate = [payment valueForKey:@"paidOrExpectingPaymentDate"];
						if ([expectedPaymentDate compare:[NSDate date]] == NSOrderedAscending) {
							[reportsToDelete addObject:paymentReport];
							break;
						}
					}
				}
			}
			for (NSManagedObject *reportToDelete in reportsToDelete) {
				[moc deleteObject:reportToDelete];
				[allExistingPaymentReports removeObject:reportToDelete];
			}

			NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
			NSMutableSet *existingPaymentReportIdentifiers = [NSMutableSet set];
			for (NSManagedObject *paymentReport in allExistingPaymentReports) {
				NSDateComponents *dateComponents = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth) fromDate:[paymentReport valueForKey:@"reportDate"]];
				[existingPaymentReportIdentifiers addObject:[NSString stringWithFormat:@"%li-%li", (long)dateComponents.year, (long)dateComponents.month]];
			}

			NSNumberFormatter *currencyFormatter = [[NSNumberFormatter alloc] init];
			currencyFormatter.numberStyle = NSNumberFormatterDecimalStyle;
			currencyFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];

			NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
			[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];

			NSDate *currDate = [NSDate date];
			NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
			offsetComponents.month = -1;

			while (YES) {
				currDate = [calendar dateByAddingComponents:offsetComponents toDate:currDate options:0];

				NSDateComponents *dateComponents = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth) fromDate:currDate];
				NSInteger year = dateComponents.year;
				NSInteger month = dateComponents.month;

				NSString *paymentReportIdentifier = [NSString stringWithFormat:@"%li-%li", (long)year, (long)month];
				if ([existingPaymentReportIdentifiers containsObject:paymentReportIdentifier]) {
					// We've already been here before, so bail out.
					break;
				}

                NSURL *paymentURL = [NSURL URLWithString:[kITCBaseURL stringByAppendingFormat:kITCPaymentVendorsPaymentAction, self->providerID, vendorID, year, month]];
				NSData *paymentData = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:paymentURL] returningResponse:nil error:nil];
				NSDictionary *payment = [NSJSONSerialization JSONObjectWithData:paymentData options:0 error:nil];
				payment = payment[@"data"];
				NSDate *paymentReportDate = [dateFormatter dateFromString:payment[@"reportDate"]];
				NSArray *paymentSummaries = payment[@"reportSummaries"];

				if (self.isCancelled) {
					[self completeDownloadWithStatus:NSLocalizedString(@"Canceled", nil)];
					break;
				} else if ((paymentSummaries == nil) || [paymentSummaries isEqual:[NSNull null]] || (paymentSummaries.count == 0)) {
                    @synchronized(self->downloadedVendors) {
                        NSInteger count = [self->downloadedVendors[vendorID] integerValue];
						count++;
                        self->downloadedVendors[vendorID] = @(count);
						// Bail out if there are no payments for over 12 consecutive months.
						if (count > 12) { break; }
					}
				} else {
                    @synchronized(self->downloadedVendors) {
                        self->downloadedVendors[vendorID] = @(0);
					}
					NSManagedObject *paymentReport = [NSEntityDescription insertNewObjectForEntityForName:@"PaymentReport" inManagedObjectContext:moc];
					[paymentReport setValue:paymentReportDate forKey:@"reportDate"];
					[paymentReport setValue:account forKey:@"account"];

					BOOL hasOnePaymentSummary = NO;
					for (NSDictionary *payment in paymentSummaries) {
						if (payment[@"paidOrExpectingPaymentDate"] == [NSNull null]) {
							continue;
						}
						NSDate *paidOrExpectedDate = [dateFormatter dateFromString:payment[@"paidOrExpectingPaymentDate"]];
						if (paidOrExpectedDate == nil) {
							// This payment is neither paid nor expected. Ignore it.
							continue;
						}
						hasOnePaymentSummary = YES;
						NSManagedObject *paymentDetailed = [NSEntityDescription insertNewObjectForEntityForName:@"PaymentDetailed" inManagedObjectContext:moc];
						CGFloat amount = [currencyFormatter numberFromString:payment[@"amount"]].floatValue;
						[paymentDetailed setValue:@(amount) forKey:@"amount"];
						[paymentDetailed setValue:payment[@"currency"] forKey:@"currency"];
						[paymentDetailed setValue:payment[@"bankName"] forKey:@"bankName"];
						[paymentDetailed setValue:payment[@"isPaymentExpected"] forKey:@"isExpected"];
						[paymentDetailed setValue:payment[@"maskedBankAccount"] forKey:@"maskedBankAccount"];
						[paymentDetailed setValue:paidOrExpectedDate forKey:@"paidOrExpectingPaymentDate"];
						[paymentDetailed setValue:payment[@"status"] forKey:@"status"];
						[paymentDetailed setValue:paymentReport forKey:@"paymentReport"];
					}
					if (!hasOnePaymentSummary) {
						[moc deleteObject:paymentReport];
						continue;
					}
					account.paymentsBadge = @(account.paymentsBadge.integerValue + 1);

					if ([moc hasChanges]) {
                        [self->psc performBlockAndWait:^{
							NSError *saveError = nil;
							[moc save:&saveError];
							if (saveError) {
								NSLog(@"Could not save context: %@", saveError);
							}
						}];
					}
				}
			}

            @synchronized(self->downloadedVendors) {
                [self->downloadedVendors removeObjectForKey:vendorID];
                if (self->downloadedVendors.count == 0) {
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
            self->_account.downloadStatus = status;
		}
        self->_account.downloadProgress = progress;
	});
}

- (void)completeDownload {
	[self completeDownloadWithStatus:NSLocalizedString(@"Finished", nil)];
}

- (void)completeDownloadWithStatus:(NSString *)status {
	dispatch_async(dispatch_get_main_queue(), ^{
        self->_account.downloadStatus = status;
        self->_account.downloadProgress = 1.0f;
        self->_account.isDownloadingReports = NO;
		[UIApplication sharedApplication].idleTimerDisabled = NO;
        if (self->backgroundTaskID != UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication] endBackgroundTask:self->backgroundTaskID];
		}
	});
}

@end
