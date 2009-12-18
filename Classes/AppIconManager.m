//
//  AppIconManager.m
//  AppSalesMobile
//
//  Created by Ole Zorn on 03.07.09.
//  Copyright 2009 omz:software. All rights reserved.
//

#import "AppIconManager.h"
#import "App.h" // for getDocPath()


@implementation AppIconManager

- (id)init
{
	[super init];
	iconsByAppID = [[NSMutableDictionary alloc] init];
	return self;
}

+ (AppIconManager *)sharedManager
{
	static AppIconManager *sharedManager = nil;
	if (sharedManager == nil) {
		sharedManager = [[self alloc] init];
	}
	return sharedManager;
}

- (UIImage *)iconForAppID:(NSString *)appID
{
	UIImage *cachedIcon = [iconsByAppID objectForKey:appID];
	if (cachedIcon)
		return cachedIcon;
	NSString *iconPath = [getDocPath() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", appID]];
	cachedIcon = [UIImage imageWithContentsOfFile:iconPath];
	if (!cachedIcon)
		return nil;
	[iconsByAppID setObject:cachedIcon forKey:appID];
	return cachedIcon;
}

- (void)downloadIconForAppID:(NSString *)appID
{
	if ([self iconForAppID:appID] != nil) {
		return;
	}
	if (appID.length < 4) {
		NSLog(@"Invalid app id");
		return;
	}
	NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://images.appshopper.com/icons/%@/%@.png", [appID substringToIndex:3], [appID substringFromIndex:3]]]];
	if (!imageData) imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://images.appshopper.com/icons/%@/%@.jpg", [appID substringToIndex:3], [appID substringFromIndex:3]]]];
	if (!imageData) return;
	UIImage *icon = [UIImage imageWithData:imageData];
	if (icon) [iconsByAppID setObject:icon forKey:appID];
	NSString *iconPath = [getDocPath() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", appID]];
	[imageData writeToFile:iconPath atomically:YES];
}

- (void)dealloc 
{
	[iconsByAppID release];
    [super dealloc];
}


@end
