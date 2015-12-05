//
//  ReviewDownloadManager.m
//  AppSales
//
//  Created by Ole Zorn on 27.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "ReviewDownloadManager.h"
#import "Product.h"
#import "Review.h"

#define MAX_CONCURRENT_REVIEW_DOWNLOADS 5

@interface ReviewDownloadManager ()

- (void)dequeueDownload;

@end

@implementation ReviewDownloadManager

- (id)init {
	self = [super init];
	if (self) {
		activeDownloads = [NSMutableSet new];
		downloadQueue = [NSMutableArray new];
	}
	return self;
}

+ (id)sharedManager {
	static id sharedManager = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedManager = [[self alloc] init];
	});
	return sharedManager;
}

- (void)downloadReviewsForProducts:(NSArray *)products {
	if ([activeDownloads count] > 0 || [downloadQueue count] > 0) return;
	
	NSArray *stores = [[NSArray alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"stores" ofType:@"plist"]];
	for (NSString *country in stores) {
		for (Product *product in products) {
			ReviewDownload *download = [[ReviewDownload alloc] initWithProduct:product countryCode:country];
			download.delegate = self;
			[downloadQueue addObject:download];
		}
	}
	
	totalDownloadsCount = [downloadQueue count];
	completedDownloadsCount = 0;
	[[NSNotificationCenter defaultCenter] postNotificationName:ReviewDownloadManagerDidUpdateProgressNotification object:self];
	[self dequeueDownload];
}

- (void)cancelAllDownloads {
	[downloadQueue removeAllObjects];
	for (ReviewDownload *download in activeDownloads) {
		[download cancel];
	}
	[activeDownloads removeAllObjects];
	completedDownloadsCount = 0;
	totalDownloadsCount = 0;
	[[NSNotificationCenter defaultCenter] postNotificationName:ReviewDownloadManagerDidUpdateProgressNotification object:self];
}

- (void)dequeueDownload {
	if ([downloadQueue count] == 0) return;
	if ([activeDownloads count] >= MAX_CONCURRENT_REVIEW_DOWNLOADS) return;
	
	ReviewDownload *nextDownload = [downloadQueue objectAtIndex:0];
	[downloadQueue removeObjectAtIndex:0];
	[activeDownloads addObject:nextDownload];
	[nextDownload start];
	
	[self dequeueDownload];
}

- (void)reviewDownloadDidFinish:(ReviewDownload *)download {
	[activeDownloads removeObject:download];
	completedDownloadsCount++;
	[[NSNotificationCenter defaultCenter] postNotificationName:ReviewDownloadManagerDidUpdateProgressNotification object:self];
	[self dequeueDownload];
}

- (BOOL)isDownloading {
	return [downloadQueue count] != 0 || [activeDownloads count] != 0;
}

- (float)downloadProgress {
	float progress = (totalDownloadsCount == 0) ? 1.0 : (float)completedDownloadsCount / (float)totalDownloadsCount;
	return progress;
}

@end



@implementation ReviewDownload

@synthesize delegate, downloadConnection;

- (id)initWithProduct:(Product *)app countryCode:(NSString *)countryCode {
	self = [super init];
	if (self) {
		_product = app;
		country = countryCode;
		productObjectID = [[app objectID] copy];
		psc = [[app managedObjectContext] persistentStoreCoordinator];
		data = [NSMutableData new];
		page = 1;
	}
	return self;
}

- (void)start {
	backgroundTaskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
	NSString *productID = _product.productID;
	NSString *URLString = [NSString stringWithFormat:@"https://itunes.apple.com/%@/rss/customerreviews/page=%ld/id=%@/sortby=mostrecent/xml?urlDesc=/customerreviews/id=%@/sortBy=mostRecent/xml", country, (long)page, productID, productID];
	NSURL *URL = [NSURL URLWithString:URLString];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
	self.downloadConnection = [NSURLConnection connectionWithRequest:request delegate:self];
}

