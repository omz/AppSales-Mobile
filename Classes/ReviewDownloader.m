//
//  ReviewDownloader.m
//  AppSales
//
//  Created by Nicolas Gomollon on 12/7/15.
//
//

#import "ReviewDownloader.h"
#import "MBProgressHUD.h"
#import "Product.h"
#import "Review.h"
#import "Version.h"

NSString *const kITCReviewAPISummaryPageAction           = @"/ra/apps/%@/reviews/summary?platform=%@";
NSString *const kITCReviewAPISummaryVersionPageAction    = @"/ra/apps/%@/reviews/summary?platform=%@&versionId=%@";
NSString *const kITCReviewAPIVersionStorefrontPageAction = @"/ra/apps/%@/reviews?platform=%@&versionId=%@&storefront=%@";

NSString *const kITCReviewAPIPlatformiOS = @"ios";
NSString *const kITCReviewAPIPlatformMac = @"osx";

@implementation ReviewDownloader

- (instancetype)initWithProduct:(Product *)product {
	self = [super init];
	if (self) {
		// Initialization code
		_product = product;
		productObjectID = [product.objectID copy];
		moc = [[NSManagedObjectContext alloc] init];
		moc.persistentStoreCoordinator = product.account.managedObjectContext.persistentStoreCoordinator;
		moc.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
		
		processedRequests = @(0);
		totalRequests = @(0);
		
		[UIApplication sharedApplication].idleTimerDisabled = YES;
		backgroundTaskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^(void) {
			NSLog(@"Background task for downloading reports has expired!");
		}];
	}
	return self;
}

- (BOOL)isDownloading {
	return (processedRequests.unsignedIntegerValue != totalRequests.unsignedIntegerValue);
}

- (void)start {
	_product.account.isDownloadingReports = YES;
	[self downloadProgress:0.0f withStatus:NSLocalizedString(@"Loading reviews...", nil)];
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
		LoginManager *loginManager = [[LoginManager alloc] initWithAccount:_product.account];
		loginManager.shouldDeleteCookies = [[NSUserDefaults standardUserDefaults] boolForKey:kSettingDeleteCookies];
		loginManager.delegate = self;
		[loginManager logIn];
	});
}

- (void)loginSucceeded {
	[self downloadProgress:0.1f withStatus:NSLocalizedString(@"Loading reviews...", nil)];
	
	MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
	hud.mode = MBProgressHUDModeDeterminateHorizontalBar;
	hud.labelText = NSLocalizedString(@"Downloading", nil);
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
		NSString *platform = [_product.platform isEqualToString:kProductPlatformMac] ? kITCReviewAPIPlatformMac : kITCReviewAPIPlatformiOS;
		NSString *summaryPagePath = [NSString stringWithFormat:kITCReviewAPISummaryPageAction, _product.productID, platform];
		NSURL *summaryPageURL = [NSURL URLWithString:[kITCBaseURL stringByAppendingString:summaryPagePath]];
		NSData *summaryPageData = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:summaryPageURL] returningResponse:nil error:nil];
		
		if (summaryPageData) {
			NSDictionary *summaryPage = [NSJSONSerialization JSONObjectWithData:summaryPageData options:0 error:nil];
			NSString *statusCode = summaryPage[@"statusCode"];
			if (![statusCode isEqualToString:@"SUCCESS"]) {
				[self showAlert:statusCode withMessages:summaryPage[@"messages"]];
			} else {
				Product *product = (Product *)[moc objectWithID:productObjectID];
				
				NSMutableDictionary *productVersions = [[NSMutableDictionary alloc] init];
				for (Version *version in product.versions) {
					productVersions[version.identifier] = version;
				}
				
				summaryPage = summaryPage[@"data"];
				NSDictionary *versions = summaryPage[@"versions"];
				for (NSString *identifier in versions) {
					Version *version = productVersions[identifier];
					if (version == nil) {
						version = (Version *)[NSEntityDescription insertNewObjectForEntityForName:@"Version" inManagedObjectContext:moc];
						version.identifier = identifier;
						version.number = versions[identifier];
						version.product = product;
					}
					[self fetchReviewsForVersion:version];
				}
			}
		}
	});
}

