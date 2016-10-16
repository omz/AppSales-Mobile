//
//  ReviewDownloader.h
//  AppSales
//
//  Created by Nicolas Gomollon on 12/7/15.
//
//

#import <Foundation/Foundation.h>
#import "LoginManager.h"

@class ReviewDownloader, Product;

@protocol ReviewDownloaderDelegate <NSObject>

@required
- (void)reviewDownloaderDidFinish:(ReviewDownloader *)reviewDownloader;

@end

@interface ReviewDownloader : NSObject <LoginManagerDelegate> {
	Product *_product;
	NSManagedObjectID *productObjectID;
	NSManagedObjectContext *moc;
	UIBackgroundTaskIdentifier backgroundTaskID;
	NSNumber *processedRequests;
	NSNumber *totalRequests;
}

@property (nonatomic, strong) id<ReviewDownloaderDelegate> delegate;

- (instancetype)initWithProduct:(Product *)product;
- (BOOL)isDownloading;
- (void)start;

@end
