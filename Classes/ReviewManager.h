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
	BOOL cancelRequested; // guarded by self synchronization
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
@property (readonly) NSUInteger numberOfApps;
@property (readonly) BOOL isDownloadingReviews;
@property (readonly) NSArray* appNamesSorted;

- (void) downloadReviews;
- (App*) appWithID:(NSString*)appID;
- (BOOL) createOrUpdateAppIfNeededWithID:(NSString*)appID name:(NSString*)appName;
- (void) addApp:(App*)app;

@end

