//
//  GraphView.m
//  AppSales
//
//  Created by Ole Zorn on 11.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "GraphView.h"
#import "MBProgressHUD.h"

#define ANIMATION_DURATION	0.4

@implementation GraphView

@synthesize delegate, dataSource;
@synthesize sectionLabelButton;

- (id)initWithFrame:(CGRect)frameRect
{
	self = [super initWithFrame:frameRect];
	if (self) {
		self.clipsToBounds = YES;
		self.backgroundColor = [UIColor clearColor];
		
		cachedValues = [NSMutableDictionary new];
		
		UIView *scaleBackgroundView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 46, self.bounds.size.height - 30)] autorelease];
		scaleBackgroundView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
		[self addSubview:scaleBackgroundView];
		
		UIView *bottomLineView = [[[UIView alloc] initWithFrame:CGRectMake(46, self.bounds.size.height - 30, self.bounds.size.width - 46, 1)] autorelease];
		bottomLineView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
		bottomLineView.backgroundColor = [UIColor lightGrayColor];
		[self addSubview:bottomLineView];
		
		scaleView = [[ScaleView alloc] initWithFrame:CGRectMake(0, 30, 46, self.bounds.size.height - 60)];
		scaleView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
		[self addSubview:scaleView];
		
		lockIndicatorView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LockIndicator.png"]];
		lockIndicatorView.frame = CGRectMake(15, 7, 16, 16);
		lockIndicatorView.hidden = YES;
		[self addSubview:lockIndicatorView];
		
		UILongPressGestureRecognizer *lockScaleRecognizer = [[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(lockScale:)] autorelease];
		[scaleView addGestureRecognizer:lockScaleRecognizer];
		
		UILongPressGestureRecognizer *longPressRecognizer = [[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)] autorelease];
		longPressRecognizer.minimumPressDuration = 1.0;
		[self addGestureRecognizer:longPressRecognizer];
		
		scrollView = [[TouchCancellingScrollView alloc] initWithFrame:CGRectMake(46, 0, self.bounds.size.width - 46, self.bounds.size.height)];
		scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		scrollView.delegate = self;
		scrollView.alwaysBounceHorizontal = YES;
		scrollView.showsVerticalScrollIndicator = NO;
		[self addSubview:scrollView];
		
		titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 4, self.bounds.size.width, 12)];
		titleLabel.font = [UIFont boldSystemFontOfSize:11.0];
		titleLabel.textAlignment = UITextAlignmentCenter;
		titleLabel.textColor = [UIColor grayColor];
		titleLabel.backgroundColor = [UIColor clearColor];
		titleLabel.shadowColor = [UIColor whiteColor];
		titleLabel.shadowOffset = CGSizeMake(0, 1);
		[self addSubview:titleLabel];
		
		self.sectionLabelButton = [UIButton buttonWithType:UIButtonTypeCustom];
		sectionLabelButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
		[self.sectionLabelButton setBackgroundImage:[UIImage imageNamed:@"DateButton.png"] forState:UIControlStateNormal];
		self.sectionLabelButton.frame = CGRectMake(0, self.bounds.size.height - 30 - 16, 46, 32);
		self.sectionLabelButton.titleLabel.font = [UIFont boldSystemFontOfSize:10.0];
		self.sectionLabelButton.titleLabel.adjustsFontSizeToFitWidth = YES;
		[self.sectionLabelButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
		[self addSubview:self.sectionLabelButton];
		
		visibleRange = NSMakeRange(NSNotFound, 0);
		barsPerPage = 7;
		visibleBarViews = [NSMutableDictionary new];
		max = -1.0;
	}
    return self;
}

