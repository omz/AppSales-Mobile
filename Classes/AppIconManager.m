//
//  AppIconManager.m
//  AppSalesMobile
//
//  Created by Ole Zorn on 03.07.09.
//  Copyright 2009 omz:software. All rights reserved.
//

#import "AppIconManager.h"


@implementation AppIconManager

- (id)init
{
	[super init];
	iconsByAppName = [[NSMutableDictionary alloc] init];
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	docPath = [[paths objectAtIndex:0] retain];
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
	NSString *iconPath = [docPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", appName]];
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
	NSString *iconPath = [docPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", appName]];
	[imageData writeToFile:iconPath atomically:YES];
}

- (void)dealloc 
{
	[docPath release];
	[iconsByAppName release];
    [super dealloc];
}


@end
