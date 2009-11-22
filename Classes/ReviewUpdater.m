#import <zlib.h>

#import "ReviewUpdater.h"
#import "App.h"
#import "Review.h"

NSString* unescapeHtmlCrap(NSString *string) { // could be a method on NSString itself
	// not a complete list of replacements
	NSMutableString *temp = [NSMutableString stringWithString:string];
	[temp replaceOccurrencesOfString:@"&#39;" withString:@"'" options:NSCaseInsensitiveSearch 
							   range:NSMakeRange(0, temp.length)];
	[temp replaceOccurrencesOfString:@"&apos;" withString:@"'" options:NSCaseInsensitiveSearch 
							   range:NSMakeRange(0, temp.length)];
	[temp replaceOccurrencesOfString:@"&#34;" withString:@"\"" options:NSCaseInsensitiveSearch 
							   range:NSMakeRange(0, temp.length)];
	[temp replaceOccurrencesOfString:@"&quot;" withString:@"\"" options:NSCaseInsensitiveSearch 
							   range:NSMakeRange(0, temp.length)];
	[temp replaceOccurrencesOfString:@"&#38;" withString:@"&" options:NSCaseInsensitiveSearch 
							   range:NSMakeRange(0, temp.length)];
	[temp replaceOccurrencesOfString:@"&amp;" withString:@"&" options:NSCaseInsensitiveSearch 
							   range:NSMakeRange(0, temp.length)];
	[temp replaceOccurrencesOfString:@"&#60;" withString:@"<" options:NSCaseInsensitiveSearch 
							   range:NSMakeRange(0, temp.length)];
	[temp replaceOccurrencesOfString:@"&lt;" withString:@"<" options:NSCaseInsensitiveSearch 
							   range:NSMakeRange(0, temp.length)];
	[temp replaceOccurrencesOfString:@"&#62;" withString:@">" options:NSCaseInsensitiveSearch 
							   range:NSMakeRange(0, temp.length)];
	[temp replaceOccurrencesOfString:@"&gt;" withString:@">" options:NSCaseInsensitiveSearch 
							   range:NSMakeRange(0, temp.length)];
	
	[temp replaceOccurrencesOfString:@"<br/>" withString:@"\n" options:NSCaseInsensitiveSearch 
							   range:NSMakeRange(0, temp.length)];
	[temp replaceOccurrencesOfString:@"&#169;" withString:@"\u00A9" options:NSCaseInsensitiveSearch 
							   range:NSMakeRange(0, temp.length)]; // copyright
	return temp;
}


@implementation ReviewUpdater

@synthesize callback; // FIXME

- (id) initWithApps:(NSDictionary*)appIDsToFetch {
	if (self = [super init]) {
		appsByID = [appIDsToFetch retain];
	}
	return self;
}

- (void) dealloc {
	[appsByID release];
	[super dealloc];
}

- (NSDictionary*) getNextStoreToFetch {
	NSDictionary *storeInfo;
	@synchronized (storeInfos) {
		storeInfo = [storeInfos lastObject];
		if (storeInfo) {
			[storeInfos removeLastObject];
		}
	}
	return storeInfo; // gcc is retarded and warns if returning inside synchronized block
}

- (void) workerDone {
	[condition lock];
	NSAssert(numThreadsActive > 0, nil);
	if (--numThreadsActive == 0) {
		[condition broadcast];
	}
	[condition unlock];	
}

- (void) addOrUpdatedReviewIfNeeded:(Review*)review appID:(NSString*)appID {
	App *app = [appsByID objectForKey:appID];
	NSAssert(app, nil);
	
	@synchronized (app) {
		NSMutableDictionary *existingReviews = app.reviewsByUser;
		Review *oldReview = [existingReviews objectForKey:review.user];
		if  ((oldReview != nil) && ([oldReview.text isEqual:review.text]) 
			 && (oldReview.translatedText != nil)) {
			return; // up to date
		}
	}
	[review updateTranslations]; // network call, done outside of synchronized block

	@synchronized (app) {
		NSMutableDictionary *existingReviews = app.reviewsByUser;
		[existingReviews setObject:review forKey:review.user];
		app.newReviewsCount += 1;
	}
}

