#import "ReviewManager.h"
#import "App.h"
#import "Review.h"
#import "NSString+UnescapeHtml.h"
#import "ReportManager.h"

#define REVIEW_SAVED_FILE_NAME @"ReviewApps.rev"

@implementation ReviewManager

@synthesize reviewDownloadStatus;

+ (ReviewManager*) sharedManager {
	static ReviewManager *sharedManager = nil;
	if (sharedManager == nil) {
		sharedManager = [ReviewManager new];
	}
	return sharedManager;
}

- (id) init {
	if (self = [super init]) {
		NSString *reviewsFile = [getDocPath() stringByAppendingPathComponent:REVIEW_SAVED_FILE_NAME];
		if ([[NSFileManager defaultManager] fileExistsAtPath:reviewsFile]) {
			appsByID = [[NSKeyedUnarchiver unarchiveObjectWithFile:reviewsFile] retain];
		} else {
			appsByID = [[NSMutableDictionary alloc] init];
		}
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cancel) 
													 name:UIApplicationWillTerminateNotification object:nil];
	}
	return self;
}

- (void) dealloc {
	[appsByID release];
	[super dealloc];
}

- (void) cancel {
#if APPSALES_DEBUG
	if (isDownloadingReviews) NSLog(@"cancel requested");
#endif	
	@synchronized (self) {
		cancelRequested = YES;
	}
}
- (void) resetCacelRequested {
	@synchronized (self) {
		cancelRequested = NO;
	}
}
- (BOOL) cancelWasRequested {
	BOOL value; // GCC is stupid
	@synchronized (self) {
		value = cancelRequested;
	}
	return value;
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

- (void) incrementStatusPercentage {
	float currentPercentComplete;
	@synchronized (self) {
		percentComplete += progressIncrement;
		currentPercentComplete = percentComplete;
	}
	NSString *status = [NSString stringWithFormat:@"%2.0f%% complete", currentPercentComplete];
	[self performSelectorOnMainThread:@selector(updateReviewDownloadProgress:) withObject:status waitUntilDone:NO];
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
	[[NSNotificationCenter defaultCenter] postNotificationName:ReviewManagerDownloadedReviewsNotification 
														object:[ReportManager sharedManager]];
}

- (void) addOrUpdatedReviewIfNeeded:(Review*)review appID:(NSString*)appID {
	App *app = [appsByID objectForKey:appID];
	NSAssert(app, nil);
	
	@synchronized (app) {
		NSDictionary *existingReviews = app.reviewsByUser;
		Review *oldReview = [existingReviews objectForKey:review.user];
		if  ((oldReview != nil) && ([oldReview.text isEqual:review.text]) 
			 && (oldReview.translatedText != nil)) {
			return; // up to date
		}
	}
	[review updateTranslations]; // network call, done outside of synchronized block

	@synchronized (app) {
		[app addOrReplaceReview:review];
		saveToDiskNeeded = YES;
	}
	[self performSelectorOnMainThread:@selector(notifyOfNewReviews) withObject:nil waitUntilDone:YES];
}

- (void) workerThreadFetch { // called by worker threads
	NSAutoreleasePool *outerPool = [NSAutoreleasePool new];		
	@try {
		NSAssert(! [NSThread isMainThread], nil);
		NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
		NSMutableDictionary *headers = [NSMutableDictionary dictionary];
		
		NSDictionary *storeInfo;
		while ((storeInfo = [self getNextStoreToFetch]) != nil) {
			NSString *countryCode = [storeInfo objectForKey:@"countryCode"];
			NSDateFormatter *dateFormatter = [storeInfo objectForKey:@"dateFormatter"];
			if (!dateFormatter) {
				@synchronized (defaultDateFormatter) {
					dateFormatter = [[defaultDateFormatter copy] autorelease]; // date formatters are not thread safe
				}
			}
						
			NSString *storeFrontID = [storeInfo objectForKey:@"storeFrontID"];
			NSString *storeFront = [storeFrontID stringByAppendingFormat:@"-1"];
			[headers setObject:@"iTunes/4.2 (Macintosh; U; PPC Mac OS X 10.2)" forKey:@"User-Agent"];
			[headers setObject:storeFront forKey:@"X-Apple-Store-Front"];
			[request setAllHTTPHeaderFields:headers];
			[request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
					
			for (NSString *appID in [appsByID keyEnumerator]) {
				NSString *reviewsURLString = [NSString stringWithFormat:@"http://ax.phobos.apple.com.edgesuite.net/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=%@&pageNumber=0&sortOrdering=4&type=Purple+Software", appID];
				[request setURL:[NSURL URLWithString:reviewsURLString]];
				
				NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:NULL error:NULL];
				if ([self cancelWasRequested]) { // check after making slow network call
					return;
				}
				NSString *xml = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
							
				NSScanner *scanner = [NSScanner scannerWithString:xml];
				int i = 0;
				do {
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
					reviewUser = [reviewUser stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
					
					[scanner scanUpToString:@" - " intoString:NULL];
					[scanner scanString:@" - " intoString:NULL];
					[scanner scanUpToString:@"</SetFontStyle>" intoString:&reviewDateAndVersion];
					reviewDateAndVersion = [reviewDateAndVersion stringByReplacingOccurrencesOfString:@"\n" withString:@""];
					NSArray *dateVersionSplitted = [reviewDateAndVersion componentsSeparatedByString:@"- "];
					if ([dateVersionSplitted count] == 3) {
						NSString *version = [dateVersionSplitted objectAtIndex:1];
						reviewVersion = [version stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
						NSString *date = [dateVersionSplitted objectAtIndex:2];
						date = [date stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
						reviewDate = [dateFormatter dateFromString:date];
					}
					
					[scanner scanUpToString:@"<SetFontStyle normalStyle=\"textColor\">" intoString:NULL];
					[scanner scanString:@"<SetFontStyle normalStyle=\"textColor\">" intoString:NULL];
					[scanner scanUpToString:@"</SetFontStyle>" intoString:&reviewText];
					
					if (reviewUser && reviewTitle && reviewText && reviewStars) {
						Review *review = [[[Review alloc] initWithUser:[reviewUser removeHtmlEscaping] reviewDate:reviewDate
														 downloadDate:downloadDate version:reviewVersion countryCode:countryCode
																title:[reviewTitle removeHtmlEscaping] text:[reviewText removeHtmlEscaping]
																 stars:[reviewStars intValue]] autorelease];
						[self addOrUpdatedReviewIfNeeded:review appID:appID];
					}
					i++;
					if ([self cancelWasRequested]) { // check again after potentially making another network call  
						return;
					}					
				} while (![scanner isAtEnd]);
			}
			[self incrementStatusPercentage];
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
	if ([arg1Count intValue] < [arg2Count intValue]) {
		return NSOrderedAscending;
	}
	if ([arg1Count intValue] > [arg2Count intValue]) {
		return NSOrderedDescending;
	}
	return NSOrderedSame;
}

- (void) updateReviews {
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	NSAssert(! [NSThread isMainThread], nil);
#if APPSALES_DEBUG
	NSDate *start = [NSDate date];
#endif

	// setup store fronts, this should probably go into a plist...:
	NSDateFormatter *frenchDateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	NSLocale *frenchLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"fr"] autorelease];
	[frenchDateFormatter setLocale:frenchLocale];
	[frenchDateFormatter setDateFormat:@"dd MMM yyyy"];
	
	NSDateFormatter *germanDateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	NSLocale *germanLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"de"] autorelease];
	[germanDateFormatter setLocale:germanLocale];
	[germanDateFormatter setDateFormat:@"dd.MM.yyyy"];
	
	NSDateFormatter *itDateFormatter = [[NSDateFormatter alloc] init];
	[itDateFormatter setDateFormat:@"dd-MMM-yyyy"];
	NSLocale *itLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"it"] autorelease];
	[itDateFormatter setLocale:itLocale];
		
	NSDateFormatter *usDateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	NSLocale *usLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en-us"] autorelease];
	[usDateFormatter setLocale:usLocale];
	[usDateFormatter setDateFormat:@"MMM dd, yyyy"];
	
	defaultDateFormatter = [[NSDateFormatter alloc] init];
	[defaultDateFormatter setDateFormat:@"dd-MMM-yyyy"];
    [defaultDateFormatter setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"en-us"] autorelease]];
	
	
	storeInfos = [[NSMutableArray alloc] init];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"au", @"countryCode",
						   @"143460", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"ca", @"countryCode",
						   @"143455", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"us", @"countryCode",
						   @"143441", @"storeFrontID",
						   usDateFormatter, @"dateFormatter",
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"de", @"countryCode",
						   @"143443", @"storeFrontID",
						   germanDateFormatter, @"dateFormatter",
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"es", @"countryCode",
						   @"143454", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"fr", @"countryCode",
						   @"143442", @"storeFrontID", 
						   frenchDateFormatter, @"dateFormatter",
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"it", @"countryCode",
						   @"143450", @"storeFrontID",
						   itDateFormatter, @"dateFormatter",
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"nl", @"countryCode",
						   @"143452", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"gb", @"countryCode",
						   @"143444", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"jp", @"countryCode",
						   @"143462", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"ar", @"countryCode",
						   @"143505", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"be", @"countryCode",
						   @"143446", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"br", @"countryCode",
						   @"143503", @"storeFrontID", 
						   nil]];	
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"cl", @"countryCode",
						   @"143483", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"cn", @"countryCode",
						   @"143465", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"co", @"countryCode",
						   @"143501", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"cr", @"countryCode",
						   @"143495", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"cz", @"countryCode",
						   @"143489", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"dk", @"countryCode",
						   @"143458", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"sv", @"countryCode",
						   @"143506", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"fi", @"countryCode",
						   @"143447", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"gr", @"countryCode",
						   @"143448", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"gt", @"countryCode",
						   @"143504", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"hk", @"countryCode",
						   @"143463", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"hu", @"countryCode",
						   @"143482", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"in", @"countryCode",
						   @"143467", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"id", @"countryCode",
						   @"143476", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"ie", @"countryCode",
						   @"143449", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"il", @"countryCode",
						   @"143491", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"kr", @"countryCode",
						   @"143466", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"kw", @"countryCode",
						   @"143493", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"lb", @"countryCode",
						   @"143497", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"lu", @"countryCode",
						   @"143451", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"my", @"countryCode",
						   @"143473", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"mx", @"countryCode",
						   @"143468", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"nz", @"countryCode",
						   @"143461", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"no", @"countryCode",
						   @"143457", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"at", @"countryCode",
						   @"143445", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"pk", @"countryCode",
						   @"143477", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"pa", @"countryCode",
						   @"143485", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"pe", @"countryCode",
						   @"143507", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"ph", @"countryCode",
						   @"143474", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"pl", @"countryCode",
						   @"143478", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"pt", @"countryCode",
						   @"143453", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"qa", @"countryCode",
						   @"143498", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"ro", @"countryCode",
						   @"143487", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"ru", @"countryCode",
						   @"143469", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"sa", @"countryCode",
						   @"143479", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"ch", @"countryCode",
						   @"143459", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"sg", @"countryCode",
						   @"143464", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"sk", @"countryCode",
						   @"143496", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"si", @"countryCode",
						   @"143499", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"za", @"countryCode",
						   @"143472", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"lk", @"countryCode",
						   @"143486", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"se", @"countryCode",
						   @"143456", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"tw", @"countryCode",
						   @"143470", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"th", @"countryCode",
						   @"143475", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"tr", @"countryCode",
						   @"143480", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"ae", @"countryCode",
						   @"143481", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"ve", @"countryCode",
						   @"143502", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"vn", @"countryCode",
						   @"143471", @"storeFrontID", 
						   nil]];
	//
	// stores added April 1, 2009
	//
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"hr", @"countryCode",
						   @"143494", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"do", @"countryCode",
						   @"143508", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"ec", @"countryCode",
						   @"143509", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"hn", @"countryCode",
						   @"143510", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"jm", @"countryCode",
						   @"143511", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"ni", @"countryCode",
						   @"143512", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"py", @"countryCode",
						   @"143513", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"uy", @"countryCode",
						   @"143514", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"mo", @"countryCode",
						   @"143515", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"eg", @"countryCode",
						   @"143516", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"kz", @"countryCode",
						   @"143517", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"ee", @"countryCode",
						   @"143518", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"lv", @"countryCode",
						   @"143519", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"lt", @"countryCode",
						   @"143520", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"mt", @"countryCode",
						   @"143521", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						   @"md", @"countryCode",
						   @"143523", @"storeFrontID", 
						   nil]];
	
	// add localized country name
	NSLocale *currentLocale = [NSLocale currentLocale];
	for (NSMutableDictionary *eachStore in storeInfos) {
		NSString *countryName = [currentLocale displayNameForKey:NSLocaleCountryCode 
														   value:[eachStore objectForKey:@"countryCode"]];
		[eachStore setValue:countryName forKey:@"countryName"];
	}
	
	// sort regions by its number of existing reviews, so the less active regions are downloaded last
	NSMutableDictionary *numExistingReviews = [NSMutableDictionary dictionary];
	for (App *app in [appsByID objectEnumerator]) {
		for (Review *review in [app.reviewsByUser objectEnumerator]) {
			NSNumber *object = [numExistingReviews objectForKey:review.countryCode];
			const NSUInteger count = (object ? object.intValue + 1 : 1);
			[numExistingReviews setObject:[NSNumber numberWithInt:count] forKey:review.countryCode];
		}
	}
	[storeInfos sortUsingFunction:&numStoreReviewsComparator context:numExistingReviews];
		
	percentComplete = 0;
	progressIncrement = 100.0f / storeInfos.count;
	downloadDate = [NSDate new];
	
	condition = [[NSCondition alloc] init];
	numThreadsActive = NUMBER_OF_FETCHING_THREADS;
	
	for (int i=0; i < NUMBER_OF_FETCHING_THREADS; i++) {
		[self performSelectorInBackground:@selector(workerThreadFetch) withObject:nil];
	}
	
	[condition lock];
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

