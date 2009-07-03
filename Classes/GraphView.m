//
//  GraphView.m
//  AppSalesMobile
//
//  Created by Ole Zorn on 15.02.09.
//  Copyright 2009 omz:software. All rights reserved.
//

#import "GraphView.h"


@implementation GraphView

@synthesize days;

- (id)initWithFrame:(CGRect)frame 
{
    if (self = [super initWithFrame:frame]) {
		self.days = [NSArray array];
		self.opaque = NO;
		self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)setDays:(NSArray *)newDays
{
	if (newDays == days)
		return;
	
	[newDays retain];
	[days release];
	days = newDays;
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect 
{
	[[UIImage imageNamed:@"GraphBackground.png"] drawAtPoint:CGPointZero];
}


- (void)dealloc 
{
	self.days = nil;
    [super dealloc];
}


@end
