//
//  ReviewDownloadOperation.h
//  AppSales
//
//  Created by Nicolas Gomollon on 6/21/17.
//
//

#import <Foundation/Foundation.h>
#import "ReviewDownloadCoordinator.h"

@class Product;

@interface ReviewDownloadOperation : NSOperation {
	BOOL executing;
	BOOL finished;
	
	Product *_product;
	NSManagedObjectID *productObjectID;
	NSManagedObjectContext *moc;
	
	NSMutableDictionary *productVersions;
	NSMutableDictionary *existingReviews;
}

@property (nonatomic, strong) id<ReviewDownloadCoordinatorDelegate> delegate;

- (instancetype)initWithProduct:(Product *)product;

@end
