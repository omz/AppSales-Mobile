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
	NSMutableDictionary *iconsByAppID;
}

+ (AppIconManager *)sharedManager;
- (UIImage *)iconForAppID:(NSString *)appID;
- (void)downloadIconForAppID:(NSString *)appID;

@end
