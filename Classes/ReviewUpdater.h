#import <Foundation/Foundation.h>

// results of using an iPhone 3G S, on 3G network, with 3 app store applications
// update reviews from all countries:
// 1 thread  - 88 sec
// 2 thread  - 45 sec
// 3 threads - 28 sec
// 4 threads - 17 sec
// 5 threads - 16 sec
// 7 threads - 16 sec
#define NUMBER_OF_FETCHING_THREADS 5

@interface ReviewUpdater : NSObject {
	NSDictionary *appsByID;
	
	id callback; // FIXME
	
	// used by worker threads
	NSCondition *condition;
	NSUInteger numThreadsActive;
	NSMutableArray *storeInfos;
	NSDateFormatter *defaultDateFormatter;
	NSLocale *defaultLocale;
}

@property (assign) id callback; // FIXME

- (id) initWithApps:(NSDictionary*)appIDsToFetch;
- (void) updateReviews; // blocking call

@end

