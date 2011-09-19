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
#import "LKGoogleTranslator.h"

#define kReviewInfoTitle		@"title"
#define kReviewInfoUser			@"user"
#define kReviewInfoDateString	@"dateString"
#define kReviewInfoRating		@"rating"
#define kReviewInfoVersion		@"version"
#define kReviewInfoText			@"text"

#define MAX_CONCURRENT_REVIEW_DOWNLOADS		5

@interface ReviewDownloadManager ()

- (void)dequeueDownload;

@end

@implementation ReviewDownloadManager

- (id)init
{
	self = [super init];
	if (self) {
		activeDownloads = [NSMutableSet new];
		downloadQueue = [NSMutableArray new];
	}
	return self;
}

+ (id)sharedManager
{
	static id sharedManager = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedManager = [[self alloc] init];
	});
	return sharedManager;
}

- (void)downloadReviewsForProducts:(NSArray *)products
{
	if ([activeDownloads count] > 0 || [downloadQueue count] > 0) return;
	
	NSDictionary *storeInfos = [[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"stores" ofType:@"plist"]] objectForKey:@"StoreInfos"];
	for (NSString *country in storeInfos) {
		NSDictionary *storeInfo = [storeInfos objectForKey:country];
		NSString *storeID = [storeInfo objectForKey:@"storeID"];
		for (Product *product in products) {
			if (product.parentSKU) continue; //don't download reviews for in-app-purchases
			ReviewDownload *download = [[[ReviewDownload alloc] initWithProduct:product storeFront:storeID countryCode:country] autorelease];
			download.delegate = self;
			[downloadQueue addObject:download];
		}
	}
	totalDownloadsCount = [downloadQueue count];
	completedDownloadsCount = 0;
	[[NSNotificationCenter defaultCenter] postNotificationName:ReviewDownloadManagerDidUpdateProgressNotification object:self];
	[self dequeueDownload];
}

- (void)cancelAllDownloads
{
	[downloadQueue removeAllObjects];
	for (ReviewDownload *download in activeDownloads) {
		[download cancel];
	}
	[activeDownloads removeAllObjects];
	completedDownloadsCount = 0;
	totalDownloadsCount = 0;
	[[NSNotificationCenter defaultCenter] postNotificationName:ReviewDownloadManagerDidUpdateProgressNotification object:self];
}

- (void)dequeueDownload
{
	if ([downloadQueue count] == 0) return;
	if ([activeDownloads count] >= MAX_CONCURRENT_REVIEW_DOWNLOADS) return;
	
	ReviewDownload *nextDownload = [[downloadQueue objectAtIndex:0] retain];
	[downloadQueue removeObjectAtIndex:0];
	[activeDownloads addObject:nextDownload];
	[nextDownload start];
    [nextDownload release];
	
	[self dequeueDownload];
}

- (void)reviewDownloadDidFinish:(ReviewDownload *)download
{
	[activeDownloads removeObject:download];
	completedDownloadsCount++;
	[[NSNotificationCenter defaultCenter] postNotificationName:ReviewDownloadManagerDidUpdateProgressNotification object:self];
	[self dequeueDownload];
}

- (BOOL)isDownloading
{
	return [downloadQueue count] != 0 || [activeDownloads count] != 0;
}

- (float)downloadProgress
{
	float progress = (totalDownloadsCount == 0) ? 1.0 : (float)completedDownloadsCount / (float)totalDownloadsCount;
	return progress;
}

- (void)dealloc
{
	[activeDownloads release];
	[downloadQueue release];
	[super dealloc];
}

@end



@implementation ReviewDownload

@synthesize delegate;

- (id)initWithProduct:(Product *)app storeFront:(NSString *)storeFrontID countryCode:(NSString *)countryCode
{
	self = [super init];
	if (self) {
		_product = [app retain];
		country = [countryCode retain];
		productObjectID = [[app objectID] copy];
		psc = [[[app managedObjectContext] persistentStoreCoordinator] retain];
		storeFront = [storeFrontID retain];
		page = 1;
        backgroundTaskID = UIBackgroundTaskInvalid;
	}
	return self;
}