- (void)cancel {
	if (backgroundTaskID != UIBackgroundTaskInvalid) {
		[[UIApplication sharedApplication] endBackgroundTask:backgroundTaskID];
	}
	canceled = YES;
	[self.downloadConnection cancel];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)dataChunk {
	[data appendData:dataChunk];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
		ReviewsParser *parser = [[ReviewsParser alloc] initWithData:data];
		[parser parse];
		if (parser.reviews.count > 0) {
			NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] init];
			[moc setPersistentStoreCoordinator:psc];
			[moc setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
			Product *product = (Product *)[moc objectWithID:productObjectID];
			
			NSSet *downloadedUsers = [NSSet setWithArray:[parser.reviews valueForKey:kReviewAuthorNameKey]];
			
			// Fetch existing reviews, based on username and country.
			NSFetchRequest *existingReviewsFetchRequest = [[NSFetchRequest alloc] init];
			[existingReviewsFetchRequest setEntity:[NSEntityDescription entityForName:@"Review" inManagedObjectContext:moc]];
			[existingReviewsFetchRequest setPredicate:[NSPredicate predicateWithFormat:@"product == %@ AND countryCode == %@ AND user IN %@", product, country, downloadedUsers]];
			NSArray *existingReviews = [moc executeFetchRequest:existingReviewsFetchRequest error:NULL];
			NSMutableDictionary *existingReviewsByUser = [NSMutableDictionary dictionary];
			for (Review *existingReview in existingReviews) {
				[existingReviewsByUser setObject:existingReview forKey:existingReview.user];
			}
			
			BOOL changesMade = NO;
			for (NSDictionary *reviewInfo in parser.reviews) {
				Review *existingReview = [existingReviewsByUser objectForKey:[reviewInfo objectForKey:kReviewAuthorNameKey]];
				
				// CREATE REVIEW DATE BY COMPONENTS
				NSInteger year = [[[reviewInfo objectForKey:kReviewUpdatedKey] substringToIndex:4] intValue];
				NSString *temp1 = [[reviewInfo objectForKey:kReviewUpdatedKey] substringWithRange:NSMakeRange(5, 5)];
				NSInteger month = [[temp1 substringToIndex:2] intValue];
				NSInteger day = [[temp1 substringFromIndex:3] intValue];
				
				// Combine date and time into components.
				NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
				NSDateComponents *components = [[NSDateComponents alloc] init];
				[components setYear:year];
				[components setMonth:month];
				[components setDay:day];
				[components setHour:12];
				[components setMinute:0];
				[components setSecond:0];
				
				// Generate a new NSDate from components.
				NSDate *reviewDate = [gregorianCalendar dateFromComponents:components];
				
				if (!existingReview) {
					Review *newReview = [NSEntityDescription insertNewObjectForEntityForName:@"Review" inManagedObjectContext:moc];
					newReview.user = [reviewInfo objectForKey:kReviewAuthorNameKey];
					newReview.title = [reviewInfo objectForKey:kReviewTitleKey];
					newReview.text = [reviewInfo objectForKey:kReviewContentKey];
					newReview.rating = [reviewInfo objectForKey:kReviewRatingKey];
					newReview.downloadDate = [NSDate date];
					newReview.productVersion = [reviewInfo objectForKey:kReviewVersionKey];
					newReview.product = product;
					newReview.countryCode = country;
					newReview.unread = [NSNumber numberWithBool:YES];
					newReview.reviewDate = reviewDate;
					
					[existingReviewsByUser setObject:newReview forKey:newReview.user];
					changesMade = YES;
				} else {
					NSString *existingText = existingReview.text;
					NSString *existingTitle = existingReview.title;
					NSNumber *existingRating = existingReview.rating;
					NSString *newText = [reviewInfo objectForKey:kReviewContentKey];
					NSString *newTitle = [reviewInfo objectForKey:kReviewTitleKey];
					NSNumber *newRating = [reviewInfo objectForKey:kReviewRatingKey];
					
					if (![existingText isEqualToString:newText] || ![existingTitle isEqualToString:newTitle] || ![existingRating isEqualToNumber:newRating]) {
						existingReview.text = newText;
						existingReview.title = newTitle;
						existingReview.rating = newRating;
						existingReview.downloadDate = [NSDate date];
						existingReview.reviewDate = reviewDate;
						changesMade = YES;
					}
				}
			}
			
			[psc performBlockAndWait:^{
				NSError *saveError = nil;
				[moc save:&saveError];
				if (saveError) {
					NSLog(@"Could not save context: %@", saveError);
				}
			}];
			
			if (changesMade && (parser.reviews.count >= 20)) {
				dispatch_async(dispatch_get_main_queue(), ^{
					page++;
					[self start];
				});
			} else {
				dispatch_async(dispatch_get_main_queue(), ^{
					if (!canceled) {
						[self.delegate reviewDownloadDidFinish:self];
					}
				});
			}
		} else {
			dispatch_async(dispatch_get_main_queue(), ^{
				if (!canceled) {
					[self.delegate reviewDownloadDidFinish:self];
				}
			});
		}
	});
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	if (backgroundTaskID != UIBackgroundTaskInvalid) {
		[[UIApplication sharedApplication] endBackgroundTask:backgroundTaskID];
	}
	[self.delegate reviewDownloadDidFinish:self];
}

@end
