//
//  DarkModeCheck.h
//  AppSales
//
//  Created by Mr Qwirk on 16/1/20.
//  Copyright © 2020 omz:software. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DarkModeCheck : NSObject

+ (BOOL)deviceIsInDarkMode;
+ (UIImage *)checkForDarkModeImage:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