- (void)longPress:(UILongPressGestureRecognizer *)recognizer
{
	if ([recognizer state] == UIGestureRecognizerStateBegan) {
		for (NSNumber *index in visibleBarViews) {
			StackedBarView *barView = [visibleBarViews objectForKey:index];
			if (CGRectContainsPoint(barView.bounds, [recognizer locationInView:barView])) {
				if ([self.delegate respondsToSelector:@selector(graphView:canDeleteBarAtIndex:)] && [self.delegate graphView:self canDeleteBarAtIndex:[index unsignedIntegerValue]]) {
					selectedBarIndexForMenu = [index unsignedIntegerValue];
					[self becomeFirstResponder];
					NSArray *menuItems = [NSArray arrayWithObject:[[[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Delete", nil) action:@selector(deleteBar:)] autorelease]];
					[[UIMenuController sharedMenuController] setMenuItems:menuItems];
				
					CGRect targetRect = [barView convertRect:barView.bounds toView:self];
					[[UIMenuController sharedMenuController] setTargetRect:targetRect inView:self];
					[[UIMenuController sharedMenuController] setMenuVisible:YES animated:YES];
				}
			}
		}
	}
}

- (void)deleteBar:(id)sender
{
	if ([self.delegate respondsToSelector:@selector(graphView:deleteBarAtIndex:)]) {
		[self.delegate graphView:self deleteBarAtIndex:selectedBarIndexForMenu];
	}
}

- (BOOL)canBecomeFirstResponder
{
	return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
	if (action == @selector(deleteBar:)) return YES;
	return NO;
}


- (void)setTitle:(NSString *)title
{
	titleLabel.text = title;
}

- (NSString *)title
{
	return titleLabel.text;
}

- (void)lockScale:(UILongPressGestureRecognizer *)recognizer
{
	if (recognizer.state == UIGestureRecognizerStateBegan) {
		maxLocked = !maxLocked;
		[MBProgressHUD hideHUDForView:self animated:YES];
		
		MBProgressHUD *hud = [[[MBProgressHUD alloc] initWithView:self] autorelease];
		hud.animationType = MBProgressHUDAnimationZoom;
		hud.customView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:(maxLocked) ? @"Lock.png" : @"Unlock.png"]] autorelease];
		hud.mode = MBProgressHUDModeCustomView;
		if (maxLocked) {
			hud.labelText = NSLocalizedString(@"Scale locked", nil);
		} else {
			hud.labelText = NSLocalizedString(@"Scale unlocked", nil);
		}
		hud.userInteractionEnabled = NO;
		[self addSubview:hud];
		[hud show:YES];
		
		lockIndicatorView.hidden = !maxLocked;
		if (!maxLocked) {
			[self reloadValuesAnimated:YES];
		}
		
		[NSObject cancelPreviousPerformRequestsWithTarget:self];
		[self performSelector:@selector(hideHUD) withObject:nil afterDelay:1.5];
	}
}

- (void)hideHUD
{
	[MBProgressHUD hideHUDForView:self animated:YES];
}

- (void)barSelected:(StackedBarView *)barView
{
	if ([[UIMenuController sharedMenuController] isMenuVisible]) return;
	
	for (NSNumber *barIndex in visibleBarViews) {
		StackedBarView *view = [visibleBarViews objectForKey:barIndex];
		if (view == barView) {
			[self.delegate graphView:self didSelectBarAtIndex:[barIndex unsignedIntegerValue]];
			break;
		}
	}
}

- (NSString *)unit
{
	return scaleView.unit;
}

- (void)setUnit:(NSString *)unit
{
	[scaleView setUnit:unit];
}


- (void)reloadData
{
	[cachedValues removeAllObjects];
	
	NSUInteger numberOfBars = [self.dataSource numberOfBarsInGraphView:self];
	
	CGFloat contentWidth = numberOfBars * barWidth;
	scrollView.contentSize = CGSizeMake(contentWidth, 0);
	
	for (UIView *barView in [visibleBarViews allValues]) {
		[barView removeFromSuperview];
	}
	[visibleBarViews removeAllObjects];
	
	visibleRange = NSMakeRange(NSNotFound, 0);
	max = -1.0;
	
	scrollView.contentOffset = CGPointMake(MAX(0, scrollView.contentSize.width - scrollView.bounds.size.width), 0);
	[self scrollViewDidScroll:scrollView];
	
	[scrollView flashScrollIndicators];
}


- (void)reloadValuesAnimated:(BOOL)animated
{
	[cachedValues removeAllObjects];
	
	if (!maxLocked) {
		max = 0.0;
		for (NSNumber *barIndex in visibleBarViews) {
			NSArray *stackedValues = [self.dataSource graphView:self valuesForBarAtIndex:[barIndex unsignedIntegerValue]];
			float sum = [[stackedValues valueForKeyPath:@"@sum.self"] floatValue];
			if (sum > max) max = sum;
		}
	}
	
	if (animated) {
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:ANIMATION_DURATION];
		[UIView setAnimationBeginsFromCurrentState:YES];
	}
	for (NSNumber *barIndex in visibleBarViews) {
		StackedBarView *barView = [visibleBarViews objectForKey:barIndex];
		NSArray *stackedValues = [self stackedValuesForBarAtIndex:[barIndex unsignedIntegerValue]];
		[barView setSegmentValues:stackedValues label:[self labelTextForIndex:[barIndex unsignedIntegerValue]]];
	}
	[scaleView setMax:max animated:YES];
	if (animated) {
		[UIView commitAnimations];
	}
}

