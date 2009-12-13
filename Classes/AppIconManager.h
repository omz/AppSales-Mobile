//
//  AppIconManager.h
//  AppSalesMobile
//
//  Created by Ole Zorn on 03.07.09.
//  Copyright 2009 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>

// TODO: move into the 'controller' group?

@interface AppIconManager : NSObject {
	NSMutableDictionary *iconsByAppName;
}

+ (AppIconManager *)sharedManager;
- (UIImage *)iconForAppNamed:(NSString *)appName;
- (void)downloadIconForAppID:(NSString *)appID appName:(NSString *)appName;

@end
