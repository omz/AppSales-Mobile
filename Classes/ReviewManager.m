#import "ReviewManager.h"
#import "App.h"
#import "Review.h"
#import "NSString+UnescapeHtml.h"
#import "AppSalesUtils.h"
#import "ReportManager.h"
#import "AppManager.h"

// based on the amount of time since the last fetch
//  'maybe' threshold is the minimum time before an app/region _may_ be downloaded,
// 'always' threshold is the minimum time before an app/region _must_ be downloaded
// 
// to fetch inactive region/apps less often, set both thresholds to larger values
#define TIME_THRESHOLD_TO_MAYBE_FETCH_REGION 5 * 60 // 5 minutes
#define TIME_THRESHOLD_TO_ALWAYS_FETCH_REGION 5 * 24 * 60 * 60 // 5 days

// percent of the app regions _that have previously downloaded reviews_ that must be checked for new reviews
// decrease value to check less active regions less often
#define PERCENT_OF_MOST_ACTIVE_REGIONS_TO_ALWAYS_DOWNLOAD 0.7f

// upper limit of new reviews to fetch, for any one app in any region.
// if you have tons of reviews and only interested in reading the latest reviews, reduce this number to keep the UI more responsive
#define MAX_NUM_REVIEWS_PER_REGION_TO_FETCH 300


// used to pass stuff between background worker threads and main thread
@interface ReviewUpdateBundle : NSObject {
@private
	NSString *appID;
    NSArray *input;
	NSMutableArray *needsUpdating;
    BOOL foundReviewsOfCurrentVersion;
}
@property (retain, readonly) NSString *appID;
@property (retain, readonly) NSArray *input; // reviews to check
@property (retain, readonly) NSMutableArray *needsUpdating; // new or updated reviews that need further processing
@property (readonly) BOOL foundReviewsOfCurrentVersion; // needsUpdating contains reviews of the current app version (as opposed to reviews of older app versions) 
@end

@implementation ReviewUpdateBundle
@synthesize appID, input, needsUpdating, foundReviewsOfCurrentVersion;
- (id) initWithAppID:(NSString*)idTouse reviews:(NSArray*)reviews {
	self = [super init];
    if (self) {
        appID = [idTouse retain];
        input = [reviews retain];
        needsUpdating = [NSMutableArray new];        
    }
	return self;
}

- (void) checkIfReviewsUpToDate {
    ASSERT_IS_MAIN_THREAD();
	App *app = [[AppManager sharedManager] appWithID:appID];
	
	NSDictionary *existingReviews = app.reviewsByUser;
    for (Review *fetchedReview in input) {
        Review *oldReview = [existingReviews objectForKey:fetchedReview.user];
        if (oldReview == nil) { // new review
            [needsUpdating addObject:fetchedReview]; // needs translation and updating
            if ([fetchedReview.version isEqualToString:app.currentVersion]) {
                foundReviewsOfCurrentVersion = true;
            }
        } else if (! [oldReview.text isEqual:fetchedReview.text]) {
            // fetched review is different than what's stored
            const NSTimeInterval ageOfStaleReviewsToIgnore = 24 * 60 * 60; // 1 day
			NSComparisonResult compare = [fetchedReview.reviewDate compare:oldReview.reviewDate];
            if ((compare == NSOrderedSame || compare == NSOrderedDescending)
                && ageOfStaleReviewsToIgnore < -1*[fetchedReview.reviewDate timeIntervalSinceNow]) {
                // if a user writes a review then immediately submits a different review, 
                // occasionally Apples web servers won't propagate the updated review to all it's webservers,
                // leaving different reviews on different web servers.
                // When fetching the reviews, the review will switch back and forth between the 
                // old and updated review (and reporting as 'new' in AppSales), when it's really just inconsistent data from Apple. 
                // we'll stop this by ignoring the stale data after downloading
                APPSALESLOG(@"ignoring stale review %@", fetchedReview);
            } else {
                [needsUpdating addObject:fetchedReview];
                if ([fetchedReview.version isEqualToString:app.currentVersion]) {
                    foundReviewsOfCurrentVersion = true;
                }
            }
        }
    }
}
- (void) dealloc {
    [appID release];
    [input release];
    [needsUpdating release];
    [super dealloc];
}
@end


