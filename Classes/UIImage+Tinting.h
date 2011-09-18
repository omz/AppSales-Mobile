//
//  UIImage+Tinting.h
//  AppSales
//
//  Created by Ole Zorn on 01.08.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Tinting)

+ (UIImage *)as_tintedImageNamed:(NSString *)name color:(UIColor *)color;

@end
