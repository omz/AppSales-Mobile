//
//  MovableView.m
//  AppSales
//
//  Created by Ole Zorn on 09.04.10.
//  Copyright 2010 omz:software. All rights reserved.
//

#import "MovableView.h"


@implementation MovableView


- (id)initWithFrame:(CGRect)frame 
{
    if ((self = [super initWithFrame:frame])) {
		UIPanGestureRecognizer *recognizer = [[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)] autorelease];
		[self addGestureRecognizer:recognizer];
    }
    return self;
}

- (void)pan:(UIPanGestureRecognizer *)recognizer
{
	UIGestureRecognizerState state = recognizer.state;
	if (state == UIGestureRecognizerStateBegan) {
		[self.superview bringSubviewToFront:self];
	}
	else if (state == UIGestureRecognizerStateChanged) {
		CGPoint translation = [recognizer translationInView:self.superview];
		
		CGPoint center = self.center;
		CGPoint newCenter = CGPointMake(center.x + translation.x, center.y + translation.y);
		self.center = newCenter;
		
		[recognizer setTranslation:CGPointZero inView:self.superview];
	}
	else if (state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateFailed || state == UIGestureRecognizerStateCancelled) {
		
	}
}

- (void)dealloc 
{
    [super dealloc];
}


@end