- (void)setFrame:(CGRect)frame
{
	[super setFrame:frame];
	[self scrollViewDidScroll:scrollView];
}

- (void)setNumberOfBarsPerPage:(int)newBarsPerPage
{
	barsPerPage = newBarsPerPage;
	barWidth = scrollView.bounds.size.width / barsPerPage;
	[self reloadData];
}

- (NSRange)visibleBarRange
{
	NSUInteger numberOfBars = [self.dataSource numberOfBarsInGraphView:self];
	barsPerPage = scrollView.bounds.size.width / barWidth;
	int firstVisibleBarIndex = MIN(numberOfBars, MAX(0, scrollView.contentOffset.x / barWidth));
	NSRange newVisibleRange = NSMakeRange(firstVisibleBarIndex, barsPerPage + 1);
	if (newVisibleRange.location + newVisibleRange.length >= numberOfBars) {
		newVisibleRange.length = numberOfBars - newVisibleRange.location;
	}
	return newVisibleRange;
}

- (float)maxVisibleValue
{
	float maxValue = 0.0;
	for (int i = visibleRange.location; i < visibleRange.location + visibleRange.length; i++) {
		NSArray *stackedValues = [self.dataSource graphView:self valuesForBarAtIndex:i];
		float sum = [[stackedValues valueForKeyPath:@"@sum.self"] floatValue];
		if (sum > maxValue) maxValue = sum;
	}
	return maxValue;
}

- (CGRect)frameForBarAtIndex:(int)index
{
	float marginBottom = 30.0;
	CGRect barFrame =  CGRectMake(barWidth * index, 0, barWidth, self.bounds.size.height - marginBottom);
	return CGRectIntegral(barFrame);
}

- (NSString *)labelTextForIndex:(NSUInteger)index
{
	if (barWidth < 20) return nil;
	NSString *labelText = [self.dataSource graphView:self labelForBarAtIndex:index];
	return labelText;
}

- (void)reloadColors
{
	for (UIView *barView in [visibleBarViews allValues]) {
		[barView removeFromSuperview];
	}
	[visibleBarViews removeAllObjects];
	
	visibleRange = NSMakeRange(NSNotFound, 0);
	
	[self scrollViewDidScroll:scrollView];
}

