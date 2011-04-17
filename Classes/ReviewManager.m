#import "ReviewManager.h"
#import "App.h"
#import "Review.h"
#import "NSString+UnescapeHtml.h"
#import "ReportManager.h"
#import "AppManager.h"

// used to pass stuff between background worker threads and main thread
// could refactor this so this object is doing the update work
@interface ReviewUpdateBundle : NSObject {
	NSString *appID;
    NSArray *input;
	NSMutableArray *needsUpdating;
}
- (id) initWithAppID:(NSString*)idTouse reviews:(NSArray*)reviews;
@property (retain, readonly) NSString *appID;
@property (retain, readonly) NSArray *input; // reviews to check
@property (retain, readonly) NSMutableArray *needsUpdating; // new or updated reviews that need further processing
@end

@implementation ReviewUpdateBundle
@synthesize appID, input, needsUpdating;
- (id) initWithAppID:(NSString*)idTouse reviews:(NSArray*)reviews {
	self = [super init];
    if (self) {
        input = [reviews retain];
        appID = [idTouse retain];
        needsUpdating = [[NSMutableArray alloc] init];        
    }
	return self;
}
- (void) dealloc {
    [appID release];
    [input release];
    [needsUpdating release];
    [super dealloc];
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
	if (self = [super init]) {
		NSString *notification = UIApplicationWillTerminateNotification;
		if (&UIApplicationDidEnterBackgroundNotification) {
			notification = UIApplicationDidEnterBackgroundNotification;
		}
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cancel) name:notification object:nil];
	}
	return self;
}

- (void) markAllReviewsAsRead {
	for(App *app in [AppManager sharedManager].allApps){
		[app resetNewReviewCount];
	}
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObject:self];
	[super dealloc];
}

- (void) cancel {
#if APPSALES_DEBUG
	if (isDownloadingReviews) NSLog(@"cancel requested");
#endif	
	cancelRequested = YES;
}

