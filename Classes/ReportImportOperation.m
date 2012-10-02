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

+ (BOOL)filesAvailableToImport
{
	NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
	NSFileManager *fm = [[[NSFileManager alloc] init] autorelease];
	NSArray *filenames = [fm contentsOfDirectoryAtPath:docPath error:NULL];
	for (NSString *filename in filenames) {
		if ([[filename pathExtension] isEqualToString:@"txt"]) {
			return YES;
		}
	}
	return NO;
}

- (id)initWithAccount:(ASAccount *)account
{
	self = [super init];
	if (self) {
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
		_account.downloadStatus = NSLocalizedString(@"Starting import", nil);
		_account.downloadProgress = 0.0;
	});
	
	NSManagedObjectContext *moc = [[[NSManagedObjectContext alloc] init] autorelease];
	[moc setPersistentStoreCoordinator:psc];
	[moc setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
	
	ASAccount *account = (ASAccount *)[moc objectWithID:accountObjectID];
	NSInteger numberOfReportsImported = 0;
	NSInteger i = 0;
	
	NSFetchRequest *existingDailyReportsRequest = [[[NSFetchRequest alloc] init] autorelease];
	[existingDailyReportsRequest setEntity:[NSEntityDescription entityForName:@"DailyReport" inManagedObjectContext:moc]];
	[existingDailyReportsRequest setPredicate:[NSPredicate predicateWithFormat:@"account == %@", account]];
	[existingDailyReportsRequest setPropertiesToFetch:[NSArray arrayWithObject:@"startDate"]];
	[existingDailyReportsRequest setResultType:NSDictionaryResultType];
	NSArray *existingDailyReportDates = [[moc executeFetchRequest:existingDailyReportsRequest error:NULL] valueForKey:@"startDate"];
	NSMutableSet *existingDailyReportDatesSet = [NSMutableSet setWithArray:existingDailyReportDates];
	
	NSFetchRequest *existingWeeklyReportsRequest = [[[NSFetchRequest alloc] init] autorelease];
	[existingWeeklyReportsRequest setEntity:[NSEntityDescription entityForName:@"WeeklyReport" inManagedObjectContext:moc]];
	[existingWeeklyReportsRequest setPredicate:[NSPredicate predicateWithFormat:@"account == %@", account]];
	[existingWeeklyReportsRequest setPropertiesToFetch:[NSArray arrayWithObject:@"startDate"]];
	[existingWeeklyReportsRequest setResultType:NSDictionaryResultType];
	NSArray *existingWeeklyReportDates = [[moc executeFetchRequest:existingWeeklyReportsRequest error:NULL] valueForKey:@"startDate"];
	NSMutableSet *existingWeeklyReportDatesSet = [NSMutableSet setWithArray:existingWeeklyReportDates];
	
	NSString *docPath = nil;
	if (self.importDirectory) {
		docPath = [[self.importDirectory retain] autorelease];
	} else {
		docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
	}
	NSFileManager *fm = [[[NSFileManager alloc] init] autorelease];
	NSArray *fileNames = [fm contentsOfDirectoryAtPath:docPath error:NULL];
	
	dispatch_async(dispatch_get_main_queue(), ^ {
		_account.downloadStatus = [NSString stringWithFormat:NSLocalizedString(@"Processing files (0/%i)...", nil), [fileNames count]];
		_account.downloadProgress = 0.0;
	});
	
	for (NSString *fileName in fileNames) {
		NSAutoreleasePool *innerPool = [NSAutoreleasePool new];
		if (![[fileName pathExtension] isEqualToString:@"txt"] && ![fileName hasSuffix:@"txt.gz"]) {
			[innerPool release];
			continue;
		}
		NSString *fullPath = [docPath stringByAppendingPathComponent:fileName];
		NSString *reportCSV = nil;
		if ([[fullPath pathExtension] isEqualToString:@"gz"]) {
			NSData *gzData = [[[NSData alloc] initWithContentsOfFile:fullPath] autorelease];
			NSData *inflatedData = [gzData gzipInflate];
			reportCSV = [[[NSString alloc] initWithData:inflatedData encoding:NSUTF8StringEncoding] autorelease];
			if (!reportCSV) reportCSV = [[[NSString alloc] initWithData:inflatedData encoding:NSISOLatin1StringEncoding] autorelease];
		} else {
			reportCSV = [[[NSString alloc] initWithContentsOfFile:fullPath encoding:NSUTF8StringEncoding error:NULL] autorelease];
			if (!reportCSV) reportCSV = [[[NSString alloc] initWithContentsOfFile:fullPath encoding:NSISOLatin1StringEncoding error:NULL] autorelease];
		}
		
		NSDictionary *reportInfo = [Report infoForReportCSV:reportCSV];
		if (reportInfo) {
			NSDate *reportDate = [reportInfo objectForKey:kReportInfoDate];
			NSMutableSet *existingDates = nil;
			if ([[reportInfo objectForKey:kReportInfoClass] isEqualToString:kReportInfoClassDaily]) {
				existingDates = existingDailyReportDatesSet;
			} else if ([[reportInfo objectForKey:kReportInfoClass] isEqualToString:kReportInfoClassWeekly]) {
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
					[psc lock];
					NSError *saveError = nil;
					[moc save:&saveError];
					if (saveError) {
						NSLog(@"Could not save context: %@", saveError);
					}
					[psc unlock];
					if (i % 10 == 0) {
						//Reset the context periodically to avoid excessive memory growth:
						[moc reset];
						account = (ASAccount *)[moc objectWithID:accountObjectID];
					}
					if (!saveError && deleteOriginalFilesAfterImport) {
						[fm removeItemAtPath:fullPath error:NULL];
					}
				}
			}
		}
		
		dispatch_async(dispatch_get_main_queue(), ^ {
			float progress = (float)i / (float)[fileNames count];
			_account.downloadStatus = [NSString stringWithFormat:NSLocalizedString(@"Processing files (%i/%i)...", nil), i, [fileNames count]];
			_account.downloadProgress = progress;
		});
		
		[innerPool release];
		i++;
	}
	
	dispatch_async(dispatch_get_main_queue(), ^ {
		_account.downloadStatus = [NSString stringWithFormat:NSLocalizedString(@"Finished (%i imported)", nil), numberOfReportsImported];
		_account.downloadProgress = 1.0;
	});
	[pool release];
}

- (void)dealloc
{
	[_account release];
	[psc release];
	[accountObjectID release];
	[super dealloc];
}

@end
