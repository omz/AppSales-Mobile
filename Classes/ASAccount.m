//
//  Account.m
//  AppSales
//
//  Created by Ole Zorn on 30.06.11.
//  Copyright (c) 2011 omz:software. All rights reserved.
//

#import "ASAccount.h"
#import "SSKeychain.h"

#define kAccountKeychainiTunesConnect  @"iTunesConnect"
#define kAccountKeychainAppSalesMobile @"AppSalesMobile"

@implementation ASAccount

@dynamic username, vendorID, title, sortIndex, dailyReports, weeklyReports, products, payments, reportsBadge, paymentsBadge;
@synthesize isDownloadingReports, downloadStatus, downloadProgress;

- (NSString *)password {
	return [SSKeychain passwordForService:kAccountKeychainiTunesConnect account:self.username];
}

- (void)setPassword:(NSString *)password {
	[SSKeychain setPassword:password forService:kAccountKeychainiTunesConnect account:self.username];
}

- (void)deletePassword {
	[SSKeychain deletePasswordForService:kAccountKeychainiTunesConnect account:self.username];
}

- (NSString *)appPassword {
	return [SSKeychain passwordForService:kAccountKeychainAppSalesMobile account:self.username];
}

- (void)setAppPassword:(NSString *)appPassword {
	[SSKeychain setPassword:appPassword forService:kAccountKeychainAppSalesMobile account:self.username];
}

- (void)deleteAppPassword {
	[SSKeychain deletePasswordForService:kAccountKeychainAppSalesMobile account:self.username];
}

- (NSString *)displayName {
	if (self.title && ![self.title isEqualToString:@""]) {
		return self.title;
	}
	return self.username;
}

@end