@interface StoreInfo : NSObject {
@private
	NSString *countryCode;
	NSString *storeFrontID;
	NSString *countryName;
	NSNumber *reviewCount; // initially nil
	NSDateFormatter *dateFormatter;
}
@property (retain, readonly) NSString *countryCode, *storeFrontID, *countryName;
@property (retain, readonly) NSDateFormatter *dateFormatter; // may be nil
@property (readonly) NSInteger reviewCount;
@end

@implementation StoreInfo
@synthesize countryCode, storeFrontID, countryName, dateFormatter;
- (id) initWithCountryCode:(NSString*)code storeID:(NSString*)storeID formatter:(NSDateFormatter*)format {
	self = [super init];
	if (self) {
		NSAssert(code && storeID, nil);
		countryCode = [code retain];
		storeFrontID = [storeID retain];
		countryName = [[[NSLocale currentLocale] displayNameForKey:NSLocaleCountryCode value:countryCode] retain];
		dateFormatter = [format retain];		
	}
	return self;
}
- (NSInteger) reviewCount {
	if (reviewCount == nil) {
		NSInteger count = 0;
		for (App *app in [AppManager sharedManager].allApps) {
			for (Review *review in [app.reviewsByUser objectEnumerator]) {
				if ([countryCode isEqualToString:review.countryCode]) {
					count++;
				}
			}
		}
		reviewCount = [[NSNumber alloc] initWithInteger:count];
	}
	return reviewCount.integerValue;
}
- (NSString*) description {
	return [countryCode stringByAppendingFormat:@" %d", self.reviewCount];
}
- (void) dealloc {
	[countryCode release];
	[storeFrontID release];
	[countryName release];
	[dateFormatter release];
	[reviewCount release];
	[super dealloc];
}
+ (StoreInfo*) storeInfoCountryCode:(NSString*)code storeID:(NSString*)storeID formatter:(NSDateFormatter*)format {
	return [[[StoreInfo alloc] initWithCountryCode:code storeID:storeID formatter:format] autorelease];
}
@end




@implementation ReviewManager

@synthesize reviewDownloadStatus, isDownloadingReviews;

+ (ReviewManager*) sharedManager {
	static ReviewManager *sharedManager = nil;
	if (sharedManager == nil) {
		sharedManager = [ReviewManager new];
	}
	return sharedManager;
}

- (id) init {
	if ((self = [super init]) != nil) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cancel) name:UIApplicationDidEnterBackgroundNotification object:nil];
	}
	return self;
}

- (void) markAllReviewsAsRead {
	for(App *app in [AppManager sharedManager].allApps){
		[app resetNewReviewCount];
	}
}

#define SKIP_LESS_ACTIVE_REGION_PREF_KEY @"SKIP_LESS_ACTIVE_REGION_PREF_KEY"
- (BOOL) skipLessActiveRegions {
	return [[NSUserDefaults standardUserDefaults] boolForKey:SKIP_LESS_ACTIVE_REGION_PREF_KEY];
}

- (void) setSkipLessActiveRegions:(BOOL)skipLessActiveRegions {
	[[NSUserDefaults standardUserDefaults] setBool:skipLessActiveRegions forKey:SKIP_LESS_ACTIVE_REGION_PREF_KEY];
}

- (void) dealloc {
	[reviewDownloadStatus release];
	[[NSNotificationCenter defaultCenter] removeObject:self];
	[super dealloc];
}

- (void) cancel {
	if (isDownloadingReviews) APPSALESLOG(@"cancel requested");
	cancelRequested = YES;
}

- (StoreInfo*) getNextStoreToFetch {
	StoreInfo *storeInfo;
	@synchronized (storeInfos) {
		storeInfo = [storeInfos lastObject];
		if (storeInfo) {
			[storeInfo retain];
			[storeInfos removeLastObject];
			[storeInfo autorelease];
		}
	}
	return storeInfo;
}

- (void) workerDone {
	[condition lock];
	NSAssert(numThreadsActive > 0, nil);
	if (--numThreadsActive == 0) {
		[condition broadcast];
	}
	[condition unlock];	
}

// called after translating new or updated reviews
- (void) addReviews:(ReviewUpdateBundle*)bundle {
    ASSERT_IS_MAIN_THREAD();
	App *app = [[AppManager sharedManager] appWithID:bundle.appID];
    for (Review *fetchedReivew in bundle.needsUpdating) {
        [app addOrReplaceReview:fetchedReivew];        
    }
	[[NSNotificationCenter defaultCenter] postNotificationName:ReviewManagerDownloadedReviewsNotification object:self];
}

