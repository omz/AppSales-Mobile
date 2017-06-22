//
//  ReviewDownloadCoordinator.h
//  AppSales
//
//  Created by Nicolas Gomollon on 6/21/17.
//
//

#import <Foundation/Foundation.h>
#import "LoginManager.h"

@class ASAccount, Product;

@protocol ReviewDownloadCoordinatorDelegate <NSObject>
- (void)downloadProgress:(CGFloat)progress withStatus:(NSString *)status;
- (void)completeDownloadWithStatus:(NSString *)status;
@end

@interface ReviewDownloadCoordinator : NSObject <ReviewDownloadCoordinatorDelegate, LoginManagerDelegate> {
	ASAccount *account;
	NSArray<Product *> *products;
	NSOperationQueue *downloadQueue;
	UIBackgroundTaskIdentifier backgroundTaskID;
}

- (instancetype)initWithAccount:(ASAccount *)_account products:(NSArray<Product *> *)_products downloadQueue:(NSOperationQueue *)_downloadQueue;
- (void)start;

@end
