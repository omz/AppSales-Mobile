#import <Foundation/Foundation.h>

#define NUMBER_OF_FETCHING_THREADS 10  // also the max number of concurrent network connections.

#define ReviewManagerDownloadedReviewsNotification					@"ReviewManagerDownloadedReviewsNotification"
#define ReviewManagerUpdatedReviewDownloadProgressNotification		@"ReviewManagerUpdatedReviewDownloadProgressNotification"

@class App;

@interface ReviewManager : NSObject {
	@private
	double percentComplete, progressIncrement; // for presentation.  can only be accessed on main thread
	NSTimeInterval timeLastFetched; // used to detect downloading twice in a row, which forces downloading all apps/regions
	
	BOOL isDownloadingReviews;
	volatile BOOL cancelRequested; // used by multile threads without synchronization, hence volatile
	NSString *reviewDownloadStatus;

	
	// used by worker threads
	NSCondition *condition;
	NSArray *allAppIds;
    NSMutableDictionary *appIDtoStoreRegion; // mapping of appID -> Dictionary(storeCountryCode -> boolShouldDownload) 
	NSUInteger numThreadsActive;
	NSMutableArray *storeInfos;
	NSDateFormatter *defaultDateFormatter;
	NSDate *downloadDate;
}

+ (ReviewManager*) sharedManager;

@property (readonly) NSString *reviewDownloadStatus;
@property (readonly) BOOL isDownloadingReviews;
@property (readwrite) BOOL skipLessActiveRegions;

- (void) downloadReviews;
- (void) markAllReviewsAsRead;

@end

