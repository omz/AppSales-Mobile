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
	iconsByAppName = [[NSMutableDictionary alloc] init];
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

- (UIImage *)iconForAppNamed:(NSString *)appName
{
	UIImage *cachedIcon = [iconsByAppName objectForKey:appName];
	if (cachedIcon)
		return cachedIcon;
	NSString *iconPath = [getDocPath() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", appName]];
	cachedIcon = [UIImage imageWithContentsOfFile:iconPath];
	if (!cachedIcon)
		return nil;
	[iconsByAppName setObject:cachedIcon forKey:appName];
	return cachedIcon;
}

- (void)downloadIconForAppID:(NSString *)appID appName:(NSString *)appName
{
	if ([self iconForAppNamed:appName] != nil)
		return;
	if ([appID length] < 4) {
		NSLog(@"Invalid app id");
		return;
	}
	NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://images.appshopper.com/icons/%@/%@.png", [appID substringToIndex:3], [appID substringFromIndex:3]]]];
	if (!imageData) imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://images.appshopper.com/icons/%@/%@.jpg", [appID substringToIndex:3], [appID substringFromIndex:3]]]];
	if (!imageData) return;
	UIImage *icon = [UIImage imageWithData:imageData];
	if (icon) [iconsByAppName setObject:icon forKey:appName];
	NSString *iconPath = [getDocPath() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", appName]];
	[imageData writeToFile:iconPath atomically:YES];
}

- (void)dealloc 
{
	[iconsByAppName release];
    [super dealloc];
}


@end