- (void)start
{
    if (canceled) {
        return;
    }
    // method may be called by connectionDidFinishLoading, and don't want to clobber the existing taskID
    if (backgroundTaskID == UIBackgroundTaskInvalid) {
        backgroundTaskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
    }
    [data release]; // release fields from potential previous page downloads
    data = [NSMutableData new];
	
	NSString *productID = _product.productID;
	NSString *URLString = [[NSString alloc] initWithFormat:@"http://itunes.apple.com/WebObjects/MZStore.woa/wa/customerReviews?s=%@&id=%@&displayable-kind=11&page=%i&sort=4", storeFront, productID, page];
	NSURL *URL = [[NSURL alloc] initWithString:URLString];
    [URLString release];
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL];
    [URL release];
	[request setValue:@"iTunes/10.1.1 (Macintosh; Intel Mac OS X 10.6.5) AppleWebKit/533.19.4" forHTTPHeaderField:@"User-Agent"];
	[request setValue:[NSString stringWithFormat:@"%@-1,12", storeFront] forHTTPHeaderField:@"X-Apple-Store-Front"];
	
    [downloadConnection release];
    downloadConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [request release];
}

- (void)endBackgroundTask
{
    if (backgroundTaskID != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskID];
        backgroundTaskID = UIBackgroundTaskInvalid;
    }
}

