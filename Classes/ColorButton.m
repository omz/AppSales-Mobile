//
//  ColorButton.m
//  AppSales
//
//  Created by Ole Zorn on 17.04.10.
//  Copyright 2010 omz:software. All rights reserved.
//

#import "ColorButton.h"
#import "UIColor+Extensions.h"

@implementation ColorButton

@synthesize color, displayAsEllipse, showOutline;

- (void)drawRect:(CGRect)rect
{
	if (!color) return;
	if (self.highlighted) {
		[[color colorByMultiplyingBy:0.5] set];
	} else {
		[color setFill];
	}
	UIRectFill(self.bounds);
}

- (void)setColor:(UIColor *)newColor
{
	if (newColor == color) return;
	[newColor retain];
	[color release];
	color = newColor;
	[self setNeedsDisplay];
}

- (void)setHighlighted:(BOOL)flag
{
	[super setHighlighted:flag];
	[self setNeedsDisplay];
}

@end
