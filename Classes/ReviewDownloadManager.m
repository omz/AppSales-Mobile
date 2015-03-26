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
	
	ReviewDownload *nextDownload = [[[downloadQueue objectAtIndex:0] retain] autorelease];
	[downloadQueue removeObjectAtIndex:0];
	[activeDownloads addObject:nextDownload];
	[nextDownload start];
	
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

@synthesize delegate, downloadConnection;

- (id)initWithProduct:(Product *)app storeFront:(NSString *)storeFrontID countryCode:(NSString *)countryCode
{
	self = [super init];
	if (self) {
		_product = [app retain];
		country = [countryCode retain];
		productObjectID = [[app objectID] copy];
		psc = [[[app managedObjectContext] persistentStoreCoordinator] retain];
		storeFront = [storeFrontID retain];
		data = [NSMutableData new];
		page = 1;
	}
	return self;
}

- (void)start
{
    backgroundTaskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
    NSString *productID = _product.productID;
    NSString *URLString = [NSString stringWithFormat:@"https://itunes.apple.com/%@/rss/customerreviews/id=%@/sortBy=mostRecent/xml", country, productID];
    NSURL *URL = [NSURL URLWithString:URLString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    self.downloadConnection = [NSURLConnection connectionWithRequest:request delegate:self];
}

- (void)cancel
{
	if (backgroundTaskID != UIBackgroundTaskInvalid) {
		[[UIApplication sharedApplication] endBackgroundTask:backgroundTaskID];
	}
	canceled = YES;
	[self.downloadConnection cancel];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)dataChunk
{
	[data appendData:dataChunk];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSError *error;
    SMXMLDocument *document = [SMXMLDocument documentWithData:data error:&error];
    // check for errors
    if (error) {
        NSLog(@"Error while parsing the document: %@", error);
        return;
    }
    SMXMLElement *feed = document.root;
    //NSLog(@"feed = %@", [feed name]);
    //SMXMLElement * firstEntryChild = [feed childNamed:@"entry"];
    //NSArray *children = [firstEntryChild children];
    // for (SMXMLElement *child in children){
    //     NSLog(@"child name = %@", [child name]);
    // }
    if (1 > 0) // always true
    {
        NSString * stringBlank = @"";
        dispatch_async(dispatch_get_global_queue(0, 0), ^ {
            
            NSMutableArray *reviewInfos = [NSMutableArray new];
            for (SMXMLElement *entry in [feed childrenNamed:@"entry"])
            {
                
                if ([entry valueWithPath:@"artist"] == nil || [entry valueWithPath:@"artist"]  == stringBlank ){
                    
                    //NSArray *children2 = [entry children];
                    //for (SMXMLElement *child2 in children2){
                    //    NSLog(@"child name = %@", [child2 name]);
                    //}
                    //NSLog(@"------------");
                    //NSLog(@"title = %@", [entry valueWithPath:@"title"]);
                    //NSLog(@"updated = %@", [entry valueWithPath:@"updated"]);
                    //NSString *updatedReduced = [[entry valueWithPath:@"updated"] substringToIndex:10];
                    //NSLog(@"updated Reduced = %@", updatedReduced);
                    //NSLog(@"author.name = %@", [entry valueWithPath:@"author.name"]);
                    //NSLog(@"content = %@", [entry valueWithPath:@"content"]);
                    //NSLog(@"version = %@", [entry valueWithPath:@"version"]);
                    //NSLog(@"rating = %@", [entry valueWithPath:@"rating"]);
                    //NSLog(@"------------");
                    
                    NSDictionary *reviewInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                                [entry valueWithPath:@"title"],kReviewInfoTitle,
                                                [[entry valueWithPath:@"updated"] substringToIndex:10], kReviewInfoDateString,
                                                [entry valueWithPath:@"author.name"], kReviewInfoUser,
                                                [entry valueWithPath:@"version"], kReviewInfoVersion,
                                                [entry valueWithPath:@"content"], kReviewInfoText,
                                                [NSNumber numberWithInt:[[entry valueWithPath:@"rating"] intValue]], kReviewInfoRating,
                                                nil];
                    [reviewInfos addObject:reviewInfo];
                }
            }
            NSManagedObjectContext *moc = [[[NSManagedObjectContext alloc] init] autorelease];
            [moc setPersistentStoreCoordinator:psc];
            [moc setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
            Product *product = (Product *)[moc objectWithID:productObjectID];
            
            NSSet *downloadedUsers = [NSSet setWithArray:[reviewInfos valueForKey:kReviewInfoUser]];
            
            //Fetch existing reviews, based on username and country:
            NSFetchRequest *existingReviewsFetchRequest = [[[NSFetchRequest alloc] init] autorelease];
            [existingReviewsFetchRequest setEntity:[NSEntityDescription entityForName:@"Review" inManagedObjectContext:moc]];
            [existingReviewsFetchRequest setPredicate:[NSPredicate predicateWithFormat:@"product == %@ AND countryCode == %@ AND user IN %@", product, country, downloadedUsers]];
            NSArray *existingReviews = [moc executeFetchRequest:existingReviewsFetchRequest error:NULL];
            NSMutableDictionary *existingReviewsByUser = [NSMutableDictionary dictionary];
            for (Review *existingReview in existingReviews) {
                [existingReviewsByUser setObject:existingReview forKey:existingReview.user];
            }
            
            BOOL changesMade = NO;
            for (NSDictionary *reviewInfo in [reviewInfos reverseObjectEnumerator]) {
                Review *existingReview = [existingReviewsByUser objectForKey:[reviewInfo objectForKey:kReviewInfoUser]];
                
                // CREATE REVIEW DATE BY COMPONENTS
                NSInteger year = [[[reviewInfo objectForKey:kReviewInfoDateString] substringToIndex:4] intValue];
                NSString * temp1 = [[reviewInfo objectForKey:kReviewInfoDateString] substringFromIndex:5];
                NSInteger month = [[temp1 substringToIndex:2] intValue];
                NSInteger day = [[temp1 substringFromIndex:3] intValue];
                
                // Combine date and time into components
                NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
                NSDateComponents *components = [[NSDateComponents alloc] init];
                [components setYear:year];
                [components setMonth:month];
                [components setDay:day];
                [components setHour:12];
                [components setMinute:0];
                [components setSecond:0];
                // Generate a new NSDate from components.
                NSDate * combinedReviewDate = [gregorianCalendar dateFromComponents:components];
                
                if (!existingReview) {
                    Review *newReview = [NSEntityDescription insertNewObjectForEntityForName:@"Review" inManagedObjectContext:moc];
                    newReview.user = [reviewInfo objectForKey:kReviewInfoUser];
                    newReview.title = [reviewInfo objectForKey:kReviewInfoTitle];
                    newReview.text = [reviewInfo objectForKey:kReviewInfoText];
                    newReview.rating = [reviewInfo objectForKey:kReviewInfoRating];
                    newReview.downloadDate = [NSDate date];
                    newReview.productVersion = [reviewInfo objectForKey:kReviewInfoVersion];
                    newReview.product = product;
                    newReview.countryCode = country;
                    newReview.unread = [NSNumber numberWithBool:YES];
                    newReview.reviewDate = combinedReviewDate;
                    
                    //NSLog(@"------------");
                    //NSLog(@"newReview.title = %@", newReview.title);
                    //NSLog(@"newReview.downloadDate = %s", [[newReview.downloadDate description] UTF8String]);
                    //NSLog(@"newReview.reviewDate  = %s", [[newReview.reviewDate description] UTF8String]);
                    //NSLog(@"newReview.user = %@", newReview.user);
                    //NSLog(@"newReview.text = %@", newReview.text);
                    //NSLog(@"newReview.productVersion = %@", newReview.productVersion);
                    //NSLog(@"newReview.rating = %@", newReview.rating);
                    //NSLog(@"------------");
                    
                    
                    [existingReviewsByUser setObject:newReview forKey:newReview.user];
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
                        existingReview.downloadDate = [NSDate date];
                        existingReview.reviewDate = combinedReviewDate;
                        changesMade = YES;
                    }
                }
            }
            
            [psc lock];
            NSError *saveError = nil;
            [moc save:&saveError];
            if (saveError) {
                NSLog(@"Could not save context: %@", saveError);
            }
            [psc unlock];
            
            if (changesMade && [reviewInfos count] >= 20) {
                dispatch_async(dispatch_get_main_queue(), ^ {
                    page = page + 1;
                    [self start];
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^ {
                    if (!canceled) {
                        [self.delegate reviewDownloadDidFinish:self];
                    }
                });
            }
        });
    } else {
        if (!canceled) {
            [self.delegate reviewDownloadDidFinish:self];
        }
        if (backgroundTaskID != UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskID];
        }
    }
}

