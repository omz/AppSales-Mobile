#import <Foundation/Foundation.h>

#define NUMBER_OF_FETCHING_THREADS 10  // also the max number of concurrent network connections.

#define ReviewManagerDownloadedReviewsNotification					@"ReviewManagerDownloadedReviewsNotification"
#define ReviewManagerUpdatedReviewDownloadProgressNotification		@"ReviewManagerUpdatedReviewDownloadProgressNotification"

@class App;

@interface ReviewManager : NSObject {
	@private
	NSMutableDictionary *appsByID;
	float percentComplete, progressIncrement; // for presentation
	
	BOOL isDownloadingReviews;
	NSString *reviewDownloadStatus;
	
	// used by worker threads
	NSCondition *condition;
	NSUInteger numThreadsActive;
	NSMutableArray *storeInfos;
	NSDateFormatter *defaultDateFormatter;
}

+ (ReviewManager*) sharedManager;

@property (readonly) NSString *reviewDownloadStatus;
@property (readonly) NSUInteger numberOfApps;

- (void) downloadReviews;
- (BOOL) isDownloadingReviews;

- (App*) appWithID:(NSString*)appID;
- (void) addApp:(App*)app;

- (NSArray*) appNamesSorted;

@end

