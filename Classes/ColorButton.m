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

@synthesize showCheckmark;

- (void)setShowCheckmark:(BOOL)_showCheckmark {
	showCheckmark = _showCheckmark;
	[self setImage:(showCheckmark ? [UIImage imageNamed:@"Checkmark"] : nil) forState:UIControlStateNormal];
}

@end