- (void)loginFailed {
	[self completeDownload];
}

- (void)fetchReviewsForVersion:(Version *)version {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
		NSMutableDictionary *existingReviews = [[NSMutableDictionary alloc] init];
		for (Review *review in version.reviews) {
			existingReviews[review.identifier] = review;
		}
		
		NSString *platform = [_product.platform isEqualToString:kProductPlatformMac] ? kITCReviewAPIPlatformMac : kITCReviewAPIPlatformiOS;
		NSString *summaryPagePath = [NSString stringWithFormat:kITCReviewAPISummaryVersionPageAction, _product.productID, platform, version.identifier];
		NSURL *summaryPageURL = [NSURL URLWithString:[kITCBaseURL stringByAppendingString:summaryPagePath]];
		NSData *summaryPageData = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:summaryPageURL] returningResponse:nil error:nil];
		
		if (summaryPageData) {
			NSDictionary *summaryPage = [NSJSONSerialization JSONObjectWithData:summaryPageData options:0 error:nil];
			NSString *statusCode = summaryPage[@"statusCode"];
			if (![statusCode isEqualToString:@"SUCCESS"]) {
				[self showAlert:statusCode withMessages:summaryPage[@"messages"]];
			} else {
				summaryPage = summaryPage[@"data"];
				NSArray *storeFronts = summaryPage[@"storeFronts"];
				for (NSDictionary *storeFront in storeFronts) {
					[self fetchReviewsForVersion:version storefront:storeFront[@"countryCode"] existingReviews:existingReviews];
				}
			}
		}
	});
}

- (void)fetchReviewsForVersion:(Version *)version storefront:(NSString *)countryCode existingReviews:(NSDictionary *)existingReviews {
	@synchronized(totalRequests) {
		totalRequests = @(totalRequests.unsignedIntegerValue + 1);
	}
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
		NSString *platform = [_product.platform isEqualToString:kProductPlatformMac] ? kITCReviewAPIPlatformMac : kITCReviewAPIPlatformiOS;
		NSString *versionPagePath = [NSString stringWithFormat:kITCReviewAPIVersionStorefrontPageAction, _product.productID, platform, version.identifier, countryCode];
		NSURL *versionPageURL = [NSURL URLWithString:[kITCBaseURL stringByAppendingString:versionPagePath]];
		NSData *versionPageData = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:versionPageURL] returningResponse:nil error:nil];
		
		if (versionPageData) {
			NSDictionary *versionPage = [NSJSONSerialization JSONObjectWithData:versionPageData options:0 error:nil];
			NSString *statusCode = versionPage[@"statusCode"];
			if (![statusCode isEqualToString:@"SUCCESS"]) {
				[self showAlert:statusCode withMessages:versionPage[@"messages"]];
			} else {
				@synchronized(moc) {
					Product *product = (Product *)[moc objectWithID:productObjectID];
					
					versionPage = versionPage[@"data"];
					NSArray *reviews = versionPage[@"reviews"];
					for (NSDictionary *reviewData in reviews) {
						NSNumber *identifier = reviewData[@"id"];
						NSTimeInterval timeInterval = [reviewData[@"created"] doubleValue];
						timeInterval /= 1000.0;
						NSDate *created = [NSDate dateWithTimeIntervalSince1970:timeInterval];
						NSString *nickname = reviewData[@"nickname"];
						NSNumber *rating = reviewData[@"rating"];
						NSString *title = reviewData[@"title"];
						NSString *text = reviewData[@"review"];
						
						Review *review = existingReviews[identifier];
						if (review == nil) {
							review = (Review *)[NSEntityDescription insertNewObjectForEntityForName:@"Review" inManagedObjectContext:moc];
							review.identifier = identifier;
							review.created = created;
							review.version = version;
							review.product = product;
							review.countryCode = countryCode;
							review.nickname = nickname;
							review.rating = rating;
							review.title = title;
							review.text = text;
							review.unread = @(YES);
							[[version mutableSetValueForKey:@"reviews"] addObject:review];
							[[product mutableSetValueForKey:@"reviews"] addObject:review];
						} else if (([created compare:review.created] != NSOrderedSame) ||
								   (rating.intValue != review.rating.intValue) ||
								   ![title isEqualToString:review.title] ||
								   ![text isEqualToString:review.text] ||
								   ![nickname isEqualToString:review.nickname]) {
							review.created = created;
							review.nickname = nickname;
							review.rating = rating;
							review.title = title;
							review.text = text;
							review.unread = @(YES);
							[[version mutableSetValueForKey:@"reviews"] addObject:review];
							[[product mutableSetValueForKey:@"reviews"] addObject:review];
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
			}
		}
		
		@synchronized(processedRequests) {
			processedRequests = @(processedRequests.unsignedIntegerValue + 1);
			CGFloat processedRatio = (CGFloat)processedRequests.unsignedIntegerValue;
			@synchronized(totalRequests) {
				processedRatio /= (CGFloat)totalRequests.unsignedIntegerValue;
			}
			CGFloat progress = 0.1f;
			progress += (1.0f - progress) * processedRatio;
			[self downloadProgress:progress withStatus:NSLocalizedString(@"Loading reviews...", nil)];
			if (processedRequests.unsignedIntegerValue == totalRequests.unsignedIntegerValue) {
				[self completeDownload];
			}
		}
	});
}

