//
//  ReviewDownloadOperation.m
//  AppSales
//
//  Created by Nicolas Gomollon on 6/21/17.
//
//

#import "ReviewDownloadOperation.h"
#import "LoginManager.h"
#import "ASAccount.h"
#import "Product.h"
#import "Version.h"
#import "Review.h"
#import "DeveloperResponse.h"

NSString *const kITCReviewAPIRefPageAction     = @"/ra/apps/%@/platforms/%@/reviews/ref";
NSString *const kITCReviewAPIReviewsPageAction = @"/ra/apps/%@/platforms/%@/reviews?sort=REVIEW_SORT_ORDER_MOST_RECENT";

NSString *const kITCReviewAPIPlatformiOS = @"ios";
NSString *const kITCReviewAPIPlatformMac = @"osx";

@implementation ReviewDownloadOperation

- (instancetype)initWithProduct:(Product *)product {
	self = [super init];
	if (self) {
		executing = NO;
		finished = NO;
		
		_product = product;
		productObjectID = [product.objectID copy];
		
        moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
		moc.persistentStoreCoordinator = product.account.managedObjectContext.persistentStoreCoordinator;
		moc.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
		
		productVersions = [[NSMutableDictionary alloc] init];
		existingReviews = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (BOOL)isConcurrent {
	return YES;
}

- (BOOL)isExecuting {
	return executing;
}

- (BOOL)isFinished {
	return finished;
}

- (void)start {
	if (self.isCancelled) {
		[self willChangeValueForKey:@"isFinished"];
		finished = YES;
		[self didChangeValueForKey:@"isFinished"];
		[self cancelDownload];
		return;
	}
	[self willChangeValueForKey:@"isExecuting"];
	[NSThread detachNewThreadSelector:@selector(main) toTarget:self withObject:nil];
	executing = YES;
	[self didChangeValueForKey:@"isExecuting"];
}

- (void)finish {
	[self willChangeValueForKey:@"isExecuting"];
	executing = NO;
	[self didChangeValueForKey:@"isExecuting"];
	
	[self willChangeValueForKey:@"isFinished"];
	finished = YES;
	[self didChangeValueForKey:@"isFinished"];
}

- (void)main {
	if ([_product.platform.lowercaseString containsString:@"bundle"]) {
		[self failDownload];
		return;
	}
	
	[self downloadProgress:(1.0f/3.0f) withStatus:NSLocalizedString(@"Downloading reviews...", nil)];
	
	NSString *platform = [_product.platform isEqualToString:kProductPlatformMac] ? kITCReviewAPIPlatformMac : kITCReviewAPIPlatformiOS;
	NSString *refPagePath = [NSString stringWithFormat:kITCReviewAPIRefPageAction, _product.productID, platform];
	NSURL *refPageURL = [NSURL URLWithString:[kITCBaseURL stringByAppendingString:refPagePath]];
    [[NSURLSession.sharedSession dataTaskWithRequest:[NSURLRequest requestWithURL:refPageURL]
                                   completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (data) {
            NSDictionary *refPage = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            NSString *statusCode = refPage[@"statusCode"];
            if (![statusCode isEqualToString:@"SUCCESS"]) {
                
                //add product name to refPage message then continue processing other apps
                NSMutableDictionary *errDict = [[NSMutableDictionary alloc] initWithDictionary:refPage[@"messages"]];
                [errDict setObject:self->_product.name forKey:@"product"];
                
                [self showAlert:statusCode withMessages:errDict];
                [self failDownload];
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self processRefPage:refPage];
                });
            }
        } else {
            [self failDownload];
        }
    }] resume];
}

- (void)processRefPage:(NSDictionary *)refPage {
	Product *product = (Product *)[moc objectWithID:productObjectID];
	
	[productVersions removeAllObjects];
	[existingReviews removeAllObjects];
	for (Version *version in product.versions) {
		productVersions[version.number] = version;
	}
	
	refPage = refPage[@"data"];
	NSDictionary *versions = refPage[@"versions"];
	for (NSDictionary *v in versions) {
		NSString *identifier = [v[@"id"] stringValue];
		NSString *number = v[@"versionString"];
		Version *version = productVersions[number];
		if (version == nil) {
			version = (Version *)[NSEntityDescription insertNewObjectForEntityForName:@"Version" inManagedObjectContext:moc];
			version.identifier = identifier;
			version.number = number;
			version.product = product;
			productVersions[number] = version;
		} else {
			for (Review *review in version.reviews) {
				existingReviews[review.identifier] = review;
			}
		}
	}
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
		[self fetchReviews];
	});
}