- (void) workerThreadFetch { // called by worker threads
    ASSERT_NOT_MAIN_THREAD();
	NSAutoreleasePool *outerPool = [NSAutoreleasePool new];
	@try {
		NSMutableURLRequest *request = [[NSMutableURLRequest new] autorelease];
		NSMutableDictionary *headers = [NSMutableDictionary dictionary];
		NSCharacterSet *whitespaceCharacterSet = [NSCharacterSet whitespaceCharacterSet];
		NSCharacterSet *whitespaceAndNewlineCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
		NSDateFormatter *threadDefaultDateFormatter;
		@synchronized (defaultDateFormatter) {
			// date formatters are not thread safe.  Make a copy for just this thread
			threadDefaultDateFormatter = [[defaultDateFormatter copy] autorelease];
		}
		
		StoreInfo *storeInfo;
		while ((storeInfo = [self getNextStoreToFetch]) != nil) {
			NSAutoreleasePool *innerPool = [NSAutoreleasePool new];
			NSString *countryCode = storeInfo.countryCode;
			NSDateFormatter *dateFormatter = storeInfo.dateFormatter;
			if (dateFormatter == nil) {
				dateFormatter = threadDefaultDateFormatter;
			}
            
			NSString *storeFrontID = storeInfo.storeFrontID;
			NSString *storeFront = [storeFrontID stringByAppendingString:@"-1"];
			[headers setObject:@"iTunes/9.2.1 (Macintosh; Intel Mac OS X 10.5.8) AppleWebKit/533.16" forKey:@"User-Agent"];
			[headers setObject:storeFront forKey:@"X-Apple-Store-Front"];
			[request setAllHTTPHeaderFields:headers];
			[request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
            
            NSInteger regionsFetched = 0;
			for (NSString *appID in allAppIds) {
                NSNumber *regionShouldDownload = [[appIDtoStoreRegion objectForKey:appID] objectForKey:countryCode];
                if (! regionShouldDownload.boolValue) {
                    continue;
                }
				APPSALESLOG(@"fetching %@ %@", countryCode, appID);
				NSAutoreleasePool *singleAppPool = [NSAutoreleasePool new];
                regionsFetched++;

                // number of new reviews that must be downloaded from a page before checking the the next page
                const NSInteger thresholdForParsingNextPage = 20;
                NSInteger pageNumber = 0;
                NSInteger totalNumberOfNewReviews = 0; // number of new reviews parsed for all pages
                NSInteger numFetchedNewReviews; // number of new reviews parsed on the page
                BOOL foundNewReviewsForCurrentAppVersion;
                do {
                    numFetchedNewReviews = 0;
                    foundNewReviewsForCurrentAppVersion = false;
                    NSString *reviewsURLString = [NSString stringWithFormat:@"http://ax.phobos.apple.com.edgesuite.net/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=%@&pageNumber=%d&sortOrdering=4&type=Purple+Software", appID, pageNumber];
                    pageNumber++;
                    [request setURL:[NSURL URLWithString:reviewsURLString]];
                    
                    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:NULL error:NULL];
                    if (cancelRequested) { // check after making slow network call
                        return;
                    }
                    NSString *xml = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
                    NSScanner *scanner = [NSScanner scannerWithString:xml];
                    NSMutableArray *input = [NSMutableArray array];
                    do {
                        NSAutoreleasePool *singleReviewPool = [NSAutoreleasePool new];
                        
                        NSString *reviewTitle = nil;
                        NSString *reviewDateAndVersion = nil;
                        NSString *reviewUser = nil;
                        NSString *reviewText = nil;
                        NSString *reviewStars = nil;
                        NSString *reviewVersion = nil;
                        NSDate *reviewDate = nil;
                        
                        [scanner scanUpToString:@"<TextView topInset=\"0\" truncation=\"right\" leftInset=\"0\" squishiness=\"1\" styleSet=\"basic13\" textJust=\"left\" maxLines=\"1\">" intoString:NULL];
                        [scanner scanUpToString:@"<b>" intoString:NULL];
                        [scanner scanString:@"<b>" intoString:NULL];
                        [scanner scanUpToString:@"</b>" intoString:&reviewTitle];
                        
                        [scanner scanUpToString:@"<HBoxView topInset=\"1\" alt=\"" intoString:NULL];
                        [scanner scanString:@"<HBoxView topInset=\"1\" alt=\"" intoString:NULL];
                        [scanner scanUpToString:@" " intoString:&reviewStars];
                        
                        [scanner scanUpToString:@"viewUsersUserReviews" intoString:NULL];
                        [scanner scanString:@"viewUsersUserReviews" intoString:NULL];
                        [scanner scanUpToString:@">" intoString:NULL];
                        [scanner scanString:@">" intoString:NULL];
                        [scanner scanUpToString:@"</GotoURL>" intoString:&reviewUser];
                        reviewUser = [reviewUser stringByReplacingOccurrencesOfString:@"<b>" withString:@""]; // should use a regular expression to strip html tags
                        reviewUser = [reviewUser stringByReplacingOccurrencesOfString:@"</b>" withString:@""];
                        reviewUser = [reviewUser stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet];
                        
                        [scanner scanUpToString:@" - " intoString:NULL];
                        [scanner scanString:@" - " intoString:NULL];
                        [scanner scanUpToString:@"</SetFontStyle>" intoString:&reviewDateAndVersion];
                        reviewDateAndVersion = [reviewDateAndVersion stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                        NSArray *dateVersionSplitted = [reviewDateAndVersion componentsSeparatedByString:@"- "];
                        if (dateVersionSplitted.count == 2) {
                            NSString *version = [dateVersionSplitted objectAtIndex:0];
                            reviewVersion = [version stringByTrimmingCharactersInSet:whitespaceCharacterSet];
                            NSString *date = [dateVersionSplitted objectAtIndex:1];
                            date = [date stringByTrimmingCharactersInSet:whitespaceCharacterSet];
                            reviewDate = [dateFormatter dateFromString:date];
                        } else if (dateVersionSplitted.count == 3) {
                            NSString *version = [dateVersionSplitted objectAtIndex:1];
                            reviewVersion = [version stringByTrimmingCharactersInSet:whitespaceCharacterSet];
                            NSString *date = [dateVersionSplitted objectAtIndex:2];
                            date = [date stringByTrimmingCharactersInSet:whitespaceCharacterSet];
                            reviewDate = [dateFormatter dateFromString:date];
                        }
                        
                        [scanner scanUpToString:@"<SetFontStyle normalStyle=\"textColor\">" intoString:NULL];
                        [scanner scanString:@"<SetFontStyle normalStyle=\"textColor\">" intoString:NULL];
                        [scanner scanUpToString:@"</SetFontStyle>" intoString:&reviewText];
                        
                        if (reviewUser && reviewTitle && reviewText && reviewStars) {
                            Review *review = [[Review alloc] initWithUser:[reviewUser removeHtmlEscaping]
                                                               reviewDate:reviewDate
                                                             downloadDate:downloadDate
                                                                  version:reviewVersion
                                                              countryCode:countryCode
                                                                    title:[reviewTitle removeHtmlEscaping] 
                                                                     text:[reviewText removeHtmlEscaping]
                                                                    stars:[reviewStars intValue]];
                            [input addObject:review];
                            [review release];
                        }
                        [singleReviewPool release];
                    } while (! [scanner isAtEnd]);
                    
                    // check if any reviews are new or updated and need further processing
                    if (input.count) {
                        // we could bundle up all reviews for every page, 
                        // but it can overload google translate so we'll translate reviews on each page separately
                        ReviewUpdateBundle *bundle = [[[ReviewUpdateBundle alloc] initWithAppID:appID reviews:input] autorelease];
                        [bundle performSelectorOnMainThread:@selector(checkIfReviewsUpToDate) withObject:nil waitUntilDone:YES];
                        numFetchedNewReviews = bundle.needsUpdating.count;
                        totalNumberOfNewReviews += numFetchedNewReviews;
                        foundNewReviewsForCurrentAppVersion = bundle.foundReviewsOfCurrentVersion;
                        if (bundle.needsUpdating.count) {
                            [Review updateTranslations:bundle.needsUpdating];
                            [self performSelectorOnMainThread:@selector(addReviews:) withObject:bundle waitUntilDone:YES];		
                        }
                    }
                } while (foundNewReviewsForCurrentAppVersion
                         && numFetchedNewReviews >= thresholdForParsingNextPage
                         && totalNumberOfNewReviews < MAX_NUM_REVIEWS_PER_REGION_TO_FETCH);
                                
				[singleAppPool release];
			}
            if (regionsFetched) {
                [self performSelectorOnMainThread:@selector(incrementDownloadProgress:)
                                       withObject:[NSNumber numberWithInt:regionsFetched] waitUntilDone:NO];
            }
			[innerPool release];
		}
	} @finally {
		[self workerDone];
		[outerPool release];
	}
}


- (void) updateReviews {
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
    ASSERT_NOT_MAIN_THREAD();
#if APPSALES_DEBUG
	NSDate *start = [NSDate date];
#endif
    
	downloadDate = [NSDate new];
	
	condition = [NSCondition new];
	numThreadsActive = NUMBER_OF_FETCHING_THREADS;
	
	[condition lock];
	for (int i=0; i < NUMBER_OF_FETCHING_THREADS; i++) {
		[self performSelectorInBackground:@selector(workerThreadFetch) withObject:nil];
	}
	[condition wait]; // wait for workers to finish (or cancel is requested)
	[condition unlock];
    
    // cleanup
	RELEASE_SAFELY(condition);
	RELEASE_SAFELY(allAppIds);
    RELEASE_SAFELY(appIDtoStoreRegion);
	RELEASE_SAFELY(storeInfos);
	RELEASE_SAFELY(defaultDateFormatter);
	RELEASE_SAFELY(downloadDate);
    
	[self performSelectorOnMainThread:@selector(finishDownloadingReviews) withObject:nil waitUntilDone:NO];
    APPSALESLOG(@"update took %f sec", -1*start.timeIntervalSinceNow);
	[pool release];
}

- (void) updateReviewDownloadProgress:(NSString*)status {
    //	    ASSERT_IS_MAIN_THREAD();
	[status retain]; // must retain first
	[reviewDownloadStatus release];
	reviewDownloadStatus = status;
	[[NSNotificationCenter defaultCenter] postNotificationName:ReviewManagerUpdatedReviewDownloadProgressNotification object:self];
}

- (void) incrementDownloadProgress:(NSNumber*)numAppRegionsFetched {
	percentComplete += numAppRegionsFetched.integerValue * progressIncrement;
	NSString *status = [[NSString alloc] initWithFormat:NSLocalizedString(@"%2.0f%% complete", nil), percentComplete];
	[self updateReviewDownloadProgress:status];
	[status release];
}

static NSInteger numStoreReviewsComparator(id arg1, id arg2, void *arg3) {
	NSInteger store1Count = [[(NSDictionary*)arg3 objectForKey:[(StoreInfo*)arg1 countryCode]] integerValue];
	NSInteger store2Count = [[(NSDictionary*)arg3 objectForKey:[(StoreInfo*)arg2 countryCode]] integerValue];
	if (store1Count < store2Count) {
		return NSOrderedAscending;
	}
	if (store1Count > store2Count) {
		return NSOrderedDescending;
	}
	return NSOrderedSame;
}

- (void) downloadReviews {
    ASSERT_IS_MAIN_THREAD();
	if (isDownloadingReviews) {
		return;
	}
	isDownloadingReviews = YES;
	cancelRequested = NO;
	[self updateReviewDownloadProgress:NSLocalizedString(@"Downloading reviews...",nil)];
	
	NSArray *allApps = [AppManager sharedManager].allApps;
	
	// reset new review count
	for (App *app in allApps) {
		[app resetNewReviewCount];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ReviewManagerDownloadedReviewsNotification object:self];
    
	// setup store fronts, this should probably go into a plist...:
	NSDateFormatter *frDateFormatter = [[NSDateFormatter new] autorelease];
	NSLocale *frLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"fr"] autorelease];
	[frDateFormatter setLocale:frLocale];
	[frDateFormatter setDateFormat:@"dd MMM yyyy"];
	
	NSDateFormatter *deDateFormatter = [[NSDateFormatter new] autorelease];
	NSLocale *deLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"de"] autorelease];
	[deDateFormatter setLocale:deLocale];
	[deDateFormatter setDateFormat:@"dd.MM.yyyy"];
	
	NSDateFormatter *itDateFormatter = [[NSDateFormatter new] autorelease];
	NSLocale *itLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"it"] autorelease];
	[itDateFormatter setLocale:itLocale];
	[itDateFormatter setDateFormat:@"dd-MMM-yyyy"];
    
	NSDateFormatter *usDateFormatter = [[NSDateFormatter new] autorelease];
	NSLocale *usLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en-us"] autorelease];
	[usDateFormatter setLocale:usLocale];
	[usDateFormatter setDateFormat:@"MMM dd, yyyy"];
	
	defaultDateFormatter = [NSDateFormatter new];
	[defaultDateFormatter setDateFormat:@"dd-MMM-yyyy"];
    [defaultDateFormatter setLocale:usLocale];
	
	// sort app id's by number of existing reviews
	NSSortDescriptor *dateSorter = [[[NSSortDescriptor alloc] initWithKey:@"totalReviewsCount" ascending:NO] autorelease];
	NSArray *sortedApps = [allApps sortedArrayUsingDescriptors:[NSArray arrayWithObject:dateSorter]];
	NSMutableArray *sortedAppIds = [[NSMutableArray alloc] initWithCapacity:sortedApps.count];
	for (App *app in sortedApps) {
		[sortedAppIds addObject:app.appID];
	}
	allAppIds = sortedAppIds;
	
	storeInfos = [[NSMutableArray alloc] initWithObjects:
				  [StoreInfo storeInfoCountryCode:@"ae" storeID:@"143481" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"am" storeID:@"143524" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"ar" storeID:@"143505" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"at" storeID:@"143445" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"au" storeID:@"143460" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"bd" storeID:@"143446" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"be" storeID:@"143446" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"bg" storeID:@"143526" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"br" storeID:@"143503" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"bw" storeID:@"143525" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"ca" storeID:@"143455" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"ch" storeID:@"143459" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"cl" storeID:@"143483" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"cn" storeID:@"143465" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"co" storeID:@"143501" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"cr" storeID:@"143495" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"cz" storeID:@"143489" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"de" storeID:@"143443" formatter:deDateFormatter],
				  [StoreInfo storeInfoCountryCode:@"dk" storeID:@"143458" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"do" storeID:@"143508" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"ec" storeID:@"143509" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"ee" storeID:@"143518" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"eg" storeID:@"143516" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"es" storeID:@"143454" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"fi" storeID:@"143447" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"fr" storeID:@"143442" formatter:frDateFormatter],
				  [StoreInfo storeInfoCountryCode:@"gb" storeID:@"143444" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"gr" storeID:@"143448" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"gt" storeID:@"143504" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"hk" storeID:@"143463" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"hn" storeID:@"143510" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"hr" storeID:@"143494" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"hu" storeID:@"143482" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"id" storeID:@"143476" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"ie" storeID:@"143449" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"il" storeID:@"143491" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"in" storeID:@"143467" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"it" storeID:@"143450" formatter:itDateFormatter],
				  [StoreInfo storeInfoCountryCode:@"jm" storeID:@"143511" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"jo" storeID:@"143528" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"jp" storeID:@"143462" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"ke" storeID:@"143529" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"kr" storeID:@"143466" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"kw" storeID:@"143493" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"kz" storeID:@"143517" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"lb" storeID:@"143497" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"lk" storeID:@"143486" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"lt" storeID:@"143520" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"lu" storeID:@"143451" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"lv" storeID:@"143519" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"md" storeID:@"143523" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"mg" storeID:@"143531" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"mk" storeID:@"143530" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"ml" storeID:@"143532" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"mo" storeID:@"143515" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"mt" storeID:@"143521" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"mu" storeID:@"143533" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"mx" storeID:@"143468" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"my" storeID:@"143473" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"ne" storeID:@"143534" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"ni" storeID:@"143512" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"nl" storeID:@"143452" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"no" storeID:@"143457" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"nz" storeID:@"143461" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"pa" storeID:@"143485" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"pe" storeID:@"143507" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"ph" storeID:@"143474" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"pk" storeID:@"143477" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"pl" storeID:@"143478" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"pt" storeID:@"143453" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"py" storeID:@"143513" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"qa" storeID:@"143498" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"ro" storeID:@"143487" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"ru" storeID:@"143469" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"sa" storeID:@"143479" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"se" storeID:@"143456" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"sg" storeID:@"143464" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"si" storeID:@"143499" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"sk" storeID:@"143496" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"sn" storeID:@"143535" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"sv" storeID:@"143506" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"th" storeID:@"143475" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"tn" storeID:@"143536" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"tr" storeID:@"143480" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"tw" storeID:@"143470" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"ug" storeID:@"143537" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"us" storeID:@"143441" formatter:usDateFormatter],
				  [StoreInfo storeInfoCountryCode:@"uy" storeID:@"143514" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"ve" storeID:@"143502" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"vn" storeID:@"143471" formatter:nil],
				  [StoreInfo storeInfoCountryCode:@"za" storeID:@"143472" formatter:nil],
				  nil];
	
	// figure out which regions of each app to fetch
	BOOL skipLessActiveRegions;
	NSDate *now = [NSDate date];
	NSTimeInterval nowInterval = now.timeIntervalSinceReferenceDate;
	if (nowInterval - timeLastFetched < TIME_THRESHOLD_TO_MAYBE_FETCH_REGION) {
		skipLessActiveRegions = NO;
		APPSALESLOG(@"recent fetched, forcing fetch of all apps/regions"); 
	} else {
		skipLessActiveRegions = [self skipLessActiveRegions];
	}
	timeLastFetched = nowInterval;
    
    NSNumber *falseObj = [NSNumber numberWithBool:false];
    NSNumber *trueObj = [NSNumber numberWithBool:true];
	NSNumber *initialFetchValue = skipLessActiveRegions ? falseObj : trueObj;
	
    // create initial mapping
    appIDtoStoreRegion = [[NSMutableDictionary alloc] initWithCapacity:allApps.count];
	for (App *app in allApps) {
        NSMutableDictionary *storeRegiontoBool = [NSMutableDictionary dictionaryWithCapacity:storeInfos.count];
        for (StoreInfo *store in storeInfos) {
            [storeRegiontoBool setValue:initialFetchValue forKey:store.countryCode];
        }
        [appIDtoStoreRegion setValue:storeRegiontoBool forKey:app.appID];
    }
	
    
	// build intermediate data structures to figure out which app regions to download
	NSMutableArray *numAllAppRegionReviews = [NSMutableArray arrayWithCapacity:allApps.count * storeInfos.count]; // raw review count for all app regions
	NSMutableDictionary *numRegionReviews = [NSMutableDictionary dictionaryWithCapacity:storeInfos.count]; // number reviews for all apps (countryCode -> NSNumber) 
	NSMutableDictionary *appRegionReviews = [NSMutableDictionary dictionaryWithCapacity:allApps.count]; // number of reviews for app region (appID -> (countryCode -> NSNumber))
    
	for (App *app in allApps) {
		NSMutableDictionary *numAppRegionReviews = [NSMutableDictionary dictionaryWithCapacity:storeInfos.count];
		[appRegionReviews setValue:numAppRegionReviews forKey:app.appID];
		for (Review *review in app.reviewsByUser.objectEnumerator) {
			// add up total number of reviews for each _region_
			NSNumber *regionCountObj = [numRegionReviews objectForKey:review.countryCode];
			const NSUInteger regionCount = (regionCountObj ? regionCountObj.intValue + 1 : 1);
			regionCountObj = [[NSNumber alloc] initWithInteger:regionCount];
			[numRegionReviews setObject:regionCountObj forKey:review.countryCode];
			[regionCountObj release];
			
			// add up total number of reviews for each _app region_
			NSNumber *appRegionCountObj = [numAppRegionReviews objectForKey:review.countryCode];
			const NSInteger appRegionCount = (appRegionCountObj ? appRegionCountObj.integerValue + 1 : 1);
			appRegionCountObj = [[NSNumber alloc] initWithInteger:appRegionCount];
			[numAppRegionReviews setObject:appRegionCountObj forKey:review.countryCode];
			[appRegionCountObj release];
		}
		[numAllAppRegionReviews addObjectsFromArray:numAppRegionReviews.allValues];
	}
	[numAllAppRegionReviews sortUsingSelector:@selector(compare:)];
	
	
	// sort regions by its number of existing reviews, so the more active regions are downloaded first
	[storeInfos sortUsingFunction:&numStoreReviewsComparator context:numRegionReviews];
	
	if (skipLessActiveRegions) {
		NSAssert(PERCENT_OF_MOST_ACTIVE_REGIONS_TO_ALWAYS_DOWNLOAD >= 0 && PERCENT_OF_MOST_ACTIVE_REGIONS_TO_ALWAYS_DOWNLOAD <= 1, nil);
		if (numAllAppRegionReviews.count == 0) {
			// no reviews for any app have been downloaded yet,
            // and thus we have no idea where new reviews are more likely to show up
			APPSALESLOG(@"no existing reviews found, downloading all app regions");
			for (NSMutableDictionary *storeRegiontoBool in appIDtoStoreRegion.allValues) {
				for (NSString *regionCode in storeRegiontoBool.allKeys) {
					[storeRegiontoBool setValue:trueObj forKey:regionCode];
				}
			}
		} else {
            // else, grab a chunk of the larger app regions
			// index of upper percent we want to use
			const NSUInteger scoreThresholdIndex = (1.0f - PERCENT_OF_MOST_ACTIVE_REGIONS_TO_ALWAYS_DOWNLOAD) * (numAllAppRegionReviews.count - 1);
			const NSInteger scoreThreshold = [[numAllAppRegionReviews objectAtIndex:scoreThresholdIndex] integerValue];
			
			for (NSString *appID in appRegionReviews.allKeys) {
				NSMutableDictionary *existingAppRegionReviews = [appRegionReviews valueForKey:appID];
				for (NSString *regionCode in existingAppRegionReviews.allKeys) {
					NSInteger regionScore = [[existingAppRegionReviews valueForKey:regionCode] integerValue];
					if (regionScore >= scoreThreshold) {
						APPSALESLOG(@"adding %@ %@", regionCode, [[AppManager sharedManager] appWithID:appID].appName);
						NSMutableDictionary *regionToBool = [appIDtoStoreRegion valueForKey:appID];
						[regionToBool setValue:trueObj forKey:regionCode];
					}
				}
			}
			
			// add app regions that have never been downloaded, or last fetch was longer than threshold
			NSAssert(TIME_THRESHOLD_TO_MAYBE_FETCH_REGION < TIME_THRESHOLD_TO_ALWAYS_FETCH_REGION, nil);
			for (App *app in allApps) {
				for (StoreInfo *store in storeInfos) {
					NSString *countryCode = store.countryCode;
					NSMutableDictionary *storeIdShouldFetch = [appIDtoStoreRegion objectForKey:app.appID];
					NSDate *dateLastFetched = [app lastTimeReviewsForStoreWasDownloaded:countryCode];
					if (dateLastFetched == nil) { // never fetched
						APPSALESLOG(@"adding never fetched %@ %@", countryCode, app.appName);
						[storeIdShouldFetch setObject:trueObj forKey:countryCode];
					} else {
						// randomly grab regions, with older fetched regions having a higher chance of being chosen
						NSTimeInterval range = -1*[dateLastFetched timeIntervalSinceNow] - TIME_THRESHOLD_TO_MAYBE_FETCH_REGION;
						range /= TIME_THRESHOLD_TO_ALWAYS_FETCH_REGION;
						if (random_0_1() < range) {
							APPSALESLOG(@"adding recently unfetched %@ %@", countryCode, app.appName);
							[storeIdShouldFetch setObject:trueObj forKey:countryCode];
						}
					}
				}
			}
		}
	}
    
    // count up how many app/regions will be fetched, and update last fetched time
    NSUInteger numAppRegionsToFetch = 0;
	AppManager *manager = [AppManager sharedManager];
	for (NSString *appID in appIDtoStoreRegion.allKeys) {
		App *app = [manager appWithID:appID];
		NSMutableDictionary *storeRegiontoBool = [appIDtoStoreRegion objectForKey:appID];
		for (NSString *countryCode in storeRegiontoBool.allKeys) {
			NSNumber *willFetch = [storeRegiontoBool objectForKey:countryCode];
			if (willFetch.boolValue) {
				[app setLastTimeReviewsDownloaded:countryCode time:now];
                numAppRegionsToFetch++;
			}
		}
	}
	
    percentComplete = 0;
	progressIncrement = 100.0 / numAppRegionsToFetch;
	
	[self performSelectorInBackground:@selector(updateReviews) withObject:nil];
}

- (void) finishDownloadingReviews {
    ASSERT_IS_MAIN_THREAD();
	isDownloadingReviews = NO;
	
	[[AppManager sharedManager] saveToDisk];
	[self updateReviewDownloadProgress:@""];
	[[NSNotificationCenter defaultCenter] postNotificationName:ReviewManagerDownloadedReviewsNotification object:self];
}


@end