- (void)scrollViewDidScroll:(UIScrollView *)aScrollView
{
	NSRange newVisibleRange = [self visibleBarRange];
	if (NSEqualRanges(newVisibleRange, visibleRange)) {
		return;
	}
	visibleRange = newVisibleRange;
	
	if (max < 0.0) {
		max = [self maxVisibleValue];
		[scaleView setMax:max animated:NO];
	}
	
	NSString *sectionLabelText = [self.dataSource graphView:self labelForSectionAtIndex:visibleRange.location];
	[self.sectionLabelButton setTitle:sectionLabelText forState:UIControlStateNormal];
	
	//Remove views that are no longer visible:
	for (NSNumber *visibleBarIndex in [visibleBarViews allKeys]) {
		if (!NSLocationInRange([visibleBarIndex intValue], visibleRange)) {
			UIView *barView = [visibleBarViews objectForKey:visibleBarIndex];
			[barView removeFromSuperview];
			[visibleBarViews removeObjectForKey:visibleBarIndex];
		}
	}
	
	//Add views that are visible now:
	for (int i=visibleRange.location; i<visibleRange.location+visibleRange.length; i++) {
		StackedBarView *barView = [visibleBarViews objectForKey:[NSNumber numberWithInt:i]];
		CGRect frameForBar = [self frameForBarAtIndex:i];
		if (!barView) {
			NSArray *colors = [self.dataSource colorsForGraphView:self];
			
			barView = [[[StackedBarView alloc] initWithColors:colors] autorelease];
			[barView addTarget:self action:@selector(barSelected:) forControlEvents:UIControlEventTouchUpInside];
			barView.frame = frameForBar;
			barView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
			
			UILabel *dateLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, frameForBar.size.height, frameForBar.size.width, 20)] autorelease];
			dateLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
			dateLabel.backgroundColor = [UIColor clearColor];
			dateLabel.textColor = [UIColor darkGrayColor];
			dateLabel.shadowColor = [UIColor whiteColor];
			dateLabel.shadowOffset = CGSizeMake(0, 1);
			dateLabel.textAlignment = UITextAlignmentCenter;
			dateLabel.font = [UIFont boldSystemFontOfSize:14.0];
			dateLabel.adjustsFontSizeToFitWidth = YES;
			[barView addSubview:dateLabel];
			
			NSString *xAxisLabelText = [self.dataSource graphView:self labelForXAxisAtIndex:i];
			dateLabel.text = xAxisLabelText;
			CGFloat separatorWidth = 1; //TODO: Ask datasource for separator size (larger for start of week/month)
			CGFloat separatorHeight = 4;
			
			dateLabel.textColor = [self.dataSource graphView:self labelColorForXAxisAtIndex:i];
			CGRect separatorFrame = CGRectMake(-(int)separatorWidth/2, frameForBar.size.height, separatorWidth, separatorHeight);
			UIView *separatorView = [[[UIView alloc] initWithFrame:separatorFrame] autorelease];
			separatorView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
			separatorView.backgroundColor = [UIColor lightGrayColor];
			[barView addSubview:separatorView];
			
			NSArray *stackedValues = [self stackedValuesForBarAtIndex:i];
			[barView setSegmentValues:stackedValues label:[self labelTextForIndex:i]];
			
			[scrollView addSubview:barView];
			[visibleBarViews setObject:barView forKey:[NSNumber numberWithInt:i]];
		}
	}
}

- (NSArray *)stackedValuesForBarAtIndex:(NSUInteger)index
{
	NSArray *stackedAbsoluteValues = [cachedValues objectForKey:[NSNumber numberWithUnsignedInteger:index]];
	if (!stackedAbsoluteValues) {
		stackedAbsoluteValues = [self.dataSource graphView:self valuesForBarAtIndex:index];
		[cachedValues setObject:stackedAbsoluteValues forKey:[NSNumber numberWithUnsignedInteger:index]];
	}
	float totalValue = [[stackedAbsoluteValues valueForKeyPath:@"@sum.self"] floatValue];
	float maxHeight = self.bounds.size.height - 60;
	float totalHeight = (max > 0) ? maxHeight * (totalValue / max) : maxHeight + 80;
	NSMutableArray *stackedValues = [NSMutableArray array];
	for (NSNumber *absoluteValue in stackedAbsoluteValues) {
		float percentage = (totalValue > 0) ? [absoluteValue floatValue] / totalValue : 0.0;
		float height = percentage * totalHeight;
		[stackedValues addObject:[NSNumber numberWithFloat:height]];
	}
	return stackedValues;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)aScrollView willDecelerate:(BOOL)decelerate
{
	if (!decelerate) {
		[self scrollViewDidEndDecelerating:aScrollView];
	}
}


- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
	if (!maxLocked) {
		float oldMax = max;
		max = [self maxVisibleValue];
		
		if (max != oldMax) {
			[UIView beginAnimations:nil context:nil];
			[UIView setAnimationDuration:ANIMATION_DURATION];
			for (NSNumber *barIndex in visibleBarViews) {
				StackedBarView *barView = [visibleBarViews objectForKey:barIndex];
				NSArray *stackedValues = [self stackedValuesForBarAtIndex:[barIndex unsignedIntegerValue]];
				[barView setSegmentValues:stackedValues label:[self labelTextForIndex:[barIndex unsignedIntegerValue]]];
			}
			[UIView commitAnimations];
			
			[scaleView setMax:max animated:YES];
		}
	}
}

- (void)dealloc
{
	[cachedValues release];
	[scaleView release];
	[scrollView release];
	[visibleBarViews release];
	[lockIndicatorView release];
	[titleLabel release];
	[super dealloc];
}

@end



@implementation StackedBarView