- (void) workerThreadFetch { // called by worker threads
	NSAutoreleasePool *outerPool = [NSAutoreleasePool new];
	NSTimeInterval t = [[NSDate date] timeIntervalSince1970];
	NSDictionary *storeInfo;
	
	while ((storeInfo = [self getNextStoreToFetch]) != nil) {
		NSAutoreleasePool *innerPool = [NSAutoreleasePool new];
		NSString *countryName = [storeInfo objectForKey:@"countryName"];
		NSString *countryCode = [storeInfo objectForKey:@"countryCode"];
		NSString *status = [NSString stringWithFormat:@"%@", countryName];
		[callback performSelectorOnMainThread:@selector(updateReviewDownloadProgress:) withObject:status waitUntilDone:NO]; // FIXME
		
		for (NSString *appID in [appsByID keyEnumerator]) {
			//NSLog(@"Downloading reviews for app %@ in %@", [appIDs objectForKey:appID], countryName);
			
			NSDateFormatter *dateFormatter = [storeInfo objectForKey:@"dateFormatter"];
			if (!dateFormatter) {
				@synchronized (defaultDateFormatter) {
					dateFormatter = [[defaultDateFormatter copy] autorelease];
				}
				if ([countryCode isEqual:@"it"]) {
					NSLocale *currentLocale = [[[NSLocale alloc] initWithLocaleIdentifier:countryCode] autorelease];
					[dateFormatter setLocale:currentLocale];
				}
				else {
					[dateFormatter setLocale:defaultLocale];
				}
			}
			
			NSString *storeFrontID = [storeInfo objectForKey:@"storeFrontID"];
			NSString *storeFront = [NSString stringWithFormat:@"%@-1", storeFrontID];
			NSString *reviewsURLString = [NSString stringWithFormat:@"http://ax.phobos.apple.com.edgesuite.net/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=%@&pageNumber=0&sortOrdering=4&type=Purple+Software", appID];
			NSURL *reviewsURL = [NSURL URLWithString:reviewsURLString];
			NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:reviewsURL];
			NSMutableDictionary *headers = [NSMutableDictionary dictionary];
			[headers setObject:storeFront forKey:@"X-Apple-Store-Front"];
			[headers setObject:@"iTunes/4.2 (Macintosh; U; PPC Mac OS X 10.2)" forKey:@"User-Agent"];
			[request setAllHTTPHeaderFields:headers];
			
			NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:NULL error:NULL];
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
					reviewTitle = unescapeHtmlCrap(reviewTitle);
					reviewText = unescapeHtmlCrap(reviewText);
					Review *review = [[Review new] autorelease];
					review.downloadDate = [NSDate dateWithTimeIntervalSince1970:t - i];
					review.reviewDate = reviewDate;
					review.user = reviewUser;
					review.stars = [reviewStars intValue];
					review.title = reviewTitle;
					review.text = reviewText;
					review.version = reviewVersion;
					review.countryCode = countryCode;
					[self addOrUpdatedReviewIfNeeded:review appID:appID];
				}
				
				i++;
			} while (![scanner isAtEnd]);
		}
		[innerPool release];
	}
	
	[self workerDone];
	[outerPool release];
}

