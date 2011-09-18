//
//  UIColor+Extensions.h
//  AppSales
//
//  Created by Ole Zorn on 17.04.10.
//  Copyright 2010 omz:software. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface UIColor (ASExtensions)

//Returns an array of the crayon colors in the Mac color picker, intended to be used in a grid of 6 rows with 8 colors each.
+ (NSArray *)crayonColorPalette;

//Adapted from http://arstechnica.com/apple/guides/2009/02/iphone-development-accessing-uicolor-components.ars
+ (UIColor *)randomColor;
- (BOOL)red:(CGFloat *)red green:(CGFloat *)green blue:(CGFloat *)blue alpha:(CGFloat *)alpha;
- (UIColor *)colorByMultiplyingBy:(CGFloat)f;
- (CGFloat)luminance;

@end
