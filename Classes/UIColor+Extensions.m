//
//  UIColor+Extensions.m
//  AppSales
//
//  Created by Ole Zorn on 17.04.10.
//  Copyright 2010 omz:software. All rights reserved.
//

#import "UIColor+Extensions.h"


@implementation UIColor (ASExtensions)

+ (NSArray *)crayonColorPalette
{
	return [NSArray arrayWithObjects:
			[UIColor colorWithRed:0.573 green:0.067 blue:0.031 alpha:1.0],
			[UIColor colorWithRed:0.573 green:0.561 blue:0.090 alpha:1.0],
			[UIColor colorWithRed:0.047 green:0.557 blue:0.071 alpha:1.0],
			[UIColor colorWithRed:0.051 green:0.569 blue:0.573 alpha:1.0],
			[UIColor colorWithRed:0.004 green:0.122 blue:0.565 alpha:1.0],
			[UIColor colorWithRed:0.573 green:0.149 blue:0.569 alpha:1.0],
			[UIColor colorWithRed:0.569 green:0.569 blue:0.569 alpha:1.0],
			[UIColor colorWithRed:0.573 green:0.573 blue:0.573 alpha:1.0],

			[UIColor colorWithRed:0.573 green:0.318 blue:0.051 alpha:1.0],
			[UIColor colorWithRed:0.325 green:0.557 blue:0.075 alpha:1.0],
			[UIColor colorWithRed:0.047 green:0.561 blue:0.325 alpha:1.0],
			[UIColor colorWithRed:0.016 green:0.333 blue:0.569 alpha:1.0],
			[UIColor colorWithRed:0.318 green:0.129 blue:0.569 alpha:1.0],
			[UIColor colorWithRed:0.573 green:0.098 blue:0.318 alpha:1.0],
			[UIColor colorWithRed:0.475 green:0.475 blue:0.475 alpha:1.0],
			[UIColor colorWithRed:0.663 green:0.663 blue:0.663 alpha:1.0],

			[UIColor colorWithRed:0.996 green:0.145 blue:0.090 alpha:1.0],
			[UIColor colorWithRed:1.000 green:0.976 blue:0.184 alpha:1.0],
			[UIColor colorWithRed:0.114 green:0.969 blue:0.153 alpha:1.0],
			[UIColor colorWithRed:0.118 green:0.992 blue:0.996 alpha:1.0],
			[UIColor colorWithRed:0.012 green:0.243 blue:0.988 alpha:1.0],
			[UIColor colorWithRed:0.996 green:0.286 blue:0.992 alpha:1.0],
			[UIColor colorWithRed:0.373 green:0.369 blue:0.373 alpha:1.0],
			[UIColor colorWithRed:0.753 green:0.753 blue:0.753 alpha:1.0],

			[UIColor colorWithRed:0.996 green:0.573 blue:0.125 alpha:1.0],
			[UIColor colorWithRed:0.580 green:0.973 blue:0.165 alpha:1.0],
			[UIColor colorWithRed:0.114 green:0.976 blue:0.584 alpha:1.0],
			[UIColor colorWithRed:0.059 green:0.600 blue:0.988 alpha:1.0],
			[UIColor colorWithRed:0.573 green:0.259 blue:0.988 alpha:1.0],
			[UIColor colorWithRed:0.996 green:0.200 blue:0.573 alpha:1.0],
			[UIColor colorWithRed:0.259 green:0.259 blue:0.259 alpha:1.0],
			[UIColor colorWithRed:0.839 green:0.839 blue:0.839 alpha:1.0],

			[UIColor colorWithRed:0.996 green:0.494 blue:0.482 alpha:1.0],
			[UIColor colorWithRed:1.000 green:0.984 blue:0.502 alpha:1.0],
			[UIColor colorWithRed:0.486 green:0.976 blue:0.494 alpha:1.0],
			[UIColor colorWithRed:0.486 green:0.992 blue:0.996 alpha:1.0],
			[UIColor colorWithRed:0.478 green:0.518 blue:0.988 alpha:1.0],
			[UIColor colorWithRed:0.996 green:0.533 blue:0.992 alpha:1.0],
			[UIColor colorWithRed:0.129 green:0.129 blue:0.129 alpha:1.0],
			[UIColor colorWithRed:0.922 green:0.922 blue:0.922 alpha:1.0],

			[UIColor colorWithRed:0.996 green:0.827 blue:0.494 alpha:1.0],
			[UIColor colorWithRed:0.839 green:0.980 blue:0.498 alpha:1.0],
			[UIColor colorWithRed:0.486 green:0.984 blue:0.839 alpha:1.0],
			[UIColor colorWithRed:0.482 green:0.843 blue:0.996 alpha:1.0],
			[UIColor colorWithRed:0.835 green:0.525 blue:0.992 alpha:1.0],
			[UIColor colorWithRed:0.996 green:0.549 blue:0.843 alpha:1.0],
			[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0],
			[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0], nil];
}

+ (UIColor *)randomColor 
{
	return [UIColor colorWithRed:(CGFloat)random() / RAND_MAX
						   green:(CGFloat)random() / RAND_MAX
							blue:(CGFloat)random() / RAND_MAX
						   alpha:1.0f];
}

- (BOOL)red:(CGFloat *)red green:(CGFloat *)green blue:(CGFloat *)blue alpha:(CGFloat *)alpha 
{
	const CGFloat *components = CGColorGetComponents(self.CGColor);
	CGFloat r,g,b,a;
	switch (CGColorSpaceGetModel(CGColorGetColorSpace(self.CGColor))) {
		case kCGColorSpaceModelMonochrome:
			r = g = b = components[0];
			a = components[1];
			break;
		case kCGColorSpaceModelRGB:
			r = components[0];
			g = components[1];
			b = components[2];
			a = components[3];
			break;
		default:
			return NO;
	}
	if (red) *red = r;
	if (green) *green = g;
	if (blue) *blue = b;
	if (alpha) *alpha = a;
	return YES;
}

- (UIColor *)colorByMultiplyingBy:(CGFloat)f 
{	
	CGFloat r,g,b,a;
	if (![self red:&r green:&g blue:&b alpha:&a]) return nil;
	return [UIColor colorWithRed:MAX(0.0, MIN(1.0, f * r))
						   green:MAX(0.0, MIN(1.0, f * g)) 
							blue:MAX(0.0, MIN(1.0, f * b))
						   alpha:a];
}


// Calculate the luminance for an arbitrary UIColor instance
- (CGFloat)luminance
{
	CGColorRef cgColor = self.CGColor;
	const CGFloat *components = CGColorGetComponents(cgColor);
	CGFloat luminance = 0.0;
	switch(CGColorSpaceGetModel(CGColorGetColorSpace(cgColor)))
	{
		case kCGColorSpaceModelMonochrome:
			// For grayscale colors, the luminance is the color value
			luminance = components[0];
			break;
			
		case kCGColorSpaceModelRGB:
			// For RGB colors, we calculate luminance assuming sRGB Primaries as per
			// http://en.wikipedia.org/wiki/Luminance_(relative)
			luminance = 0.2126 * components[0] + 0.7152 * components[1] + 0.0722 * components[2];
			break;
			
		default:
			// We don't implement support for non-gray, non-rgb colors at this time.
			// Since our only consumer is colorSortByLuminance, we return a larger than normal
			// value to ensure that these types of colors are sorted to the end of the list.
			luminance = 2.0;
	}
	return luminance;
}


@end
