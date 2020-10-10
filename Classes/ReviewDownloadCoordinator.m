//
//  ReviewDownloadCoordinator.m
//  AppSales
//
//  Created by Nicolas Gomollon on 6/21/17.
//
//

#import "ReviewDownloadCoordinator.h"
#import "ReviewDownloadOperation.h"
#import "ASAccount.h"
#import "Product.h"

@implementation ReviewDownloadCoordinator

- (instancetype)initWithAccount:(ASAccount *)_account products:(NSArray<Product *> *)_products downloadQueue:(NSOperationQueue *)_downloadQueue {
	self = [super init];
	if (self) {
		account = _account;
		products = _products;
		downloadQueue = _downloadQueue;
        
		[UIApplication sharedApplication].idleTimerDisabled = YES;
		backgroundTaskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^(void) {
			NSLog(@"Background task for downloading reviews has expired!");
		}];
	}
	return self;
}

- (void)start {
	if (!account.password || (account.password.length == 0)) { // Only download reviews for accounts with a login.
		NSLog(@"Login details not set for the account \"%@\". Please go to the account's settings and fill in the missing information.", account.displayName);
		[self showAlertWithTitle:NSLocalizedString(@"Missing Login Credentials", nil)
						 message:[NSString stringWithFormat:NSLocalizedString(@"You have not entered complete login credentials for the account \"%@\". Please go to the account's settings and fill in the missing information.", nil), account.displayName]];
		[self loginFailed:nil];
		return;
	}
	
	dispatch_async(dispatch_get_main_queue(), ^{
        self->account.downloadStatus = NSLocalizedString(@"Logging in...", nil);
	});
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
        LoginManager *loginManager = [[LoginManager alloc] initWithAccount:self->account];
		loginManager.shouldDeleteCookies = [[NSUserDefaults standardUserDefaults] boolForKey:kSettingDeleteCookies];
		loginManager.delegate = self;
		[loginManager logIn];
	});
}

- (void)loginSucceeded:(LoginManager *)loginManager {
	for (Product *product in products) {
		ReviewDownloadOperation *operation = [[ReviewDownloadOperation alloc] initWithProduct:product];
		operation.delegate = self;
		[downloadQueue addOperation:operation];
	}
}

- (void)loginFailed:(LoginManager *)loginManager {
	[self completeDownloadWithStatus:NSLocalizedString(@"Finished", nil)];
}

#pragma mark - Helper Methods

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
	dispatch_async(dispatch_get_main_queue(), ^{
		UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
																				 message:message
																		  preferredStyle:UIAlertControllerStyleAlert];
		[alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:nil]];
		[alertController show];
	});
}

- (void)downloadProgress:(CGFloat)progress withStatus:(NSString *)status {
	dispatch_async(dispatch_get_main_queue(), ^{
		if (status != nil) {
            self->account.downloadStatus = status;
		}
        CGFloat p = (1.0f / (CGFloat)self->products.count);
        CGFloat completed = (CGFloat)(self->products.count - self->downloadQueue.operationCount);
        self->account.downloadProgress = (p * completed) + (p * progress);
	});
}

- (void)completeDownloadWithStatus:(NSString *)status {
    dispatch_async(dispatch_get_main_queue(), ^{
        CGFloat completed = (CGFloat)(self->products.count - self->downloadQueue.operationCount);
        CGFloat progress = completed / (CGFloat)self->products.count;
        self->account.downloadStatus = status;
        self->account.downloadProgress = progress;
        if (self->downloadQueue.operationCount == 0) {
            self->account.isDownloadingReports = NO;
			[UIApplication sharedApplication].idleTimerDisabled = NO;
            if (self->backgroundTaskID != UIBackgroundTaskInvalid) {
                [[UIApplication sharedApplication] endBackgroundTask:self->backgroundTaskID];
                self->backgroundTaskID = UIBackgroundTaskInvalid;
			}
		}
	});
}

@end