- (NSDictionary*) getNextStoreToFetch {
	NSDictionary *storeInfo;
	@synchronized (storeInfos) {
		storeInfo = [storeInfos lastObject];
		if (storeInfo) {
			[storeInfos removeLastObject];
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

- (void) notifyOfNewReviews {
	NSAssert([NSThread isMainThread], nil);
	[[NSNotificationCenter defaultCenter] postNotificationName:ReviewManagerDownloadedReviewsNotification object:self];
}

- (void) checkIfReviewsUpToDate:(ReviewUpdateBundle*)bundle {
	NSAssert([NSThread isMainThread], nil);
	App *app = [[AppManager sharedManager] appWithID:bundle.appID];
	
	NSDictionary *existingReviews = app.reviewsByUser;
    for (Review *fetchedReview in bundle.input) {
        Review *oldReview = [existingReviews objectForKey:fetchedReview.user];
        if (oldReview == nil) { // new review
            [bundle.needsUpdating addObject:fetchedReview]; // needs translation and updating
        } else if (! [oldReview.text isEqual:fetchedReview.text]) { // fetched review is new or different than what's stored
            const NSTimeInterval ageOfStaleReviewsToIgnore = 24 * 60 * 60; // 1 day
            if ([fetchedReview.reviewDate isEqualToDate:oldReview.reviewDate] 
                    && ageOfStaleReviewsToIgnore < -1*[fetchedReview.reviewDate timeIntervalSinceNow]) {
                // if a user writes a review then immediately submits a different review, 
                // occasionally Apples web servers won't propagate the updated review to all it's webservers,
                // leaving different reviews on different web servers.
                // When fetching the reviews, the review will switch back and forth between the 
                // old and updated review (and reporting as 'new' in AppSales), when it's really just inconsistent data from Apple. 
                // we'll stop this by ignoring the stale data after downloading
#if APPSALES_DEBUG
                NSLog(@"ignoring stale review %@", fetchedReview);
#endif
            } else {
                [bundle.needsUpdating addObject:fetchedReview];
            }
        }
    }
}

// called after translating new or updated reviews
- (void) addReviews:(ReviewUpdateBundle*)bundle {
	NSAssert([NSThread isMainThread], nil);
	App *app = [[AppManager sharedManager] appWithID:bundle.appID];
    for (Review *fetchedReivew in bundle.needsUpdating) {
        [app addOrReplaceReview:fetchedReivew];        
    }
    [self notifyOfNewReviews];
	saveToDiskNeeded = YES;
}

- (void) workerThreadFetch { // called by worker threads
	NSAutoreleasePool *outerPool = [NSAutoreleasePool new];
	@try {
		NSAssert(! [NSThread isMainThread], nil);
		NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
		NSMutableDictionary *headers = [NSMutableDictionary dictionary];
		NSCharacterSet *whitespaceCharacterSet = [NSCharacterSet whitespaceCharacterSet];
		NSCharacterSet *whitespaceAndNewlineCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
		NSDateFormatter *threadDefaultDateFormatter;
		@synchronized (defaultDateFormatter) {
			// date formatters are not thread safe.  Make a copy for just this thread
			threadDefaultDateFormatter = [[defaultDateFormatter copy] autorelease];
		}
		
		NSDictionary *storeInfo;
		while ((storeInfo = [self getNextStoreToFetch]) != nil) {
			NSAutoreleasePool *innerPool = [NSAutoreleasePool new];
			NSString *countryCode = [storeInfo objectForKey:@"countryCode"];
			NSDateFormatter *dateFormatter = [storeInfo objectForKey:@"dateFormatter"];
			if (dateFormatter == nil) {
				dateFormatter = threadDefaultDateFormatter;
			}
            
			NSString *storeFrontID = [storeInfo objectForKey:@"storeFrontID"];
			NSString *storeFront = [storeFrontID stringByAppendingFormat:@"-1"];
			[headers setObject:@"iTunes/10.2.1 (Macintosh; Intel Mac OS X 10.6.7) AppleWebKit/533.20.25" forKey:@"User-Agent"];
			[headers setObject:storeFront forKey:@"X-Apple-Store-Front"];
			[request setAllHTTPHeaderFields:headers];
			[request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
					
			for (NSString *appID in [AppManager sharedManager].allAppIDs) {
				NSAutoreleasePool *singleAppPool = [NSAutoreleasePool new];
				
				NSString *reviewsURLString = [NSString stringWithFormat:@"http://ax.phobos.apple.com.edgesuite.net/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=%@&pageNumber=0&sortOrdering=4&type=Purple+Software", appID];
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
						NSString *date = [dateVersionSplitted objectAtIndex:1];
						date = [date stringByTrimmingCharactersInSet:whitespaceCharacterSet];
						reviewDate = [dateFormatter dateFromString:date];						
                        if (reviewDate == nil) {
                            NSDateFormatter *usDateFormatter = [[[NSDateFormatter alloc] init] autorelease];
                            NSLocale *usLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en-us"] autorelease];
                            [usDateFormatter setLocale:usLocale];
                            [usDateFormatter setDateFormat:@"MMM dd, yyyy"];
                            reviewDate = [usDateFormatter dateFromString:date];
                        }
					} else if (dateVersionSplitted.count == 3) {
						NSString *version = [dateVersionSplitted objectAtIndex:1];
						reviewVersion = [version stringByTrimmingCharactersInSet:whitespaceCharacterSet];
						NSString *date = [dateVersionSplitted objectAtIndex:2];
						date = [date stringByTrimmingCharactersInSet:whitespaceCharacterSet];
						reviewDate = [dateFormatter dateFromString:date];
                        if (reviewDate == nil) {
                            NSDateFormatter *usDateFormatter = [[[NSDateFormatter alloc] init] autorelease];
                            NSLocale *usLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en-us"] autorelease];
                            [usDateFormatter setLocale:usLocale];
                            [usDateFormatter setDateFormat:@"MMM dd, yyyy"];
                            reviewDate = [usDateFormatter dateFromString:date];
                        }
					}
					
					[scanner scanUpToString:@"<SetFontStyle normalStyle=\"textColor\">" intoString:NULL];
					[scanner scanString:@"<SetFontStyle normalStyle=\"textColor\">" intoString:NULL];
					[scanner scanUpToString:@"</SetFontStyle>" intoString:&reviewText];
					
					if (reviewUser && reviewTitle && reviewText && reviewStars) {
						Review *review = [[Review alloc] initWithUser:[reviewUser removeHtmlEscaping]
														   reviewDate:reviewDate
														 downloadDate:downloadDate version:reviewVersion
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
                    ReviewUpdateBundle *bundle = [[[ReviewUpdateBundle alloc] initWithAppID:appID reviews:input] autorelease];
                    [self performSelectorOnMainThread:@selector(checkIfReviewsUpToDate:) withObject:bundle waitUntilDone:YES];
                    if (bundle.needsUpdating.count) {
                        for (Review *fetchedReview in bundle.needsUpdating) {
                            [fetchedReview updateTranslations];
                        }
                        [self performSelectorOnMainThread:@selector(addReviews:) withObject:bundle waitUntilDone:YES];							
                    }
                }
				
				[singleAppPool release];
			}
			[self performSelectorOnMainThread:@selector(incrementDownloadProgress) withObject:nil waitUntilDone:NO];
			[innerPool release];
		}
	} @finally {
		[self workerDone];
		[outerPool release];
	}
}


static NSInteger numStoreReviewsComparator(id arg1, id arg2, void *arg3) {
	NSString *arg1CountryCode = [(NSDictionary*)arg1 objectForKey:@"countryCode"];
	NSString *arg2CountryCode = [(NSDictionary*)arg2 objectForKey:@"countryCode"];
	NSNumber *arg1Count = [(NSDictionary*)arg3 objectForKey:arg1CountryCode];
	NSNumber *arg2Count = [(NSDictionary*)arg3 objectForKey:arg2CountryCode];
	if (arg1Count.intValue < arg2Count.intValue) {
		return NSOrderedAscending;
	}
	if (arg1Count.intValue > arg2Count.intValue) {
		return NSOrderedDescending;
	}
	return NSOrderedSame;
}

static NSDictionary* getStoreInfoDictionary(NSString *countryCode, NSString *storeFrontID, NSDateFormatter *formatter) {
	NSString *countryName = [[NSLocale currentLocale] displayNameForKey:NSLocaleCountryCode value:countryCode];
	return [NSDictionary dictionaryWithObjectsAndKeys:
							   countryCode, @"countryCode",
							   storeFrontID, @"storeFrontID",
							   countryName, @"countryName",
							   formatter, @"dateFormatter", // formatter may be nil, so this pair must be last
							   nil];
}

- (void) resetProgressIncrement:(NSNumber*)increment {
	NSAssert([NSThread isMainThread], nil);
	percentComplete = 0;
	progressIncrement = increment.floatValue;
}

- (void) updateReviews {
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	NSAssert(! [NSThread isMainThread], nil);
#if APPSALES_DEBUG
	NSDate *start = [NSDate date];
#endif

	// setup store fronts, this should probably go into a plist...:
	NSDateFormatter *frDateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	NSLocale *frLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"fr"] autorelease];
	[frDateFormatter setLocale:frLocale];
	[frDateFormatter setDateFormat:@"dd MMM yyyy"];
	
	NSDateFormatter *deDateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	NSLocale *deLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"de"] autorelease];
	[deDateFormatter setLocale:deLocale];
	[deDateFormatter setDateFormat:@"dd.MM.yyyy"];
	
	NSDateFormatter *itDateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	NSLocale *itLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"it"] autorelease];
	[itDateFormatter setLocale:itLocale];
	[itDateFormatter setDateFormat:@"dd-MMM-yyyy"];
		
	NSDateFormatter *usDateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	NSLocale *usLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en-us"] autorelease];
	[usDateFormatter setLocale:usLocale];
	[usDateFormatter setDateFormat:@"MMM dd, yyyy"];
	
	defaultDateFormatter = [[NSDateFormatter alloc] init];
	[defaultDateFormatter setDateFormat:@"dd-MMM-yyyy"];
    [defaultDateFormatter setLocale:usLocale];
	
	storeInfos = [[NSMutableArray alloc] initWithObjects:
				  getStoreInfoDictionary(@"ae", @"143481", nil),
				  getStoreInfoDictionary(@"am", @"143524", nil),
				  getStoreInfoDictionary(@"ar", @"143505", nil),
				  getStoreInfoDictionary(@"at", @"143445", nil),
				  getStoreInfoDictionary(@"au", @"143460", nil),
				  getStoreInfoDictionary(@"bd", @"143446", nil),
				  getStoreInfoDictionary(@"be", @"143446", nil),
				  getStoreInfoDictionary(@"bg", @"143526", nil),
				  getStoreInfoDictionary(@"br", @"143503", nil),
				  getStoreInfoDictionary(@"bw", @"143525", nil),
				  getStoreInfoDictionary(@"ca", @"143455", nil),
				  getStoreInfoDictionary(@"ch", @"143459", nil),
				  getStoreInfoDictionary(@"ci", @"143527", nil),
				  getStoreInfoDictionary(@"cl", @"143483", nil),
				  getStoreInfoDictionary(@"cn", @"143465", nil),
				  getStoreInfoDictionary(@"co", @"143501", nil),
				  getStoreInfoDictionary(@"cr", @"143495", nil),
				  getStoreInfoDictionary(@"cz", @"143489", nil),
				  getStoreInfoDictionary(@"de", @"143443", deDateFormatter),
				  getStoreInfoDictionary(@"dk", @"143458", nil),
				  getStoreInfoDictionary(@"do", @"143508", nil),
				  getStoreInfoDictionary(@"ec", @"143509", nil),
				  getStoreInfoDictionary(@"ee", @"143518", nil),
				  getStoreInfoDictionary(@"eg", @"143516", nil),
				  getStoreInfoDictionary(@"es", @"143454", nil),
				  getStoreInfoDictionary(@"fi", @"143447", nil),
				  getStoreInfoDictionary(@"fr", @"143442", frDateFormatter),
				  getStoreInfoDictionary(@"gb", @"143444", nil),
				  getStoreInfoDictionary(@"gr", @"143448", nil),
				  getStoreInfoDictionary(@"gt", @"143504", nil),
				  getStoreInfoDictionary(@"hk", @"143463", nil),
				  getStoreInfoDictionary(@"hn", @"143510", nil),
				  getStoreInfoDictionary(@"hr", @"143494", nil),
				  getStoreInfoDictionary(@"hu", @"143482", nil),
				  getStoreInfoDictionary(@"id", @"143476", nil),
				  getStoreInfoDictionary(@"ie", @"143449", nil),
				  getStoreInfoDictionary(@"il", @"143491", nil),
				  getStoreInfoDictionary(@"in", @"143467", nil),
				  getStoreInfoDictionary(@"it", @"143450", itDateFormatter),
				  getStoreInfoDictionary(@"jm", @"143511", nil),
				  getStoreInfoDictionary(@"jo", @"143528", nil),
				  getStoreInfoDictionary(@"jp", @"143462", nil),
				  getStoreInfoDictionary(@"ke", @"143529", nil),
				  getStoreInfoDictionary(@"kr", @"143466", nil),
				  getStoreInfoDictionary(@"kw", @"143493", nil),
				  getStoreInfoDictionary(@"kz", @"143517", nil),
				  getStoreInfoDictionary(@"lb", @"143497", nil),
				  getStoreInfoDictionary(@"li", @"143522", nil),
				  getStoreInfoDictionary(@"lk", @"143486", nil),
				  getStoreInfoDictionary(@"lt", @"143520", nil),
				  getStoreInfoDictionary(@"lu", @"143451", nil),
				  getStoreInfoDictionary(@"lv", @"143519", nil),
				  getStoreInfoDictionary(@"md", @"143523", nil),
				  getStoreInfoDictionary(@"mg", @"143531", nil),
				  getStoreInfoDictionary(@"mk", @"143530", nil),
				  getStoreInfoDictionary(@"ml", @"143532", nil),
				  getStoreInfoDictionary(@"mo", @"143515", nil),
				  getStoreInfoDictionary(@"mt", @"143521", nil),
				  getStoreInfoDictionary(@"mu", @"143533", nil),
				  getStoreInfoDictionary(@"mv", @"143488", nil),
				  getStoreInfoDictionary(@"mx", @"143468", nil),
				  getStoreInfoDictionary(@"my", @"143473", nil),
				  getStoreInfoDictionary(@"ne", @"143534", nil),
				  getStoreInfoDictionary(@"ni", @"143512", nil),
				  getStoreInfoDictionary(@"nl", @"143452", nil),
				  getStoreInfoDictionary(@"no", @"143457", nil),
				  getStoreInfoDictionary(@"np", @"143484", nil),
				  getStoreInfoDictionary(@"nz", @"143461", nil),
				  getStoreInfoDictionary(@"pa", @"143485", nil),
				  getStoreInfoDictionary(@"pe", @"143507", nil),
				  getStoreInfoDictionary(@"ph", @"143474", nil),
				  getStoreInfoDictionary(@"pk", @"143477", nil),
				  getStoreInfoDictionary(@"pl", @"143478", nil),
				  getStoreInfoDictionary(@"pt", @"143453", nil),
				  getStoreInfoDictionary(@"py", @"143513", nil),
				  getStoreInfoDictionary(@"qa", @"143498", nil),
				  getStoreInfoDictionary(@"ro", @"143487", nil),
				  getStoreInfoDictionary(@"rs", @"143500", nil),
				  getStoreInfoDictionary(@"ru", @"143469", nil),
				  getStoreInfoDictionary(@"sa", @"143479", nil),
				  getStoreInfoDictionary(@"se", @"143456", nil),
				  getStoreInfoDictionary(@"sg", @"143464", nil),
				  getStoreInfoDictionary(@"si", @"143499", nil),
				  getStoreInfoDictionary(@"sk", @"143496", nil),
				  getStoreInfoDictionary(@"sn", @"143535", nil),
				  getStoreInfoDictionary(@"sv", @"143506", nil),
				  getStoreInfoDictionary(@"th", @"143475", nil),
				  getStoreInfoDictionary(@"tn", @"143536", nil),
				  getStoreInfoDictionary(@"tr", @"143480", nil),
				  getStoreInfoDictionary(@"tw", @"143470", nil),
				  getStoreInfoDictionary(@"ua", @"143492", nil),
				  getStoreInfoDictionary(@"ug", @"143537", nil),
				  getStoreInfoDictionary(@"us", @"143441", usDateFormatter),
				  getStoreInfoDictionary(@"uy", @"143514", nil),
				  getStoreInfoDictionary(@"ve", @"143502", nil),
				  getStoreInfoDictionary(@"vn", @"143471", nil),
				  getStoreInfoDictionary(@"za", @"143472", nil),
				  nil];
	
	// sort regions by its number of existing reviews, so the less active regions are downloaded last
	NSMutableDictionary *numExistingReviews = [NSMutableDictionary dictionary];
	for (App *app in [AppManager sharedManager].allApps) {
		for (Review *review in [app.reviewsByUser objectEnumerator]) {
			NSNumber *object = [numExistingReviews objectForKey:review.countryCode];
			const NSUInteger count = (object ? object.intValue + 1 : 1);
			[numExistingReviews setObject:[NSNumber numberWithInt:count] forKey:review.countryCode];
		}
	}
	[storeInfos sortUsingFunction:&numStoreReviewsComparator context:numExistingReviews];
	
	// increment field can only be accessed on main thread
	NSNumber *increment = [NSNumber numberWithFloat:100.0f / storeInfos.count];
	[self performSelectorOnMainThread:@selector(resetProgressIncrement:) withObject:increment waitUntilDone:NO];
	downloadDate = [NSDate new];
	
	condition = [[NSCondition alloc] init];
	numThreadsActive = NUMBER_OF_FETCHING_THREADS;
	
	[condition lock];
	for (int i=0; i < NUMBER_OF_FETCHING_THREADS; i++) {
		[self performSelectorInBackground:@selector(workerThreadFetch) withObject:nil];
	}
	[condition wait]; // wait for workers to finish (or cancel is requested)
	[condition unlock];
	
	[condition release];
	condition = nil;
	[storeInfos release];
	storeInfos = nil;
	[defaultDateFormatter release];
	defaultDateFormatter = nil;
	[downloadDate release];
	downloadDate = nil;
		
	[self performSelectorOnMainThread:@selector(finishDownloadingReviews) withObject:nil waitUntilDone:NO];