- (void)fetchReviews {
	NSString *platform = [_product.platform isEqualToString:kProductPlatformMac] ? kITCReviewAPIPlatformMac : kITCReviewAPIPlatformiOS;
	NSString *reviewsPagePath = [NSString stringWithFormat:kITCReviewAPIReviewsPageAction, _product.productID, platform];
	NSURL *reviewsPageURL = [NSURL URLWithString:[kITCBaseURL stringByAppendingString:reviewsPagePath]];
    [[NSURLSession.sharedSession dataTaskWithRequest:[NSURLRequest requestWithURL:reviewsPageURL]
                                   completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (data) {
            NSDictionary *reviewsPage = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            NSString *statusCode = reviewsPage[@"statusCode"];
            if (![statusCode isEqualToString:@"SUCCESS"]) {
                
                //add product name to refPage message then continue processing other apps
                NSMutableDictionary *errDict = [[NSMutableDictionary alloc] initWithDictionary:reviewsPage[@"messages"]];
                [errDict setObject:self->_product.name forKey:@"product"];
                
                [self showAlert:statusCode withMessages:reviewsPage[@"messages"]];
                [self failDownload];
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self processReviewsPage:reviewsPage];
                });
            }
        } else {
            [self failDownload];
        }
    }] resume];
}

- (void)processReviewsPage:(NSDictionary *)reviewsPage {
	[self downloadProgress:(2.0f/3.0f) withStatus:NSLocalizedString(@"Processing reviews...", nil)];
	@synchronized(moc) {
		Product *product = (Product *)[moc objectWithID:productObjectID];
		
		reviewsPage = reviewsPage[@"data"];
		NSArray *reviews = reviewsPage[@"reviews"];
		for (__strong NSDictionary *reviewData in reviews) {
			reviewData = reviewData[@"value"];
			
			NSNumber *identifier = reviewData[@"id"];
			NSTimeInterval timeInterval = [reviewData[@"lastModified"] doubleValue];
			timeInterval /= 1000.0;
			NSDate *lastModified = [NSDate dateWithTimeIntervalSince1970:timeInterval];
			NSString *nickname = reviewData[@"nickname"];
			NSNumber *rating = reviewData[@"rating"];
			NSString *title = reviewData[@"title"];
			NSString *text = reviewData[@"review"];
			NSNumber *helpfulViews = reviewData[@"helpfulViews"];
			NSNumber *totalViews = reviewData[@"totalViews"];
			NSNumber *edited = reviewData[@"edited"];
			NSString *countryCode = reviewData[@"storeFront"];
			NSString *versionNumber = reviewData[@"appVersionString"];
			Version *version = productVersions[versionNumber];
			
			BOOL updateReview = NO;
			Review *review = existingReviews[identifier];
			if (review == nil) {
				review = (Review *)[NSEntityDescription insertNewObjectForEntityForName:@"Review" inManagedObjectContext:moc];
				review.identifier = identifier;
				review.product = product;
				review.countryCode = countryCode;
				updateReview = YES;
			} else if (([lastModified compare:review.lastModified] != NSOrderedSame) ||
					   ![version.identifier isEqualToString:review.version.identifier] ||
					   ![nickname isEqualToString:review.nickname] ||
					   (rating.intValue != review.rating.intValue) ||
					   ![title isEqualToString:review.title] ||
					   ![text isEqualToString:review.text] ||
					   (helpfulViews.intValue != review.helpfulViews.intValue) ||
					   (totalViews.intValue != review.totalViews.intValue) ||
					   (edited.boolValue != review.edited.boolValue)) {
				updateReview = YES;
			}
			if (updateReview) {
				review.lastModified = lastModified;
				review.version = version;
				review.nickname = nickname;
				review.rating = rating;
				review.title = title;
				review.text = text;
				review.helpfulViews = helpfulViews;
				review.totalViews = totalViews;
				review.edited = edited;
				review.unread = @(YES);
				[[version mutableSetValueForKey:@"reviews"] addObject:review];
				[[product mutableSetValueForKey:@"reviews"] addObject:review];
			}
			
			NSDictionary *devResp = reviewData[@"developerResponse"];
			if ((devResp != nil) && ![devResp isEqual:[NSNull null]]) {
				// Developer response was posted.
				NSNumber *identifier = devResp[@"responseId"];
				NSTimeInterval timeInterval = [devResp[@"lastModified"] doubleValue];
				timeInterval /= 1000.0;
				NSDate *lastModified = [NSDate dateWithTimeIntervalSince1970:timeInterval];
				NSString *text = devResp[@"response"];
				NSString *pendingState = devResp[@"pendingState"];
				
				DeveloperResponse *developerResponse = review.developerResponse;
				if (developerResponse == nil) {
					developerResponse = (DeveloperResponse *)[NSEntityDescription insertNewObjectForEntityForName:@"DeveloperResponse" inManagedObjectContext:moc];
					developerResponse.identifier = identifier;
					developerResponse.lastModified = lastModified;
					developerResponse.text = text;
					developerResponse.pendingState = pendingState;
				} else {
					if ([lastModified compare:developerResponse.lastModified] != NSOrderedSame) {
						developerResponse.lastModified = lastModified;
					}
					if (![text isEqualToString:developerResponse.text]) {
						developerResponse.text = text;
					}
					if (![pendingState isEqualToString:developerResponse.pendingState]) {
						developerResponse.pendingState = pendingState;
					}
				}
				developerResponse.review = review;
				review.developerResponse = developerResponse;
			} else {
				// Developer response was deleted.
				DeveloperResponse *developerResponse = review.developerResponse;
				if (developerResponse != nil) {
					[moc deleteObject:developerResponse];
				}
			}
		}
		
		[moc.persistentStoreCoordinator performBlockAndWait:^{
			NSError *saveError = nil;
			[moc save:&saveError];
			if (saveError) {
				NSLog(@"Could not save context: %@", saveError);
			}
		}];
	}
	[self completeDownload];
}