- (void) updateReviews {
//	NSAssert(resultsByAppID == nil, nil);
//	resultsByAppID = [[NSMutableDictionary alloc] initWithCapacity:appsByID.count];
//	for (NSString *appID in appsByID) {
//		[resultsByAppID setObject:[NSMutableArray array] forKey:appID];
//	}
	
	//setup store fronts, this should probably go into a plist...:
	NSDateFormatter *frenchDateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	NSLocale *frenchLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"fr"] autorelease];
	[frenchDateFormatter setLocale:frenchLocale];
	[frenchDateFormatter setDateFormat:@"dd MMM yyyy"];
	NSDateFormatter *germanDateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[germanDateFormatter setDateFormat:@"dd.MM.yyyy"];
	NSDateFormatter *usDateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	NSLocale *usLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en-us"] autorelease];
	[usDateFormatter setLocale:usLocale];
	[usDateFormatter setDateFormat:@"MMM dd, yyyy"];
	defaultDateFormatter = [[NSDateFormatter alloc] init];
	[defaultDateFormatter setDateFormat:@"dd-MMM-yyyy"];
	defaultLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en-us"];
	storeInfos = [[NSMutableArray alloc] init];

	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Argentina", @"countryName", 
						   @"ar", @"countryCode",
						   @"143505", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Belgium", @"countryName", 
						   @"be", @"countryCode",
						   @"143446", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Brazil", @"countryName", 
						   @"br", @"countryCode",
						   @"143503", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Chile", @"countryName", 
						   @"cl", @"countryCode",
						   @"143483", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"China", @"countryName", 
						   @"cn", @"countryCode",
						   @"143465", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Colombia", @"countryName", 
						   @"co", @"countryCode",
						   @"143501", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Costa Rica", @"countryName", 
						   @"cr", @"countryCode",
						   @"143495", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Czech Republic", @"countryName", 
						   @"cz", @"countryCode",
						   @"143489", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Denmark", @"countryName", 
						   @"dk", @"countryCode",
						   @"143458", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"El Salvador", @"countryName", 
						   @"sv", @"countryCode",
						   @"143506", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Finland", @"countryName", 
						   @"fi", @"countryCode",
						   @"143447", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Greece", @"countryName", 
						   @"gr", @"countryCode",
						   @"143448", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Guatemala", @"countryName", 
						   @"gt", @"countryCode",
						   @"143504", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Hong Kong", @"countryName", 
						   @"hk", @"countryCode",
						   @"143463", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Hungary", @"countryName", 
						   @"hu", @"countryCode",
						   @"143482", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"India", @"countryName", 
						   @"in", @"countryCode",
						   @"143467", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Indonesia", @"countryName", 
						   @"id", @"countryCode",
						   @"143476", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Ireland", @"countryName", 
						   @"ie", @"countryCode",
						   @"143449", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Israel", @"countryName", 
						   @"il", @"countryCode",
						   @"143491", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Korea", @"countryName", 
						   @"kr", @"countryCode",
						   @"143466", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Kuwait", @"countryName", 
						   @"kw", @"countryCode",
						   @"143493", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Lebanon", @"countryName", 
						   @"lb", @"countryCode",
						   @"143497", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Luxemburg", @"countryName", 
						   @"lu", @"countryCode",
						   @"143451", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Malaysia", @"countryName", 
						   @"my", @"countryCode",
						   @"143473", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Mexico", @"countryName", 
						   @"mx", @"countryCode",
						   @"143468", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"New Zealand", @"countryName", 
						   @"nz", @"countryCode",
						   @"143461", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Norway", @"countryName", 
						   @"no", @"countryCode",
						   @"143457", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Austria", @"countryName", 
						   @"at", @"countryCode",
						   @"143445", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Pakistan", @"countryName", 
						   @"pk", @"countryCode",
						   @"143477", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Panama", @"countryName", 
						   @"pa", @"countryCode",
						   @"143485", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Peru", @"countryName", 
						   @"pe", @"countryCode",
						   @"143507", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Phillipines", @"countryName", 
						   @"ph", @"countryCode",
						   @"143474", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Poland", @"countryName", 
						   @"pl", @"countryCode",
						   @"143478", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Portugal", @"countryName", 
						   @"pt", @"countryCode",
						   @"143453", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Qatar", @"countryName", 
						   @"qa", @"countryCode",
						   @"143498", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Romania", @"countryName", 
						   @"ro", @"countryCode",
						   @"143487", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Russia", @"countryName", 
						   @"ru", @"countryCode",
						   @"143469", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Saudi Arabia", @"countryName", 
						   @"sa", @"countryCode",
						   @"143479", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Switzerland", @"countryName", 
						   @"ch", @"countryCode",
						   @"143459", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Singapore", @"countryName", 
						   @"sg", @"countryCode",
						   @"143464", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Slovakia", @"countryName", 
						   @"sk", @"countryCode",
						   @"143496", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Slovenia", @"countryName", 
						   @"si", @"countryCode",
						   @"143499", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"South Africa", @"countryName", 
						   @"za", @"countryCode",
						   @"143472", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Sri Lanka", @"countryName", 
						   @"lk", @"countryCode",
						   @"143486", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Sweden", @"countryName", 
						   @"se", @"countryCode",
						   @"143456", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Taiwan", @"countryName", 
						   @"tw", @"countryCode",
						   @"143470", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Thailand", @"countryName", 
						   @"th", @"countryCode",
						   @"143475", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Turkey", @"countryName", 
						   @"tr", @"countryCode",
						   @"143480", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"United Arab Emirates", @"countryName", 
						   @"ae", @"countryCode",
						   @"143481", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Venezuela", @"countryName", 
						   @"ve", @"countryCode",
						   @"143502", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Vietnam", @"countryName", 
						   @"vn", @"countryCode",
						   @"143471", @"storeFrontID", 
						   nil]];
	
	// keep larger app stores at the back of the list, as they are processed from the back to the front
	
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Australia", @"countryName", 
						   @"au", @"countryCode",
						   @"143460", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Canada", @"countryName", 
						   @"ca", @"countryCode",
						   @"143455", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"United States", @"countryName", 
						   @"us", @"countryCode",
						   @"143441", @"storeFrontID",
						   usDateFormatter, @"dateFormatter",
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Germany", @"countryName", 
						   @"de", @"countryCode",
						   @"143443", @"storeFrontID",
						   germanDateFormatter, @"dateFormatter",
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Spain", @"countryName", 
						   @"es", @"countryCode",
						   @"143454", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"France", @"countryName", 
						   @"fr", @"countryCode",
						   @"143442", @"storeFrontID", 
						   frenchDateFormatter, @"dateFormatter",
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Italy", @"countryName", 
						   @"it", @"countryCode",
						   @"143450", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Netherlands", @"countryName", 
						   @"nl", @"countryCode",
						   @"143452", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"United Kingdom", @"countryName", 
						   @"gb", @"countryCode",
						   @"143444", @"storeFrontID", 
						   nil]];
	[storeInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"Japan", @"countryName", 
						   @"jp", @"countryCode",
						   @"143462", @"storeFrontID", 
						   nil]];
	
	condition = [[NSCondition alloc] init];
	numThreadsActive = NUMBER_OF_FETCHING_THREADS;
	
	for (int i=0; i < NUMBER_OF_FETCHING_THREADS; i++) {
		[self performSelectorInBackground:@selector(workerThreadFetch) withObject:nil];
	}
	
	[condition lock];
	[condition wait]; // wait for workers to finish
	[condition unlock];
			
	[condition release];
	condition = nil;
	[storeInfos release];
	storeInfos = nil;
	[defaultDateFormatter release];
	defaultDateFormatter = nil;
	[defaultLocale release];
	defaultLocale = nil;
}

@end