#if APPSALES_DEBUG
	NSLog(@"update took %f sec", -1*start.timeIntervalSinceNow);
#endif		
	[pool release];
}

- (void) updateReviewDownloadProgress:(NSString*)status {
//	NSAssert([NSThread isMainThread], nil);
	[status retain]; // must retain first
	[reviewDownloadStatus release];
	reviewDownloadStatus = status;
	[[NSNotificationCenter defaultCenter] postNotificationName:ReviewManagerUpdatedReviewDownloadProgressNotification object:self];
}

- (void) incrementDownloadProgress {
	percentComplete += progressIncrement;
	NSString *status = [[NSString alloc] initWithFormat:@"%2.0f%% complete", percentComplete];
	[self updateReviewDownloadProgress:status];
	[status release];
}

- (void) downloadReviews {
	NSAssert([NSThread isMainThread], nil);
	if (isDownloadingReviews) {
		return;
	}
	isDownloadingReviews = YES;
	cancelRequested = NO;
	[self updateReviewDownloadProgress:NSLocalizedString(@"Downloading reviews...",nil)];
	
	// reset new review count
	for (App *app in [[AppManager sharedManager] allApps]) {
		[app resetNewReviewCount];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ReviewManagerDownloadedReviewsNotification object:self];
	
	[self performSelectorInBackground:@selector(updateReviews) withObject:nil];
}

- (void) finishDownloadingReviews {
	NSAssert([NSThread isMainThread], nil);	
	isDownloadingReviews = NO;
	
	if (saveToDiskNeeded) {
		saveToDiskNeeded = NO;
		[[AppManager sharedManager] saveToDisk];
	}
	[self updateReviewDownloadProgress:@""];
	[[NSNotificationCenter defaultCenter] postNotificationName:ReviewManagerDownloadedReviewsNotification object:self];
}




@end