- (void) updateReviewDownloadProgress:(NSString *)status {
	NSAssert([NSThread isMainThread], nil);
	[status retain];
	[reviewDownloadStatus release];
	reviewDownloadStatus = status;
	[[NSNotificationCenter defaultCenter] postNotificationName:ReviewManagerUpdatedReviewDownloadProgressNotification object:self];
}

- (void) downloadReviews {
	NSAssert([NSThread isMainThread], nil);
	if (isDownloadingReviews) {
		return;
	}
	isDownloadingReviews = YES;
	[self resetCacelRequested];
	[UIApplication sharedApplication].idleTimerDisabled = YES;	
	[self updateReviewDownloadProgress:NSLocalizedString(@"Downloading reviews...",nil)];
	
	[self performSelectorInBackground:@selector(updateReviews) withObject:nil];
}

- (BOOL) isDownloadingReviews {
	return isDownloadingReviews;
}

- (void) finishDownloadingReviews {
	NSAssert([NSThread isMainThread], nil);	
	isDownloadingReviews = NO;
	[UIApplication sharedApplication].idleTimerDisabled = NO;
	if (! [self cancelWasRequested]) {
		if (saveToDiskNeeded) {
			#if APPSALES_DEBUG
			NSLog(@"saving reviews to disk");
			#endif
			NSString *reviewsFile = [getDocPath() stringByAppendingPathComponent:REVIEW_SAVED_FILE_NAME];
			[NSKeyedArchiver archiveRootObject:appsByID toFile:reviewsFile];
			saveToDiskNeeded = NO;
		}
		[self updateReviewDownloadProgress:@""];
		[[NSNotificationCenter defaultCenter] postNotificationName:ReviewManagerDownloadedReviewsNotification object:self];
	}
}

- (App*) appWithID:(NSString*)appID {
	return [appsByID objectForKey:appID];
}

- (void) addApp:(App*)app {
	[appsByID setObject:app forKey:app.appID];
}

- (BOOL) createOrUpdateAppIfNeededWithID:(NSString*)appID name:(NSString*)appName {
	App *app = [self appWithID:appID];
	if (app == nil) {
		App *app = [[App alloc] initWithID:appID name:appName];
		[self addApp:app];
		[app release];
		return YES;
	} else if (! [app.appName isEqualToString:appName]) {
		[app updateApplicationName:appName]; // name of app has changed
	}
	return NO; // was already present
}

- (NSUInteger) numberOfApps {
	return appsByID.count;
}

- (NSArray*) appNamesSorted {
	NSArray *allApps = [appsByID allValues];
	NSSortDescriptor *appSorter = [[[NSSortDescriptor alloc] initWithKey:@"appName" ascending:YES] autorelease];
	return [allApps sortedArrayUsingDescriptors:[NSArray arrayWithObject:appSorter]];
}


@end
