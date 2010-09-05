#import <Foundation/Foundation.h>

#define NUMBER_OF_FETCHING_THREADS 10  // also the max number of concurrent network connections.

#define ReviewManagerDownloadedReviewsNotification					@"ReviewManagerDownloadedReviewsNotification"
#define ReviewManagerUpdatedReviewDownloadProgressNotification		@"ReviewManagerUpdatedReviewDownloadProgressNotification"

@class App;

@interface ReviewManager : NSObject {
	@private
	float percentComplete, progressIncrement; // for presentation.  can only be accessed on main thread
	
	BOOL isDownloadingReviews;
	volatile BOOL cancelRequested; // used by multile threads without synchronization, hence volatile
	volatile BOOL saveToDiskNeeded; 
	NSString *reviewDownloadStatus;
	
	// used by worker threads
	NSCondition *condition;
	NSUInteger numThreadsActive;
	NSMutableArray *storeInfos;
	NSDateFormatter *defaultDateFormatter;
	NSDate *downloadDate;
}

+ (ReviewManager*) sharedManager;

@property (readonly) NSString *reviewDownloadStatus;
@property (readonly) BOOL isDownloadingReviews;

- (void) downloadReviews;
- (void) markAllReviewsAsRead;

@end

