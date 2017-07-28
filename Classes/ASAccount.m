//
//  Account.m
//  AppSales
//
//  Created by Ole Zorn on 30.06.11.
//  Copyright (c) 2011 omz:software. All rights reserved.
//

#import "ASAccount.h"
#import "SSKeychain.h"

#define kAccountKeychainServiceIdentifier	@"iTunesConnect"

@interface ASAccount (PrimitiveAccessors)
- (NSString *)primitiveUsername;
@end

@implementation ASAccount

@dynamic username, vendorID, title, sortIndex, dailyReports, weeklyReports, products, payments, reportsBadge, paymentsBadge;
@synthesize isDownloadingReports, downloadStatus, downloadProgress;

/*
 * For backwards compatibility, allow existing usernames to continue to be used (for things like data folder names, etc). If
 * no username is set, use the current token. If no token is set, use "default".
 */
- (NSString *)username
{
	[self willAccessValueForKey:@"username"];
	NSString *username = [self primitiveUsername];
	[self didAccessValueForKey:@"username"];
	if (!username || [username isEqualToString:@""]) {
		if (self.token && ![self.token isEqualToString:@""]) {
			return self.token;
		}
		return @"default";
	}
	return username;
}

- (NSString *)token
{
	return [SSKeychain passwordForService:kAccountKeychainServiceIdentifier account:kAccountKeychainServiceIdentifier];
}

- (void)setToken:(NSString *)token
{
	[SSKeychain setPassword:token forService:kAccountKeychainServiceIdentifier account:kAccountKeychainServiceIdentifier];
}

- (void)deleteToken
{
	[SSKeychain deletePasswordForService:kAccountKeychainServiceIdentifier account:kAccountKeychainServiceIdentifier];
}

- (void)deletePassword
{
	[SSKeychain deletePasswordForService:kAccountKeychainServiceIdentifier account:self.username];
}

- (NSString *)displayName
{
	if (self.title && ![self.title isEqualToString:@""]) {
		return self.title;
	}
	if (self.token && ![self.token isEqualToString:@""]) {
		return self.token;
	}
	return @"Default";
}

@end