- (id)initWithColors:(NSArray *)colorArray
{
	self = [super initWithFrame:CGRectZero];
	if (self) {
		segmentViews = [NSMutableArray new];
		for (UIColor *color in colorArray) {
			UIView *segmentView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
			segmentView.backgroundColor = color;
			segmentView.userInteractionEnabled = NO;
			[segmentViews addObject:segmentView];
			[self addSubview:segmentView];
		}
		label = [[UILabel alloc] initWithFrame:CGRectZero];
		label.backgroundColor = [UIColor clearColor];
		label.font = [UIFont boldSystemFontOfSize:12.0];
		label.adjustsFontSizeToFitWidth = YES;
		label.textAlignment = UITextAlignmentCenter;
		label.textColor = [UIColor darkGrayColor];
		label.shadowColor = [UIColor whiteColor];
		label.shadowOffset = CGSizeMake(0, 1);
		[self addSubview:label];
	}
	return self;
}


- (void)setSegmentValues:(NSArray *)values
{
	[self setSegmentValues:values label:@""];
}

- (void)setSegmentValues:(NSArray *)values label:(NSString *)labelText
{
	NSAssert([values count] == [segmentViews count], @"The number of values must always be equal to the number of colors");
	
	CGFloat padding = 3.0;
	CGFloat width = self.bounds.size.width - 2 * padding;
	CGFloat x = padding;
	CGFloat y = self.bounds.size.height;
	int i = 0;
	for (NSNumber *value in values) {
		CGFloat segmentHeight = [value floatValue];
		y -= segmentHeight;
		CGRect segmentFrame = CGRectMake(x, y, width, segmentHeight);
		UIView *segmentView = [segmentViews objectAtIndex:i];
		segmentView.frame = segmentFrame;
		i++;
	}
	label.hidden = (labelText == nil);
	if (labelText) {
		label.text = labelText;
		label.frame = CGRectIntegral(CGRectMake(0, y - 15, self.bounds.size.width, 15));
	}
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self selectedBackgroundView].alpha = 1.0;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	[UIView beginAnimations:nil context:nil];
	[self selectedBackgroundView].alpha = 0.0;
	[UIView commitAnimations];
	[self sendActionsForControlEvents:UIControlEventTouchUpInside];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	selectedBackgroundView.alpha = 0.0;
}

- (UIView *)selectedBackgroundView
{
	if (!selectedBackgroundView) {
		selectedBackgroundView = [[[UIView alloc] initWithFrame:CGRectMake(2, 3, self.bounds.size.width - 4, self.bounds.size.height + 18)] autorelease];
		selectedBackgroundView.backgroundColor = [UIColor colorWithRed:0.698 green:0.804 blue:0.871 alpha:0.8];
		selectedBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
		selectedBackgroundView.layer.cornerRadius = 5.0;
		selectedBackgroundView.alpha = 0.0;
		[self insertSubview:selectedBackgroundView atIndex:0];
	}
	return selectedBackgroundView;
}

- (void)dealloc
{
	[segmentViews release];
	[label release];
	[super dealloc];
}

@end


@implementation ScaleView

@synthesize unit;

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		lineViews = [NSMutableDictionary new];
		possibleUnits = [[NSArray alloc] initWithObjects:
						 [NSNumber numberWithInt:1], 
						 [NSNumber numberWithInt:5], 
						 [NSNumber numberWithInt:10], 
						 [NSNumber numberWithInt:25],
						 [NSNumber numberWithInt:50],
						 [NSNumber numberWithInt:100],
						 [NSNumber numberWithInt:250],
						 [NSNumber numberWithInt:500], 
						 [NSNumber numberWithInt:1000],
						 [NSNumber numberWithInt:2500],
						 [NSNumber numberWithInt:5000], 
						 [NSNumber numberWithInt:10000],
						 [NSNumber numberWithInt:25000],
						 [NSNumber numberWithInt:50000], 
						 [NSNumber numberWithInt:100000], 
						 [NSNumber numberWithInt:1000000], 
						 [NSNumber numberWithInt:10000000], nil];
		unit = @"";
	}
	return self;
}

- (void)setUnit:(NSString *)newUnit
{
	if ([newUnit isEqualToString:unit]) return;
	[newUnit retain];
	[unit release];
	unit = newUnit;
	for (NSNumber *step in lineViews) {
		LineView *lineView = [lineViews objectForKey:step];
		[lineView setLabelText:[NSString stringWithFormat:@"%@%@", unit, step]];
	}
	
}

