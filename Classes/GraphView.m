//
//  GraphView.m
//  AppSalesMobile
//
//  Created by Ole Zorn on 15.02.09.
//  Copyright 2009 omz:software. All rights reserved.
//

#import "GraphView.h"


@implementation GraphView

- (id)initWithFrame:(CGRect)frame 
{
    if ((self = [super initWithFrame:frame]) != nil) {
		self.days = [NSArray array];
		self.opaque = NO;
		self.backgroundColor = [UIColor clearColor];
		backgroundImage = [[UIImage imageNamed:@"GraphBackground.png"] retain];
    }
    return self;
}


- (NSArray*) days {
	return days;
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
	[backgroundImage drawAtPoint:CGPointZero];
}


- (void)dealloc 
{
	self.days = nil;
	[backgroundImage release];
    [super dealloc];
}


@end