#pragma mark - Alert Helper Methods

- (void)showErrorWithMessage:(NSString *)message {
	[self showAlertWithTitle:NSLocalizedString(@"Error", nil) message:message];
}

- (void)showAlert:(NSString *)title withMessages:(NSDictionary *)messages {
	NSMutableArray *errorMessage = [[NSMutableArray alloc] init];
	NSString *appName = @"";
	for (NSString *type in messages.allKeys) {
		if ([type isEqualToString:@"product"]) {
			appName = messages[type];
		}
		else {
			NSArray *message = messages[type];
			if ((message != nil) && ![message isEqual:[NSNull null]]) {
				[errorMessage addObjectsFromArray:message];
			}
		}
	}
	
	if (appName.length > 0) {
		[errorMessage insertObject:appName atIndex:0];
	}
	[self showAlertWithTitle:title message:[errorMessage componentsJoinedByString:@"\n"]];
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
	dispatch_async(dispatch_get_main_queue(), ^{
		UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
																				 message:message
																		  preferredStyle:UIAlertControllerStyleAlert];
		[alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:nil]];
		[alertController show];
	});
}

#pragma mark - Progress Helper Methods

- (void)downloadProgress:(CGFloat)progress withStatus:(NSString *)status {
	if (self.delegate) {
		[self.delegate downloadProgress:progress withStatus:status];
	}
}


- (void)cancelDownload {
	[self completeDownloadWithStatus:NSLocalizedString(@"Cancelled", nil)];
}

- (void)failDownload {
	dispatch_async(dispatch_get_main_queue(), ^{
		[self completeDownloadWithStatus:NSLocalizedString(@"Failed", nil)];
	});
}

- (void)completeDownload {
	[self completeDownloadWithStatus:NSLocalizedString(@"Finished", nil)];
}

- (void)completeDownloadWithStatus:(NSString *)status {
	[self finish];
	if (self.delegate) {
		[self.delegate completeDownloadWithStatus:status];
	}
}

@end