#pragma mark - Helper Methods

- (void)showAlert:(NSString *)title withMessages:(NSDictionary *)messages {
	NSMutableArray *errorMessage = [[NSMutableArray alloc] init];
	for (NSString *type in messages.allKeys) {
		NSArray *message = messages[type];
		if ((message != nil) && ![message isEqual:[NSNull null]]) {
			[errorMessage addObjectsFromArray:message];
		}
	}
	dispatch_async(dispatch_get_main_queue(), ^{
		UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
																				 message:[errorMessage componentsJoinedByString:@"\n"]
																		  preferredStyle:UIAlertControllerStyleAlert];
		[alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:nil]];
		[alertController show];
	});
}

- (void)showErrorWithMessage:(NSString *)message {
	dispatch_async(dispatch_get_main_queue(), ^{
		UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil)
																				 message:message
																		  preferredStyle:UIAlertControllerStyleAlert];
		[alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:nil]];
		[alertController show];
	});
}

- (void)downloadProgress:(CGFloat)progress withStatus:(NSString *)status {
	dispatch_async(dispatch_get_main_queue(), ^{
		if (status != nil) {
			_product.account.downloadStatus = status;
		}
		_product.account.downloadProgress = progress;
		
		MBProgressHUD *hud = [MBProgressHUD HUDForView:[UIApplication sharedApplication].keyWindow];
		hud.progress = progress;
	});
}

- (void)completeDownload {
	[self completeDownloadWithStatus:NSLocalizedString(@"Finished", nil)];
}

- (void)completeDownloadWithStatus:(NSString *)status {
	dispatch_async(dispatch_get_main_queue(), ^{
		if ([self.delegate respondsToSelector:@selector(reviewDownloaderDidFinish:)]) {
			[self.delegate reviewDownloaderDidFinish:self];
		}
		[MBProgressHUD hideHUDForView:[UIApplication sharedApplication].keyWindow animated:YES];
		_product.account.downloadStatus = status;
		_product.account.downloadProgress = 1.0f;
		_product.account.isDownloadingReports = NO;
		[UIApplication sharedApplication].idleTimerDisabled = NO;
		if (backgroundTaskID != UIBackgroundTaskInvalid) {
			[[UIApplication sharedApplication] endBackgroundTask:backgroundTaskID];
		}
	});
}

@end