- (void)cancel
{
    [self endBackgroundTask];
	canceled = YES;
	[downloadConnection cancel];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)dataChunk
{
	[data appendData:dataChunk];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSString *html = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	if (html) {
		dispatch_async(dispatch_get_global_queue(0, 0), ^ {
			NSArray *reviewInfos = [self reviewInfosFromHTML:html];
			
			NSManagedObjectContext *moc = [[[NSManagedObjectContext alloc] init] autorelease];
			[moc setPersistentStoreCoordinator:psc];
			[moc setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
			Product *product = (Product *)[moc objectWithID:productObjectID];
			
			NSDateFormatter *reviewDateFormatter = [[[NSDateFormatter alloc] init] autorelease];
			[reviewDateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
			if ([country isEqualToString:@"fr"]) {
				NSLocale *frLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"fr"] autorelease];
				[reviewDateFormatter setLocale:frLocale];
				[reviewDateFormatter setDateFormat:@"dd MMM yyyy"];
			} else if ([country isEqualToString:@"de"]) {
				NSLocale *deLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"de"] autorelease];
				[reviewDateFormatter setLocale:deLocale];
				[reviewDateFormatter setDateFormat:@"dd.MM.yyyy"];
			} else if ([country isEqualToString:@"it"]) {
				NSLocale *itLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"it"] autorelease];
				[reviewDateFormatter setLocale:itLocale];
				[reviewDateFormatter setDateFormat:@"dd-MMM-yyyy"];
			} else if ([country isEqualToString:@"us"]) {
				NSLocale *usLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en-us"] autorelease];
				[reviewDateFormatter setLocale:usLocale];
				[reviewDateFormatter setDateFormat:@"MMM dd, yyyy"];
			} else {
				NSLocale *usLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en-us"] autorelease];
				[reviewDateFormatter setDateFormat:@"dd-MMM-yyyy"];
				[reviewDateFormatter setLocale:usLocale];
			}
			
			NSSet *downloadedUsers = [NSSet setWithArray:[reviewInfos valueForKey:kReviewInfoUser]];
			
			//Fetch existing reviews, based on username and country:
			NSFetchRequest *existingReviewsFetchRequest = [[[NSFetchRequest alloc] init] autorelease];
			[existingReviewsFetchRequest setEntity:[NSEntityDescription entityForName:@"Review" inManagedObjectContext:moc]];
			[existingReviewsFetchRequest setPredicate:[NSPredicate predicateWithFormat:@"product == %@ AND countryCode == %@ AND user IN %@", product, country, downloadedUsers]];
			NSArray *existingReviews = [moc executeFetchRequest:existingReviewsFetchRequest error:NULL];
			NSMutableDictionary *existingReviewsByUser = [NSMutableDictionary dictionaryWithCapacity:existingReviews.count];
			for (Review *existingReview in existingReviews) {
				[existingReviewsByUser setObject:existingReview forKey:existingReview.user];
			}
			
			BOOL changesMade = NO;
            NSDate *today = [NSDate date];
            NSNumber *yesObject = [NSNumber numberWithBool:YES];
            NSMutableArray *updatedOrNewReviews = [NSMutableArray array];
			for (NSDictionary *reviewInfo in [reviewInfos reverseObjectEnumerator]) {
				Review *existingReview = [existingReviewsByUser objectForKey:[reviewInfo objectForKey:kReviewInfoUser]];
				if (!existingReview) {
					Review *newReview = [NSEntityDescription insertNewObjectForEntityForName:@"Review" inManagedObjectContext:moc];
					newReview.user = [reviewInfo objectForKey:kReviewInfoUser];
					newReview.title = [reviewInfo objectForKey:kReviewInfoTitle];
					newReview.text = [reviewInfo objectForKey:kReviewInfoText];
					newReview.rating = [reviewInfo objectForKey:kReviewInfoRating];
					newReview.productVersion = [reviewInfo objectForKey:kReviewInfoVersion];
					newReview.downloadDate = today;
					newReview.product = product;
					newReview.countryCode = country;
					newReview.unread = yesObject;
					newReview.reviewDate = [reviewDateFormatter dateFromString:[reviewInfo objectForKey:kReviewInfoDateString]];
					[existingReviewsByUser setObject:newReview forKey:newReview.user];
                    [updatedOrNewReviews addObject:newReview];
					changesMade = YES;
				} else {
					NSString *existingText = existingReview.text;
					NSString *existingTitle = existingReview.title;
					NSNumber *existingRating = existingReview.rating;
					NSString *newText = [reviewInfo objectForKey:kReviewInfoText];
					NSString *newTitle = [reviewInfo objectForKey:kReviewInfoTitle];
					NSNumber *newRating = [reviewInfo objectForKey:kReviewInfoRating];
					if (![existingText isEqualToString:newText] || ![existingTitle isEqualToString:newTitle] || ![existingRating isEqualToNumber:newRating]) {
						existingReview.text = newText;
						existingReview.title = newTitle;
						existingReview.rating = newRating;
                        [updatedOrNewReviews addObject:existingReview];
						changesMade = YES;
					}
				}
			}
            
            if (updatedOrNewReviews.count) {
                // update translations
                NSMutableArray *textToTranslate = [NSMutableArray arrayWithCapacity:2*updatedOrNewReviews.count];
                for (Review *rev in updatedOrNewReviews) {
                    [textToTranslate addObject:rev.title];
                    [textToTranslate addObject:rev.text];
                }
                LKGoogleTranslator *translator = [[LKGoogleTranslator new] autorelease];
                NSString *presentationLanguage = [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode];
                NSArray *translated = [translator translateMultipleText:textToTranslate toLanguage:presentationLanguage];
                
                for (NSUInteger i=0, count=updatedOrNewReviews.count; i < count; i++) {
                    Review *review = [updatedOrNewReviews objectAtIndex:i];
                    review.title = [translated objectAtIndex:2*i];
                    review.text = [translated objectAtIndex:2*i+1];
                }
            }
            
			
            if (changesMade) {
                [psc lock];
                NSError *saveError = nil;
                [moc save:&saveError];
                if (saveError) {
                    NSLog(@"Could not save context: %@", saveError);
                }
                [psc unlock];
            }
			
            const NSUInteger NUM_REVIEWS_PER_PAGE = 20;
			if (changesMade && [reviewInfos count] >= NUM_REVIEWS_PER_PAGE) {
				dispatch_async(dispatch_get_main_queue(), ^ {
					page = page + 1;
					[self start];
				});
			} else {
                if (!canceled) {
                    dispatch_async(dispatch_get_main_queue(), ^ {
                        [self.delegate reviewDownloadDidFinish:self];
                    });
                }
			}
		});
	} else {
		if (!canceled) {
            [self.delegate reviewDownloadDidFinish:self];
		}
		[self endBackgroundTask];
	}
}

