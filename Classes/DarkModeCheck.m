//
//  DarkModeCheck.m
//  AppSales
//
//  Created by Mr Qwirk on 16/1/20.
//  Copyright © 2020 omz:software. All rights reserved.
//

#import "DarkModeCheck.h"
#import "UIImage+Tinting.h"

@implementation DarkModeCheck

+ (BOOL)deviceIsInDarkMode {
	if (@available(iOS 13.0, *)) {
		if ([[UITraitCollection currentTraitCollection] userInterfaceStyle] == UIUserInterfaceStyleDark) {
			return YES;
		}
	}
	return NO;
}

+ (UIImage *)checkForDarkModeImage:(NSString *)name {
	if ([self deviceIsInDarkMode]) {
		return [UIImage as_tintedImageNamed:name color:[UIColor colorWithWhite:0.0 alpha:0.75]];
	}
	return [UIImage imageNamed:name];
}

@end
