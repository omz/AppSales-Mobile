#import <Foundation/Foundation.h>

#define NUMBER_OF_FETCHING_THREADS 5  // also the max number of concurrent network connections.

@interface ReviewUpdater : NSObject {
	NSDictionary *appsByID;
	
	id callback; // FIXME.  Ugly hack, used to update the GUI status
	
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

