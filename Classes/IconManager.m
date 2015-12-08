//
//  IconManager.m
//  AppSales
//
//  Created by Ole Zorn on 20.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "IconManager.h"

NSString *const kITunesStorePageURLFormat             = @"https://itunes.apple.com/app/id%@";
NSString *const kITunesStoreThumbnailPathRegexPattern = @"(https:\\/\\/is[0-9]-ssl\\.mzstatic\\.com\\/image\\/thumb\\/[a-zA-Z0-9\\/\\.-]+\\/source(?:\\.icns)?\\/)1024x1024sr.\\w{3,4}";
NSString *const kAppShopperThumbnailPathFormat        = @"http://cdn.appshopper.com/icons/%@/%@_larger.png";

@implementation IconManager

- (instancetype)init {
	self = [super init];
	if (self) {
		queue = dispatch_queue_create("app icon download", nil);
		iconCache = [NSMutableDictionary new];
		downloadQueue = [NSMutableArray new];
		
		BOOL isDir = NO;
		[[NSFileManager defaultManager] fileExistsAtPath:[self iconDirectory] isDirectory:&isDir];
		if (!isDir) {
			[[NSFileManager defaultManager] createDirectoryAtPath:[self iconDirectory] withIntermediateDirectories:YES attributes:nil error:nil];
		}
	}
	return self;
}

+ (instancetype)sharedManager {
	static id sharedManager = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedManager = [[self alloc] init];
	});
	return sharedManager;
}

- (NSString *)iconDirectory {
	NSString *appSupportPath = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
	NSString *iconDirectory = [appSupportPath stringByAppendingPathComponent:@"AppIcons"];
	return iconDirectory;
}

- (UIImage *)iconForAppID:(NSString *)appID {
	if ([appID length] < 4) {
		NSLog(@"Invalid app ID for icon download (%@)", appID);
		return nil;
	}
	UIImage *cachedIcon = iconCache[appID];
	if (cachedIcon) {
		return cachedIcon;
	}
	NSString *iconPath = [[self iconDirectory] stringByAppendingPathComponent:appID];
	UIImage *icon = [[UIImage alloc] initWithContentsOfFile:iconPath];
	if (icon) {
		return icon;
	}
	[downloadQueue addObject:appID];
	[self dequeueDownload];
	return [UIImage imageNamed:@"GenericApp"];
}

- (void)dequeueDownload {
	if ([downloadQueue count] == 0 || isDownloading) return;
	
	NSString *nextAppID = [downloadQueue[0] copy];
	[downloadQueue removeObjectAtIndex:0];
	
	dispatch_async(queue, ^{
		NSURL *iTunesStorePageURL = [NSURL URLWithString:[NSString stringWithFormat:kITunesStorePageURLFormat, nextAppID]];
		NSURLRequest *iTunesStorePageRequest = [NSURLRequest requestWithURL:iTunesStorePageURL];
		
		NSHTTPURLResponse *response = nil;
		NSData *iTunesStorePageData = [NSURLConnection sendSynchronousRequest:iTunesStorePageRequest returningResponse:&response error:nil];
		NSString *iTunesStorePage = [[NSString alloc] initWithData:iTunesStorePageData encoding:NSUTF8StringEncoding];
		
		void (^failureBlock)(NSString *) = ^void(NSString *appID) {
			dispatch_async(dispatch_get_main_queue(), ^{
				// There was a response, but the download was not successful, write the default icon, so that we won't try again and again...
				NSString *iconPath = [self.iconDirectory stringByAppendingPathComponent:appID];
				[UIImagePNGRepresentation([UIImage imageNamed:@"GenericApp"]) writeToFile:iconPath atomically:YES];
			});
		};
		
		void (^successBlock)(UIImage *, NSData *, NSString *) = ^void(UIImage *icon, NSData *iconData, NSString *appID) {
			dispatch_async(dispatch_get_main_queue(), ^{
				// Download was successful, write icon to file.
				NSString *iconPath = [self.iconDirectory stringByAppendingPathComponent:appID];
				[iconData writeToFile:iconPath atomically:YES];
				[iconCache setObject:icon forKey:appID];
				[[NSNotificationCenter defaultCenter] postNotificationName:IconManagerDownloadedIconNotification object:self userInfo:@{kIconManagerDownloadedIconNotificationAppID: appID}];
			});
		};
		
		void (^retryAlternativePNG)(NSString *) = ^void(NSString *appID) {
			NSString *iconThumbnailPath = [NSString stringWithFormat:kAppShopperThumbnailPathFormat, [appID substringToIndex:3], [appID substringFromIndex:3]];
			NSURL *iconThumbnailURL = [NSURL URLWithString:iconThumbnailPath];
			NSData *iconData = [[NSData alloc] initWithContentsOfURL:iconThumbnailURL];
			UIImage *icon = [UIImage imageWithData:iconData];
			if (icon != nil) {
				successBlock(icon, iconData, appID);
			} else {
				failureBlock(appID);
			}
		};
		
		if (iTunesStorePage != nil) {
			NSRegularExpression *iTunesStoreThumbnailPathRegex = [NSRegularExpression regularExpressionWithPattern:kITunesStoreThumbnailPathRegexPattern options:0 error:nil];
			NSTextCheckingResult *match = [iTunesStoreThumbnailPathRegex firstMatchInString:iTunesStorePage options:0 range:NSMakeRange(0, 3500)];
			if (match.numberOfRanges > 0) {
				CGFloat iconSize = 30.0f * [UIScreen mainScreen].scale;
				NSString *iconFile = [NSString stringWithFormat:@"%.0fx%.0f.png", iconSize, iconSize];
				
				NSRange matchRange = [match rangeAtIndex:1];
				NSString *iTunesStoreThumbnailPath = [iTunesStorePage substringWithRange:matchRange];
				iTunesStoreThumbnailPath = [iTunesStoreThumbnailPath stringByAppendingPathComponent:iconFile];
				
				NSURL *iTunesStoreThumbnailURL = [NSURL URLWithString:iTunesStoreThumbnailPath];
				NSData *iconData = [[NSData alloc] initWithContentsOfURL:iTunesStoreThumbnailURL];
				UIImage *icon = [UIImage imageWithData:iconData];
				if (icon != nil) {
					successBlock(icon, iconData, nextAppID);
				} else {
					retryAlternativePNG(nextAppID);
				}
			} else {
				retryAlternativePNG(nextAppID);
			}
		} else if (response != nil) {
			retryAlternativePNG(nextAppID);
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{
			isDownloading = NO;
			[self dequeueDownload];
		});
	});
}

- (void)clearIconForAppID:(NSString *)appID {
	dispatch_async(dispatch_get_main_queue(), ^{
		NSString *iconPath = [[self iconDirectory] stringByAppendingPathComponent:appID];
		[[NSFileManager defaultManager] removeItemAtPath:iconPath error:nil];
		[iconCache removeObjectForKey:appID];
		[[NSNotificationCenter defaultCenter] postNotificationName:IconManagerClearedIconNotification object:self userInfo:@{kIconManagerClearedIconNotificationAppID: appID}];
	});
}

@end
