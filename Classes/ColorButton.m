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
	
	UIBezierPath *roundRect = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:5.0];
	UIBezierPath *innerRect = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(self.bounds, 3, 3) cornerRadius:3];
	
	if (self.highlighted) {
		[[color colorByMultiplyingBy:0.5] set];
	} else {
		[(showOutline) ? [color colorByMultiplyingBy:0.75] : color set];
	}
	if (displayAsEllipse) {
		CGContextFillEllipseInRect(UIGraphicsGetCurrentContext(), self.bounds);
		[color set];
		CGContextFillEllipseInRect(UIGraphicsGetCurrentContext(), CGRectInset(self.bounds, 3, 3));
	} else {
		[roundRect fill];
		[color set];
		[innerRect fill];
	}
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