- (void)setMax:(float)newMax animated:(BOOL)animated
{
	float animationDuration = (animated) ? ANIMATION_DURATION : 0.0;
	
	[UIView animateWithDuration:animationDuration delay:0.0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState animations: ^ {
		//Don't attempt to do a transition animation if there were no lines visible before:
		BOOL wasEmpty = [lineViews count] == 0;
		
		//Calculate which lines should be visible:
		float totalHeight = self.bounds.size.height;
		int pickedUnit = 0;
		for (NSNumber *possibleUnit in possibleUnits) {
			int unitCount = (int)newMax / [possibleUnit intValue];
			float unitHeight = totalHeight / unitCount;
			if (unitHeight >= 25.0) {
				pickedUnit = [possibleUnit intValue];
				break;
			}
		}
		NSMutableArray *steps = [NSMutableSet set];
		int step = pickedUnit;
		while (step <= newMax && pickedUnit != 0) {
			[steps addObject:[NSNumber numberWithInt:step]];
			step += pickedUnit;
		}
		
		//Remove lines that should not be visible anymore and animate the others to their new position:
		for (NSNumber *existingStep in [lineViews allKeys]) {
			LineView *lineView = [lineViews objectForKey:existingStep];
			if (![steps containsObject:existingStep]) {
				float y = totalHeight - (totalHeight * ([existingStep floatValue] / newMax));
				CGRect lineFrame = CGRectMake(40, (int)y, self.superview.bounds.size.width, 1);
				if ([steps count] > 0) {
					lineView.frame = lineFrame;
				}
				lineView.alpha = 0.0;
				[lineViews removeObjectForKey:existingStep];
			} else {
				float y = totalHeight - (totalHeight * ([existingStep floatValue] / newMax));
				CGRect lineFrame = CGRectMake(40, (int)y, self.superview.bounds.size.width, 1);
				lineView.frame = lineFrame;
			}
		}
		
		//Add new lines, animating them from their hypothetical previous position (relative to the previous max value):
		for (NSNumber *step in steps) {
			LineView *lineView = [lineViews objectForKey:step];
			if (!lineView) {
				float oldY = totalHeight - (totalHeight * ([step floatValue] / max));
				float newY = totalHeight - (totalHeight * ([step floatValue] / newMax));
				CGRect toLineFrame = CGRectMake(40, (int)newY, self.superview.bounds.size.width, 1);
				CGRect fromLineFrame = CGRectMake(40, (int)oldY, self.superview.bounds.size.width, 1);
				LineView *lineView = [[[LineView alloc] initWithFrame:(wasEmpty) ? toLineFrame : fromLineFrame] autorelease];
				lineView.alpha = 0.0;
				[lineView setLabelText:[NSString stringWithFormat:@"%@%@", unit, step]];
				[self addSubview:lineView];
				lineView.frame = toLineFrame;
				lineView.alpha = 1.0;
				[lineViews setObject:lineView forKey:step];
			}
		}
	
	} completion:^ (BOOL finished) {
		for (UIView *v in self.subviews) {
			//Clean up, remove lines that have faded out:
			if (v.alpha <= 0.0) {
				[v removeFromSuperview];
			}
		}
	}];
	max = newMax;
}

- (void)dealloc
{
	[unit release];
	[possibleUnits release];
	[lineViews release];
	[super dealloc];
}

@end


@implementation LineView

- (id)initWithFrame:(CGRect)frameRect
{
	self = [super initWithFrame:frameRect];
	if (self) {
		self.backgroundColor = [UIColor colorWithWhite:0.75 alpha:1.0];
		label = [[UILabel alloc] initWithFrame:CGRectMake(-40, -8, 40, 16)];
		label.backgroundColor = [UIColor clearColor];
		label.font = [UIFont boldSystemFontOfSize:12.0];
		label.textColor = [UIColor darkGrayColor];
		label.shadowColor = [UIColor whiteColor];
		label.shadowOffset = CGSizeMake(0, 1);
		label.textAlignment = UITextAlignmentRight;
		label.adjustsFontSizeToFitWidth = YES;
		[self addSubview:label];
	}
	return self;
}

- (void)setLabelText:(NSString *)labelText
{
	label.text = labelText;
}

- (void)dealloc
{
	[label release];
	[super dealloc];
}

@end


@implementation TouchCancellingScrollView

- (BOOL)touchesShouldCancelInContentView:(UIView *)view
{
	return YES;
}

@end