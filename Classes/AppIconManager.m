//
//  AppIconManager.m
//  AppSalesMobile
//
//  Created by Ole Zorn on 03.07.09.
//  Copyright 2009 omz:software. All rights reserved.
//

#import "AppIconManager.h"
#import "AppSalesUtils.h"


@implementation AppIconManager

- (id)init
{
	self = [super init];
	if (self) {
		iconsByAppID = [NSMutableDictionary new];
	}
	return self;
}

+ (AppIconManager *)sharedManager
{
	static AppIconManager *sharedManager = nil;
	if (sharedManager == nil) {
		sharedManager = [self new];
	}
	return sharedManager;
}

- (UIImage*)iconForAppNotFound
{
    return [UIImage imageNamed:@"Product.png"];
}

- (UIImage *)iconForAppID:(NSString *)appID
{
	UIImage *cachedIcon = [iconsByAppID objectForKey:appID];
	if (cachedIcon)
		return cachedIcon;
	NSString *iconPath = [getDocPath() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", appID]];
	cachedIcon = [UIImage imageWithContentsOfFile:iconPath];
	if (! cachedIcon) {
        cachedIcon = [self iconForAppNotFound]; // prevent subsequent lookups
    }
    [iconsByAppID setObject:cachedIcon forKey:appID];
	return cachedIcon;
}

- (void)downloadIconForAppID:(NSString *)appID
{
	if ([iconsByAppID objectForKey:appID] != nil) {
		return;
	}
	if (appID.length < 4) {
		NSLog(@"invalid appID: %@", appID);
		return;
	}
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://images.appshopper.com/icons/%@/%@.png",
                                       [appID substringToIndex:3], [appID substringFromIndex:3]]];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:5];

	NSData *imageData = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:nil error:nil];
	if (!imageData) {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"http://images.appshopper.com/icons/%@/%@.jpg",
                                    [appID substringToIndex:3], [appID substringFromIndex:3]]];
        [urlRequest setURL:url];
        imageData = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:nil error:nil];
    }
	if (!imageData) {
		NSLog(@"Could not get an icon for %@", appID);
		/* Don't try to look it up again this session.
		 * Don't write it to disk, so we'll check again on a subsequent launch */
		[iconsByAppID setObject:[self iconForAppNotFound] forKey:appID];
		return;
	}
	UIImage *icon = [UIImage imageWithData:imageData];
	if (icon) {
        [iconsByAppID setObject:icon forKey:appID];
        NSString *iconPath = [getDocPath() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", appID]];
        [imageData writeToFile:iconPath atomically:YES];
    } else {
        NSLog(@"Could not load icon image data for %@", appID);
    }
}

- (void)dealloc 
{
	[iconsByAppID release];
    [super dealloc];
}


@end