- (NSArray *)reviewInfosFromHTML:(NSString *)html
{
	NSMutableArray *reviews = [NSMutableArray array];
	NSScanner *scanner = [NSScanner scannerWithString:html];
    NSCharacterSet *whitespaceAndNewlineCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    
	while (![scanner isAtEnd]) {
		NSString *reviewTitle = nil;
		[scanner scanUpToString:@"<span class=\"customerReviewTitle\">" intoString:NULL];
		[scanner scanString:@"<span class=\"customerReviewTitle\">" intoString:NULL];
		[scanner scanUpToString:@"</span>" intoString:&reviewTitle];
		
		NSString *reviewRatingString = nil;
		NSInteger rating = 0;
		[scanner scanUpToString:@"<div class='rating'" intoString:NULL];
		[scanner scanUpToString:@"aria-label='" intoString:NULL];
		[scanner scanString:@"aria-label='" intoString:NULL];
		[scanner scanUpToString:@"'>" intoString:&reviewRatingString];
		if (reviewRatingString && reviewRatingString.length > 1) {
			rating = [[reviewRatingString substringToIndex:1] integerValue];
		}
		
		NSString *reviewUser = nil;
		[scanner scanUpToString:@"class=\"reviewer\">" intoString:NULL];
		[scanner scanString:@"class=\"reviewer\">" intoString:NULL];
		[scanner scanUpToString:@"</a>" intoString:&reviewUser];
		[scanner scanString:@"</a>" intoString:NULL];
		reviewUser = [reviewUser stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet];
		
		NSString *reviewVersion = nil;
		NSString *reviewDateString = nil;
		NSString *reviewVersionAndDate = nil;
		[scanner scanUpToString:@"</span>" intoString:&reviewVersionAndDate];
		reviewVersionAndDate = [reviewVersionAndDate stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet];
		if (reviewVersionAndDate) {
			NSArray *versionAndDateLines = [reviewVersionAndDate componentsSeparatedByString:@"\n"];
			if ([versionAndDateLines count] == 6) {
				reviewVersion = [[versionAndDateLines objectAtIndex:2] stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet];
				reviewDateString = [[versionAndDateLines objectAtIndex:5] stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet];
			}
		}
		
		NSString *reviewText = nil;
		[scanner scanUpToString:@"<p class=\"content more-text\" truncate-style=\"paragraph\" truncate-length=\"5\">" intoString:NULL];
		[scanner scanString:@"<p class=\"content more-text\" truncate-style=\"paragraph\" truncate-length=\"5\">" intoString:NULL];
		[scanner scanUpToString:@"</p>" intoString:&reviewText];
		reviewText = [reviewText stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet];
		
		if (rating > 0 && reviewTitle && reviewUser && reviewVersion && reviewDateString && reviewText) {
			NSDictionary *reviewInfo = [NSDictionary dictionaryWithObjectsAndKeys:
										reviewTitle, kReviewInfoTitle, 
										reviewUser, kReviewInfoUser, 
										reviewVersion, kReviewInfoVersion, 
										reviewDateString, kReviewInfoDateString, 
										reviewText, kReviewInfoText, 
										[NSNumber numberWithInt:rating], kReviewInfoRating,
										nil];
			[reviews addObject:reviewInfo];
		}
	}
	return reviews;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self endBackgroundTask];
	[self.delegate reviewDownloadDidFinish:self];
}


- (void)dealloc
{
	[country release];
	[_product release];
	[productObjectID release];
	[psc release];
	[downloadConnection release];
	[data release];
	[storeFront release];
	[super dealloc];
}

@end