//
//  ReportImportOperation.m
//  AppSales
//
//  Created by Ole Zorn on 09.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "ReportImportOperation.h"
#import "ASAccount.h"
#import "Report.h"
#import "NSData+Compression.h"

@implementation ReportImportOperation

@synthesize importDirectory, deleteOriginalFilesAfterImport;

+ (BOOL)filesAvailableToImport {
	NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
	NSFileManager *fm = [[NSFileManager alloc] init];
	NSArray *filenames = [fm contentsOfDirectoryAtPath:docPath error:nil];
	for (NSString *filename in filenames) {
		if ([[filename pathExtension] isEqualToString:@"txt"]) {
			return YES;
		}
	}
	return NO;
}

- (instancetype)initWithAccount:(ASAccount *)account {
	self = [super init];
	if (self) {
		_account = account;
		accountObjectID = [[account objectID] copy];
		psc = [[account managedObjectContext] persistentStoreCoordinator];
	}
	return self;
}

- (void)main {
	@autoreleasepool {
	
		dispatch_async(dispatch_get_main_queue(), ^{
            self->_account.downloadStatus = NSLocalizedString(@"Starting import", nil);
            self->_account.downloadProgress = 0.0;
		});
		
        NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
		[moc setPersistentStoreCoordinator:psc];
		[moc setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
		
		ASAccount *account = (ASAccount *)[moc objectWithID:accountObjectID];
		NSInteger numberOfReportsImported = 0;
		NSInteger i = 0;
		
		NSFetchRequest *existingDailyReportsRequest = [[NSFetchRequest alloc] init];
		[existingDailyReportsRequest setEntity:[NSEntityDescription entityForName:@"DailyReport" inManagedObjectContext:moc]];
		[existingDailyReportsRequest setPredicate:[NSPredicate predicateWithFormat:@"account == %@", account]];
		[existingDailyReportsRequest setPropertiesToFetch:@[@"startDate"]];
		[existingDailyReportsRequest setResultType:NSDictionaryResultType];
		NSArray *existingDailyReportDates = [[moc executeFetchRequest:existingDailyReportsRequest error:nil] valueForKey:@"startDate"];
		NSMutableSet *existingDailyReportDatesSet = [NSMutableSet setWithArray:existingDailyReportDates];
		
		NSFetchRequest *existingWeeklyReportsRequest = [[NSFetchRequest alloc] init];
		[existingWeeklyReportsRequest setEntity:[NSEntityDescription entityForName:@"WeeklyReport" inManagedObjectContext:moc]];
		[existingWeeklyReportsRequest setPredicate:[NSPredicate predicateWithFormat:@"account == %@", account]];
		[existingWeeklyReportsRequest setPropertiesToFetch:@[@"startDate"]];
		[existingWeeklyReportsRequest setResultType:NSDictionaryResultType];
		NSArray *existingWeeklyReportDates = [[moc executeFetchRequest:existingWeeklyReportsRequest error:nil] valueForKey:@"startDate"];
		NSMutableSet *existingWeeklyReportDatesSet = [NSMutableSet setWithArray:existingWeeklyReportDates];
		
		NSString *docPath = nil;
		if (self.importDirectory) {
			docPath = self.importDirectory;
		} else {
			docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
		}
		NSFileManager *fm = [[NSFileManager alloc] init];
		NSArray *fileNames = [fm contentsOfDirectoryAtPath:docPath error:nil];
		
		dispatch_async(dispatch_get_main_queue(), ^{
            self->_account.downloadStatus = [NSString stringWithFormat:NSLocalizedString(@"Processing files (0/%lu)...", nil), (unsigned long)[fileNames count]];
            self->_account.downloadProgress = 0.0;
		});
		
		for (NSString *fileName in fileNames) {
			@autoreleasepool {
				if (![[fileName pathExtension] isEqualToString:@"txt"] && ![fileName hasSuffix:@"txt.gz"]) {
					continue;
				}
				NSString *fullPath = [docPath stringByAppendingPathComponent:fileName];
				NSString *reportCSV = nil;
				if ([[fullPath pathExtension] isEqualToString:@"gz"]) {
					NSData *gzData = [[NSData alloc] initWithContentsOfFile:fullPath];
					NSData *inflatedData = [gzData gzipInflate];
					reportCSV = [[NSString alloc] initWithData:inflatedData encoding:NSUTF8StringEncoding];
					if (!reportCSV) reportCSV = [[NSString alloc] initWithData:inflatedData encoding:NSISOLatin1StringEncoding];
				} else {
					reportCSV = [[NSString alloc] initWithContentsOfFile:fullPath encoding:NSUTF8StringEncoding error:nil];
					if (!reportCSV) reportCSV = [[NSString alloc] initWithContentsOfFile:fullPath encoding:NSISOLatin1StringEncoding error:nil];
				}
				
				NSDictionary *reportInfo = [Report infoForReportCSV:reportCSV];
				if (reportInfo) {
					NSDate *reportDate = reportInfo[kReportInfoDate];
					NSMutableSet *existingDates = nil;
					if ([reportInfo[kReportInfoClass] isEqualToString:kReportInfoClassDaily]) {
						existingDates = existingDailyReportDatesSet;
					} else if ([reportInfo[kReportInfoClass] isEqualToString:kReportInfoClassWeekly]) {
						existingDates = existingWeeklyReportDatesSet;
					}
					if (![existingDates containsObject:reportDate]) {
						Report *report = [Report insertNewReportWithCSV:reportCSV inAccount:account];
						if (report) {
							[existingDates addObject:reportDate];
							NSManagedObject *originalReport = [NSEntityDescription insertNewObjectForEntityForName:@"ReportCSV" inManagedObjectContext:moc];
							[originalReport setValue:reportCSV forKey:@"content"];
							[originalReport setValue:report forKey:@"report"];
							[originalReport setValue:fileName forKey:@"filename"];
							
							[report generateCache];
							
							numberOfReportsImported++;
							__block NSError *saveError = nil;
							[psc performBlockAndWait:^{
								[moc save:&saveError];
								if (saveError) {
									NSLog(@"Could not save context: %@", saveError);
								}
							}];
							if (i % 10 == 0) {
								// Reset the context periodically to avoid excessive memory growth:
								[moc reset];
								account = (ASAccount *)[moc objectWithID:accountObjectID];
							}
							if (!saveError && deleteOriginalFilesAfterImport) {
								[fm removeItemAtPath:fullPath error:nil];
							}
						}
					}
				}
				
				dispatch_async(dispatch_get_main_queue(), ^{
					float progress = (float)i / (float)[fileNames count];
                    self->_account.downloadStatus = [NSString stringWithFormat:NSLocalizedString(@"Processing files (%li/%lu)...", nil), (long)i, (unsigned long)[fileNames count]];
                    self->_account.downloadProgress = progress;
				});
			
			}
			i++;
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{
            self->_account.downloadStatus = [NSString stringWithFormat:NSLocalizedString(@"Finished (%li imported)", nil), (long)numberOfReportsImported];
            self->_account.downloadProgress = 1.0;
		});
	}
}

@end
