//
//  IconManager.m
//  AppSales
//
//  Created by Ole Zorn on 20.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "IconManager.h"
#import "UIViewController+Alert.h"

NSString *const kITunesStoreLookupURLFormat           = @"https://itunes.apple.com/lookup?id=%@&country=%@";
NSString *const kITunesStoreBundlePageURLFormat       = @"https://apps.apple.com/app-bundle/id%@";
NSString *const kITunesStoreBundleThumbnailPathRegexPattern = @"(https:\\/\\/is[0-9]-ssl\\.mzstatic\\.com\\/image\\/thumb\\/[a-zA-Z0-9\\/\\.-]+246x0w.png)";
NSString *const kITunesStoreDefaultCountryCode        = @"us";

@implementation IconManager

- (instancetype)init {
	self = [super init];
	if (self) {
		queue = dispatch_queue_create("app icon download", nil);
		iconCache = [NSMutableDictionary new];
		downloadQueue = [NSMutableArray new];
        self.countryCode = kITunesStoreDefaultCountryCode;
		
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

- (UIImage *)resizeIcon:(UIImage *)icon {
	CGFloat iconSize = 30.0f * [UIScreen mainScreen].scale;
	CGSize newSize = CGSizeMake(iconSize, iconSize);
	UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0f);
	[icon drawInRect:CGRectMake(0.0f, 0.0f, newSize.width, newSize.height)];
	UIImage *resizedIcon = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return resizedIcon;
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
		
		void (^failureBlock)(NSString *) = ^void(NSString *appID) {
			dispatch_async(dispatch_get_main_queue(), ^{
				// There was a response, but the download was not successful, write the default icon, so that we won't try again and again...
				NSString *iconPath = [self.iconDirectory stringByAppendingPathComponent:appID];
				[UIImagePNGRepresentation([UIImage imageNamed:@"GenericApp"]) writeToFile:iconPath atomically:YES];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:IconManagerReloadFailedIconNotification object:self userInfo:@{kIconManagerReloadFailedIconNotificationAppID: appID}];
			});
		};
		
		void (^successBlock)(UIImage *, NSData *, NSString *) = ^void(UIImage *icon, NSData *iconData, NSString *appID) {
			dispatch_async(dispatch_get_main_queue(), ^{
				// Download was successful, write icon to file.
				NSString *iconPath = [self.iconDirectory stringByAppendingPathComponent:appID];
				[iconData writeToFile:iconPath atomically:YES];
                [self->iconCache setObject:icon forKey:appID];
				[[NSNotificationCenter defaultCenter] postNotificationName:IconManagerDownloadedIconNotification object:self userInfo:@{kIconManagerDownloadedIconNotificationAppID: appID}];
			});
		};
		
		// Maybe the app is a bundle?
		void (^retryAlternativePNG)(NSString *) = ^void(NSString *appID) {
			NSURL *iTunesStorePageURL = [NSURL URLWithString:[NSString stringWithFormat:kITunesStoreBundlePageURLFormat, appID]];
			NSURLRequest *iTunesStorePageRequest = [NSURLRequest requestWithURL:iTunesStorePageURL];
			
            [[NSURLSession.sharedSession dataTaskWithRequest:iTunesStorePageRequest
                                           completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                
                NSString *iTunesStorePage = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                
                if ((iTunesStorePage != nil) && (iTunesStorePage.length > 0)) {
                    NSRegularExpression *iTunesStoreThumbnailPathRegex = [NSRegularExpression regularExpressionWithPattern:kITunesStoreBundleThumbnailPathRegexPattern options:0 error:nil];
                    NSTextCheckingResult *match = [iTunesStoreThumbnailPathRegex firstMatchInString:iTunesStorePage options:0 range:NSMakeRange(0, iTunesStorePage.length-1)];
                    if (match.numberOfRanges > 0) {
                        NSRange matchRange = [match rangeAtIndex:1];
                        NSString *iTunesStoreThumbnailPath = [iTunesStorePage substringWithRange:matchRange];
                        NSURL *iTunesStoreThumbnailURL = [NSURL URLWithString:iTunesStoreThumbnailPath];
                        NSData *iconData = [[NSData alloc] initWithContentsOfURL:iTunesStoreThumbnailURL];
                        UIImage *icon = [UIImage imageWithData:iconData];
                        
                        UIImage *resizedIcon = [self resizeIcon:icon];
                        NSData *resizedIconData = UIImagePNGRepresentation(resizedIcon);
                        
                        if (resizedIcon != nil) {
                            successBlock(resizedIcon, resizedIconData, nextAppID);
                        } else {
                            failureBlock(appID);
                        }
                    } else {
                        failureBlock(appID);
                    }
                }
                else {
                    failureBlock(appID);
                }
            }] resume];
		};
        
        NSURL *iTunesStoreLookupURL = [NSURL URLWithString:[NSString stringWithFormat:kITunesStoreLookupURLFormat, nextAppID, self.countryCode]];
        NSURLRequest *iTunesStoreLookupRequest = [NSURLRequest requestWithURL:iTunesStoreLookupURL];
        
        [[NSURLSession.sharedSession dataTaskWithRequest:iTunesStoreLookupRequest
                                       completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            
            if ((data != nil) && (data.length > 0)) {
                NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
                NSArray *results = [dict objectForKey:@"results"];
                if ((results == nil) || (results.count == 0)) {
                    retryAlternativePNG(nextAppID);
                } else {
                    NSDictionary *result = [results objectAtIndex:0];
                    NSString *imageUrlStr = [result objectForKey:@"artworkUrl512"];
                    
                    NSURL *artworkURL = [NSURL URLWithString:imageUrlStr];
                    NSData *imageData = [NSData dataWithContentsOfURL:artworkURL];
                    UIImage *icon = [UIImage imageWithData:imageData];
                    
                    UIImage *resizedIcon = [self resizeIcon:icon];
                    NSData *resizedIconData = UIImagePNGRepresentation(resizedIcon);
                    
                    if (resizedIcon != nil) {
                        successBlock(resizedIcon, resizedIconData, nextAppID);
                    } else {
                        retryAlternativePNG(nextAppID);
                    }
                }
            } else {
                retryAlternativePNG(nextAppID);
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self->isDownloading = NO;
                [self dequeueDownload];
            });
            
        }] resume];
	});
}

- (void)clearIconForAppID:(NSString *)appID {
	dispatch_async(dispatch_get_main_queue(), ^{
		NSString *iconPath = [[self iconDirectory] stringByAppendingPathComponent:appID];
		[[NSFileManager defaultManager] removeItemAtPath:iconPath error:nil];
        [self->iconCache removeObjectForKey:appID];
		[[NSNotificationCenter defaultCenter] postNotificationName:IconManagerClearedIconNotification object:self userInfo:@{kIconManagerClearedIconNotificationAppID: appID}];
	});
}

@end
