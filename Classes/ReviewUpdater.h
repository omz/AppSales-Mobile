#import <Foundation/Foundation.h>

#define NUMBER_OF_FETCHING_THREADS 10  // also the max number of concurrent network connections.

#define ReviewUpdaterDownloadedReviewsNotification					@"ReviewUpdaterDownloadedReviewsNotification"
#define ReviewUpdaterUpdatedReviewDownloadProgressNotification		@"ReviewUpdaterUpdatedReviewDownloadProgressNotification"

@class App;

@interface ReviewUpdater : NSObject {
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

+ (ReviewUpdater*) sharedManager;

@property (retain) NSString *reviewDownloadStatus;
@property (readonly) NSUInteger numberOfApps;

- (void) downloadReviews;
- (void) updateReviewDownloadProgress:(NSString *)status;
- (BOOL) isDownloadingReviews;

- (App*) appWithID:(NSString*)appID;
- (void) addApp:(App*)app;

- (NSArray*) appNamesSorted;

@end