- (NSArray *)reviewInfosFromHTML:(NSString *)html
{
	NSMutableArray *reviews = [NSMutableArray array];
	NSScanner *scanner = [NSScanner scannerWithString:html];
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
		reviewUser = [reviewUser stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
		NSString *reviewVersion = nil;
		NSString *reviewDateString = nil;
		NSString *reviewVersionAndDate = nil;
		[scanner scanUpToString:@"</span>" intoString:&reviewVersionAndDate];
		reviewVersionAndDate = [reviewVersionAndDate stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		if (reviewVersionAndDate) {
			NSArray *versionAndDateLines = [reviewVersionAndDate componentsSeparatedByString:@"\n"];
			if ([versionAndDateLines count] == 6) {
				reviewVersion = [[versionAndDateLines objectAtIndex:2] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
				reviewDateString = [[versionAndDateLines objectAtIndex:5] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			}
		}
		
		NSString *reviewText = nil;
		[scanner scanUpToString:@"<p class=\"content\" will-truncate-max-height=\"0\" data-text-truncate-lines=\"5\">" intoString:NULL];
		[scanner scanString:@"<p class=\"content\" will-truncate-max-height=\"0\" data-text-truncate-lines=\"5\">" intoString:NULL];
		[scanner scanUpToString:@"</p>" intoString:&reviewText];
		reviewText = [reviewText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
		if (rating > 0 && reviewTitle && reviewUser && reviewVersion && reviewDateString && reviewText) {
			NSDictionary *reviewInfo = [NSDictionary dictionaryWithObjectsAndKeys:
										reviewTitle, kReviewInfoTitle, 
										reviewUser, kReviewInfoUser, 
										reviewVersion, kReviewInfoVersion, 
										reviewDateString, kReviewInfoDateString, 
										reviewText, kReviewInfoText, 
										[NSNumber numberWithInteger:rating], kReviewInfoRating,
										nil];
			[reviews addObject:reviewInfo];
		}
	}
	return reviews;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	if (backgroundTaskID != UIBackgroundTaskInvalid) {
		[[UIApplication sharedApplication] endBackgroundTask:backgroundTaskID];
	}
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