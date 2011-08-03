//
//  UIImage+Tinting.m
//  AppSales
//
//  Created by Ole Zorn on 01.08.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "UIImage+Tinting.h"

@implementation UIImage (Tinting)

+ (UIImage *)as_tintedImageNamed:(NSString *)name color:(UIColor *)color
{
	UIImage *image = [UIImage imageNamed:name];
	CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
	UIGraphicsBeginImageContextWithOptions(rect.size, NO, image.scale);
	CGContextRef c = UIGraphicsGetCurrentContext();
	[image drawInRect:rect];
	CGContextSetFillColorWithColor(c, [color CGColor]);
	CGContextSetBlendMode(c, kCGBlendModeSourceAtop);
	CGContextFillRect(c, rect);
	UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return result;
}

@end
