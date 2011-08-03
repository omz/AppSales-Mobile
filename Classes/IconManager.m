//
//  IconManager.m
//  AppSales
//
//  Created by Ole Zorn on 20.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "IconManager.h"

@interface IconManager ()

- (void)dequeueDownload;

@end

@implementation IconManager

- (id)init
{
    self = [super init];
    if (self) {
		queue = dispatch_queue_create("app icon download", NULL);
		iconCache = [NSMutableDictionary new];
		downloadQueue = [NSMutableArray new];
		
		BOOL isDir = NO;
		[[NSFileManager defaultManager] fileExistsAtPath:[self iconDirectory] isDirectory:&isDir];
		if (!isDir) {
			[[NSFileManager defaultManager] createDirectoryAtPath:[self iconDirectory] withIntermediateDirectories:YES attributes:nil error:NULL];
		}
	}
	return self;
}

+ (id)sharedManager
{
	static id sharedManager = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedManager = [[self alloc] init];
	});
	return sharedManager;
}

- (NSString *)iconDirectory
{
	NSString *appSupportPath = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
	NSString *iconDirectory = [appSupportPath stringByAppendingPathComponent:@"AppIcons"];
	return iconDirectory;
}

- (UIImage *)iconForAppID:(NSString *)appID
{
	if ([appID length] < 4) {
		NSLog(@"Invalid app ID for icon download (%@)", appID);
		return nil;
	}
	UIImage *cachedIcon = [iconCache objectForKey:appID];
	if (cachedIcon) {
		return cachedIcon;
	}
	NSString *iconPath = [[self iconDirectory] stringByAppendingPathComponent:appID];
	UIImage *icon = [[[UIImage alloc] initWithContentsOfFile:iconPath] autorelease];
	if (icon) {
		return icon;
	}
	[downloadQueue addObject:appID];
	[self dequeueDownload];
	return [UIImage imageNamed:@"GenericApp.png"];
}

- (void)dequeueDownload
{
	if ([downloadQueue count] == 0 || isDownloading) return;
	
	NSString *nextAppID = [[[downloadQueue objectAtIndex:0] copy] autorelease];
	[downloadQueue removeObjectAtIndex:0];
	
	dispatch_async(queue, ^ {
		NSString *iconURLStringPNG = [NSString stringWithFormat:@"http://images.appshopper.com/icons/%@/%@.png", [nextAppID substringToIndex:3], [nextAppID substringFromIndex:3]];
		NSHTTPURLResponse *response = nil;
		NSError *error = nil;
		NSData *iconData = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:iconURLStringPNG]] returningResponse:&response error:&error];
		if (!iconData) {
			response = nil; error = nil;
			NSString *iconURLStringJPG = [NSString stringWithFormat:@"http://images.appshopper.com/icons/%@/%@.jpg", [nextAppID substringToIndex:3], [nextAppID substringFromIndex:3]];
			iconData = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:iconURLStringJPG]] returningResponse:&response error:&error];
		}
		UIImage *icon = [UIImage imageWithData:iconData];
		if (iconData && icon) {
			dispatch_async(dispatch_get_main_queue(), ^ {
				//Download was successful, write icon to file
				NSString *iconPath = [[self iconDirectory] stringByAppendingPathComponent:nextAppID];
				[iconData writeToFile:iconPath atomically:YES];
				[iconCache setObject:icon forKey:nextAppID];
				[[NSNotificationCenter defaultCenter] postNotificationName:IconManagerDownloadedIconNotification object:self userInfo:[NSDictionary dictionaryWithObject:nextAppID forKey:kIconManagerDownloadedIconNotificationAppID]];
			});
		} else if (response) {
			dispatch_async(dispatch_get_main_queue(), ^ {
				//There was a response, but the download was not successful, write the default icon, so that we won't try again and again...
				NSString *defaultIconPath = [[NSBundle mainBundle] pathForResource:@"GenericApp" ofType:@"png"];
				NSString *iconPath = [[self iconDirectory] stringByAppendingPathComponent:nextAppID];
				[[NSFileManager defaultManager] copyItemAtPath:defaultIconPath toPath:iconPath error:NULL];
			});
		}
		dispatch_async(dispatch_get_main_queue(), ^ {
			isDownloading = NO;
			[self dequeueDownload];
		});
	});
}

- (void)dealloc
{
	dispatch_release(queue);
	[iconCache release];
	[super dealloc];
}

@end
