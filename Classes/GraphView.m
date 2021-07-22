//
//  GraphView.m
//  AppSales
//
//  Created by Ole Zorn on 11.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "GraphView.h"
#import "ASProgressHUD.h"
#import "DarkModeCheck.h"

#define ANIMATION_DURATION	0.4

@implementation GraphView

@synthesize delegate, dataSource;
@synthesize sectionLabelButton;

- (instancetype)initWithFrame:(CGRect)frameRect {
	self = [super initWithFrame:frameRect];
	if (self) {
		self.clipsToBounds = YES;
		self.backgroundColor = [UIColor clearColor];
		
		cachedValues = [NSMutableDictionary new];
		
		UIView *scaleBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 46.0f, self.bounds.size.height - 30.0f)];
		if (@available(iOS 13.0, *)) {
			scaleBackgroundView.backgroundColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
				switch (traitCollection.userInterfaceStyle) {
					case UIUserInterfaceStyleDark:
						return [UIColor colorWithRed:28.0f/255.0f green:28.0f/255.0f blue:30.0f/255.0f alpha:1.0f];
					default:
						return [UIColor colorWithWhite:0.9f alpha:1.0f];
				}
			}];
		} else {
			scaleBackgroundView.backgroundColor = [UIColor colorWithWhite:0.9f alpha:1.0f];
		}
		[self addSubview:scaleBackgroundView];
		
		UIView *bottomLineView = [[UIView alloc] initWithFrame:CGRectMake(46.0f, self.bounds.size.height - 30.0f, self.bounds.size.width - 46.0f, 1.0f)];
		bottomLineView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
		if (@available(iOS 13.0, *)) {
			bottomLineView.backgroundColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
				switch (traitCollection.userInterfaceStyle) {
					case UIUserInterfaceStyleDark:
						return [UIColor systemGray5Color];
					default:
						return [UIColor lightGrayColor];
				}
			}];
		} else {
			bottomLineView.backgroundColor = [UIColor lightGrayColor];
		}
		[self addSubview:bottomLineView];
		
		scaleView = [[ScaleView alloc] initWithFrame:CGRectMake(0.0f, 30.0f, 46.0f, self.bounds.size.height - 60.0f)];
		scaleView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
		[self addSubview:scaleView];
		
		lockIndicatorView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LockIndicator"]];
		lockIndicatorView.frame = CGRectMake(15.0f, 7.0f, 16.0f, 16.0f);
		lockIndicatorView.hidden = YES;
		[self addSubview:lockIndicatorView];
		
		UILongPressGestureRecognizer *lockScaleRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(lockScale:)];
		[scaleView addGestureRecognizer:lockScaleRecognizer];
		
		UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
		longPressRecognizer.minimumPressDuration = 1.0;
		[self addGestureRecognizer:longPressRecognizer];
		
		scrollView = [[TouchCancellingScrollView alloc] initWithFrame:CGRectMake(46.0f, 0.0f, self.bounds.size.width - 46.0f, self.bounds.size.height)];
		scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		scrollView.delegate = self;
		scrollView.alwaysBounceHorizontal = YES;
		scrollView.showsVerticalScrollIndicator = NO;
		[self addSubview:scrollView];
		
		titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 4.0f, self.bounds.size.width, 12.0f)];
		titleLabel.font = [UIFont systemFontOfSize:11.0f weight:UIFontWeightSemibold];
		titleLabel.textAlignment = NSTextAlignmentCenter;
		titleLabel.textColor = [UIColor grayColor];
		titleLabel.backgroundColor = [UIColor clearColor];
		[self addSubview:titleLabel];
		
		self.sectionLabelButton = [UIButton buttonWithType:UIButtonTypeCustom];
		sectionLabelButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        [self.sectionLabelButton setBackgroundImage:[DarkModeCheck checkForDarkModeImage:@"DateButton"] forState:UIControlStateNormal];
		self.sectionLabelButton.frame = CGRectMake(0.0f, self.bounds.size.height - 30.0f - 16.0f, 46.0f, 32.0f);
		self.sectionLabelButton.titleLabel.font = [UIFont systemFontOfSize:10.0f weight:UIFontWeightSemibold];
		self.sectionLabelButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        
        
        if (@available(iOS 13.0, *)) {
            [self.sectionLabelButton setTitleColor:[UIColor secondaryLabelColor] forState:UIControlStateNormal];
        } else {
            [self.sectionLabelButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        }
		
		[self addSubview:self.sectionLabelButton];
		
		visibleRange = NSMakeRange(NSNotFound, 0);
		barsPerPage = 7;
		visibleBarViews = [NSMutableDictionary new];
		max = -1.0f;
	}
	return self;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
	[super traitCollectionDidChange:previousTraitCollection];
	[self.sectionLabelButton setBackgroundImage:[DarkModeCheck checkForDarkModeImage:@"DateButton"] forState:UIControlStateNormal];
}

- (void)longPress:(UILongPressGestureRecognizer *)recognizer {
	if ([recognizer state] == UIGestureRecognizerStateBegan) {
		for (NSNumber *index in visibleBarViews) {
			StackedBarView *barView = visibleBarViews[index];
			if (CGRectContainsPoint(barView.bounds, [recognizer locationInView:barView])) {
				if ([self.delegate respondsToSelector:@selector(graphView:canDeleteBarAtIndex:)] && [self.delegate graphView:self canDeleteBarAtIndex:index.unsignedIntegerValue]) {
					selectedBarIndexForMenu = index.unsignedIntegerValue;
					[self becomeFirstResponder];
					NSArray *menuItems = @[[[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Delete", nil) action:@selector(deleteBar:)]];
					[[UIMenuController sharedMenuController] setMenuItems:menuItems];
				
					CGRect targetRect = [barView convertRect:barView.bounds toView:self];
					[[UIMenuController sharedMenuController] setTargetRect:targetRect inView:self];
					[[UIMenuController sharedMenuController] setMenuVisible:YES animated:YES];
				}
			}
		}
	}
}

- (void)deleteBar:(id)sender {
	if ([self.delegate respondsToSelector:@selector(graphView:deleteBarAtIndex:)]) {
		[self.delegate graphView:self deleteBarAtIndex:selectedBarIndexForMenu];
	}
}

- (BOOL)canBecomeFirstResponder {
	return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
	if (action == @selector(deleteBar:)) return YES;
	return NO;
}

- (void)setTitle:(NSString *)title {
	titleLabel.text = title;
}

- (NSString *)title {
	return titleLabel.text;
}

- (void)lockScale:(UILongPressGestureRecognizer *)recognizer {
	if (recognizer.state == UIGestureRecognizerStateBegan) {
		maxLocked = !maxLocked;
		[ASProgressHUD hideHUDForView:self animated:YES];
		
		ASProgressHUD *hud = [[ASProgressHUD alloc] initWithView:self];
		hud.animationType = MBProgressHUDAnimationZoom;
		hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:(maxLocked ? @"Lock" : @"Unlock")]];
		hud.mode = MBProgressHUDModeCustomView;
		if (maxLocked) {
			hud.label.text = NSLocalizedString(@"Scale locked", nil);
		} else {
			hud.label.text = NSLocalizedString(@"Scale unlocked", nil);
		}
		hud.userInteractionEnabled = NO;
		[self addSubview:hud];
		[hud showAnimated:YES];
		
		lockIndicatorView.hidden = !maxLocked;
		if (!maxLocked) {
			[self reloadValuesAnimated:YES];
		}
		
		[NSObject cancelPreviousPerformRequestsWithTarget:self];
		[self performSelector:@selector(hideHUD) withObject:nil afterDelay:1.5];
	}
}

- (void)hideHUD {
	[ASProgressHUD hideHUDForView:self animated:YES];
}

- (void)barSelected:(StackedBarView *)barView {
	if ([UIMenuController sharedMenuController].isMenuVisible) return;
	for (NSNumber *barIndex in visibleBarViews) {
		StackedBarView *view = visibleBarViews[barIndex];
		if (view == barView) {
			CGFloat stackHeight = view.stackHeight;
			CGRect stackRect = CGRectMake(barView.frame.origin.x, barView.frame.origin.y + (barView.frame.size.height - stackHeight), barView.frame.size.width, stackHeight);
			[self.delegate graphView:self didSelectBarAtIndex:barIndex.unsignedIntegerValue withFrame:[self convertRect:stackRect fromView:view.superview]];
			break;
		}
	}
}

- (NSString *)unit {
	return scaleView.unit;
}

- (void)setUnit:(NSString *)unit {
	[scaleView setUnit:unit];
}

- (void)reloadData {
	[cachedValues removeAllObjects];
	
	NSUInteger numberOfBars = [self.dataSource numberOfBarsInGraphView:self];
	
	CGFloat contentWidth = numberOfBars * barWidth;
	scrollView.contentSize = CGSizeMake(contentWidth, 0.0f);
	
	for (UIView *barView in visibleBarViews.allValues) {
		[barView removeFromSuperview];
	}
	[visibleBarViews removeAllObjects];
	
	visibleRange = NSMakeRange(NSNotFound, 0);
	max = -1.0f;
	
	scrollView.contentOffset = CGPointMake(MAX(0.0f, scrollView.contentSize.width - scrollView.bounds.size.width), 0.0f);
	[self scrollViewDidScroll:scrollView];
	
	[scrollView flashScrollIndicators];
}

- (void)reloadValuesAnimated:(BOOL)animated {
	[cachedValues removeAllObjects];
	
	if (!maxLocked) {
		max = 0.0f;
		for (NSNumber *barIndex in visibleBarViews) {
			NSArray *stackedValues = [self.dataSource graphView:self valuesForBarAtIndex:barIndex.unsignedIntegerValue];
			CGFloat sum = [[stackedValues valueForKeyPath:@"@sum.self"] floatValue];
			if (sum > max) max = sum;
		}
	}
	
	if (animated) {
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:ANIMATION_DURATION];
		[UIView setAnimationBeginsFromCurrentState:YES];
	}
	for (NSNumber *barIndex in visibleBarViews) {
		StackedBarView *barView = visibleBarViews[barIndex];
		NSArray *stackedValues = [self stackedValuesForBarAtIndex:barIndex.unsignedIntegerValue];
		[barView setSegmentValues:stackedValues label:[self labelTextForIndex:barIndex.unsignedIntegerValue]];
	}
	[scaleView setMax:max animated:YES];
	if (animated) {
		[UIView commitAnimations];
	}
}

- (void)setFrame:(CGRect)frame {
	[super setFrame:frame];
	[self scrollViewDidScroll:scrollView];
}

- (void)setNumberOfBarsPerPage:(int)newBarsPerPage {
	barsPerPage = newBarsPerPage;
	barWidth = scrollView.bounds.size.width / barsPerPage;
	[self reloadData];
}

- (NSRange)visibleBarRange {
	NSUInteger numberOfBars = [self.dataSource numberOfBarsInGraphView:self];
	barsPerPage = scrollView.bounds.size.width / barWidth;
	NSInteger firstVisibleBarIndex = MIN(numberOfBars, MAX(0, scrollView.contentOffset.x / barWidth));
	NSRange newVisibleRange = NSMakeRange(firstVisibleBarIndex, barsPerPage + 2);
	if (newVisibleRange.location + newVisibleRange.length >= numberOfBars) {
		newVisibleRange.length = numberOfBars - newVisibleRange.location;
	}
	return newVisibleRange;
}

- (CGFloat)maxVisibleValue {
	CGFloat maxValue = 0.0f;
	for (NSInteger i = visibleRange.location; i < visibleRange.location + visibleRange.length; i++) {
		NSArray *stackedValues = [self.dataSource graphView:self valuesForBarAtIndex:i];
		CGFloat sum = [[stackedValues valueForKeyPath:@"@sum.self"] floatValue];
		if (sum > maxValue) maxValue = sum;
	}
	return maxValue;
}

- (CGRect)frameForBarAtIndex:(NSInteger)index {
	CGFloat marginBottom = 30.0f;
	CGRect barFrame =  CGRectMake(barWidth * index, 0.0f, barWidth, self.bounds.size.height - marginBottom);
	return CGRectIntegral(barFrame);
}

- (NSString *)labelTextForIndex:(NSUInteger)index {
	if (barWidth < 20.0f) return nil;
	NSString *labelText = [self.dataSource graphView:self labelForBarAtIndex:index];
	return labelText;
}

- (void)reloadColors {
	for (UIView *barView in visibleBarViews.allValues) {
		[barView removeFromSuperview];
	}
	[visibleBarViews removeAllObjects];
	
	visibleRange = NSMakeRange(NSNotFound, 0);
	
	[self scrollViewDidScroll:scrollView];
}

- (void)scrollViewDidScroll:(UIScrollView *)aScrollView {
	NSRange newVisibleRange = self.visibleBarRange;
	if (NSEqualRanges(newVisibleRange, visibleRange)) {
		return;
	}
	visibleRange = newVisibleRange;
	
	if (max < 0.0f) {
		max = [self maxVisibleValue];
		[scaleView setMax:max animated:NO];
	}
	
	NSString *sectionLabelText = [self.dataSource graphView:self labelForSectionAtIndex:visibleRange.location];
	[self.sectionLabelButton setTitle:sectionLabelText forState:UIControlStateNormal];
	
	// Remove views that are no longer visible.
	for (NSNumber *visibleBarIndex in visibleBarViews.allKeys) {
		if (!NSLocationInRange(visibleBarIndex.integerValue, visibleRange)) {
			UIView *barView = visibleBarViews[visibleBarIndex];
			[barView removeFromSuperview];
			[visibleBarViews removeObjectForKey:visibleBarIndex];
		}
	}
	
	// Add views that are visible now.
	for (NSInteger i = visibleRange.location; i < (visibleRange.location + visibleRange.length); i++) {
		StackedBarView *barView = visibleBarViews[@(i)];
		CGRect frameForBar = [self frameForBarAtIndex:i];
		if (!barView) {
			NSArray *colors = [self.dataSource colorsForGraphView:self];
			
			barView = [[StackedBarView alloc] initWithColors:colors];
			[barView addTarget:self action:@selector(barSelected:) forControlEvents:UIControlEventTouchUpInside];
			barView.frame = frameForBar;
			barView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
			
			UILabel *dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, frameForBar.size.height, frameForBar.size.width, 30.0f)];
			dateLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
			dateLabel.backgroundColor = [UIColor clearColor];
			if (@available(iOS 13.0, *)) {
				dateLabel.textColor = [UIColor secondaryLabelColor];
			} else {
				dateLabel.textColor = [UIColor darkGrayColor];
			}
			dateLabel.textAlignment = NSTextAlignmentCenter;
			dateLabel.font = [UIFont systemFontOfSize:12.0f weight:UIFontWeightSemibold];
			dateLabel.adjustsFontSizeToFitWidth = YES;
			dateLabel.numberOfLines = 0;
			[barView addSubview:dateLabel];
			
			NSString *xAxisLabelText = [self.dataSource graphView:self labelForXAxisAtIndex:i];
			dateLabel.text = xAxisLabelText;
			CGFloat separatorWidth = 1.0f; // TODO: Ask datasource for separator size (larger for start of week/month).
			CGFloat separatorHeight = 4.0f;
			
			dateLabel.textColor = [self.dataSource graphView:self labelColorForXAxisAtIndex:i];
			CGRect separatorFrame = CGRectMake(-(int)separatorWidth/2, frameForBar.size.height, separatorWidth, separatorHeight);
			UIView *separatorView = [[UIView alloc] initWithFrame:separatorFrame];
			separatorView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
			if (@available(iOS 13.0, *)) {
				separatorView.backgroundColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
					switch (traitCollection.userInterfaceStyle) {
						case UIUserInterfaceStyleDark:
							return [UIColor systemGray5Color];
						default:
							return [UIColor lightGrayColor];
					}
				}];
			} else {
				separatorView.backgroundColor = [UIColor lightGrayColor];
			}
			[barView addSubview:separatorView];
			
			NSArray *stackedValues = [self stackedValuesForBarAtIndex:i];
			[barView setSegmentValues:stackedValues label:[self labelTextForIndex:i]];
			
			[scrollView addSubview:barView];
			visibleBarViews[@(i)] = barView;
		}
	}
}

- (NSArray *)stackedValuesForBarAtIndex:(NSUInteger)index {
	NSArray *stackedAbsoluteValues = cachedValues[@(index)];
	if (!stackedAbsoluteValues) {
		stackedAbsoluteValues = [self.dataSource graphView:self valuesForBarAtIndex:index];
		cachedValues[@(index)] = stackedAbsoluteValues;
	}
	CGFloat totalValue = [[stackedAbsoluteValues valueForKeyPath:@"@sum.self"] floatValue];
	CGFloat maxHeight = self.bounds.size.height - 60.0f;
	CGFloat totalHeight = (max > 0.0f) ? maxHeight * (totalValue / max) : maxHeight + 80.0f;
	NSMutableArray *stackedValues = [NSMutableArray array];
	for (NSNumber *absoluteValue in stackedAbsoluteValues) {
		CGFloat percentage = (totalValue > 0.0f) ? absoluteValue.floatValue / totalValue : 0.0f;
		CGFloat height = percentage * totalHeight;
		[stackedValues addObject:@(height)];
	}
	return stackedValues;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)aScrollView willDecelerate:(BOOL)decelerate {
	if (!decelerate) {
		[self scrollViewDidEndDecelerating:aScrollView];
	}
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	if (!maxLocked) {
		CGFloat oldMax = max;
		max = self.maxVisibleValue;
		
		if (max != oldMax) {
			[UIView beginAnimations:nil context:nil];
			[UIView setAnimationDuration:ANIMATION_DURATION];
			for (NSNumber *barIndex in visibleBarViews) {
				StackedBarView *barView = visibleBarViews[barIndex];
				NSArray *stackedValues = [self stackedValuesForBarAtIndex:barIndex.unsignedIntegerValue];
				[barView setSegmentValues:stackedValues label:[self labelTextForIndex:barIndex.unsignedIntegerValue]];
			}
			[UIView commitAnimations];
			
			[scaleView setMax:max animated:YES];
		}
	}
}

@end


@implementation StackedBarView

- (instancetype)initWithColors:(NSArray *)colorArray {
	self = [super initWithFrame:CGRectZero];
	if (self) {
		segmentViews = [NSMutableArray new];
		for (UIColor *color in colorArray) {
			UIView *segmentView = [[UIView alloc] initWithFrame:CGRectZero];
			segmentView.backgroundColor = color;
			segmentView.userInteractionEnabled = NO;
			[segmentViews addObject:segmentView];
			[self addSubview:segmentView];
		}
		label = [[UILabel alloc] initWithFrame:CGRectZero];
		label.backgroundColor = [UIColor clearColor];
		label.font = [UIFont systemFontOfSize:12.0f weight:UIFontWeightSemibold];
		label.adjustsFontSizeToFitWidth = YES;
		label.textAlignment = NSTextAlignmentCenter;
		if (@available(iOS 13.0, *)) {
			label.textColor = [UIColor secondaryLabelColor];
		} else {
			label.textColor = [UIColor darkGrayColor];
		}
		[self addSubview:label];
	}
	return self;
}

- (void)setSegmentValues:(NSArray *)values {
	[self setSegmentValues:values label:@""];
}

- (void)setSegmentValues:(NSArray *)values label:(NSString *)labelText {
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
		UIView *segmentView = segmentViews[i];
		segmentView.frame = segmentFrame;
		i++;
	}
	label.hidden = (labelText == nil);
	if (labelText) {
		label.text = labelText;
		label.frame = CGRectIntegral(CGRectMake(0, y - 15, self.bounds.size.width, 15));
	}
}

- (CGFloat)stackHeight {
	CGFloat stackHeight = 0.0;
	for (UIView *segmentView in segmentViews) {
		stackHeight += segmentView.frame.size.height;
	}
	return stackHeight;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[self selectedBackgroundView].alpha = 1.0;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	[UIView beginAnimations:nil context:nil];
	[self selectedBackgroundView].alpha = 0.0;
	[UIView commitAnimations];
	[self sendActionsForControlEvents:UIControlEventTouchUpInside];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	selectedBackgroundView.alpha = 0.0;
}

- (UIView *)selectedBackgroundView {
	if (!selectedBackgroundView) {
		selectedBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(2, 3, self.bounds.size.width - 4, self.bounds.size.height + 25)];
		if (@available(iOS 13.0, *)) {
			selectedBackgroundView.backgroundColor = [UIColor systemGray5Color];
		} else {
			selectedBackgroundView.backgroundColor = [UIColor colorWithRed:229.0f/255.0f green:229.0f/255.0f blue:234.0f/255.0f alpha:1.0f];
		}
		selectedBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
		selectedBackgroundView.layer.cornerRadius = 5.0;
		selectedBackgroundView.alpha = 0.0;
		[self insertSubview:selectedBackgroundView atIndex:0];
	}
	return selectedBackgroundView;
}

@end


@implementation ScaleView

@synthesize unit;

- (instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		lineViews = [NSMutableDictionary new];
		possibleUnits = @[@(1),
						  @(5),
						  @(10),
						  @(25),
						  @(50),
						  @(100),
						  @(250),
						  @(500),
						  @(1000),
						  @(2500),
						  @(5000),
						  @(10000),
						  @(25000),
						  @(50000),
						  @(100000),
						  @(1000000),
						  @(10000000)];
		unit = @"";
		numberFormatter = [[NSNumberFormatter alloc] init];
		numberFormatter.locale = [NSLocale currentLocale];
		numberFormatter.formatterBehavior = NSNumberFormatterBehavior10_4;
		numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
		numberFormatter.maximumFractionDigits = 2;
		numberFormatter.minimumFractionDigits = 0;
	}
	return self;
}

- (NSString *)descriptionForStep:(NSNumber *)step {
	if (unit.length == 0) {
		if (step.integerValue >= 1000000) {
			return [NSString stringWithFormat:@"%@M", [numberFormatter stringFromNumber:@(step.floatValue / 1000000.0f)]];
		} else if (step.integerValue >= 1000) {
			return [NSString stringWithFormat:@"%@K", [numberFormatter stringFromNumber:@(step.floatValue / 1000.0f)]];
		}
	}
	return [NSString stringWithFormat:@"%@%@", unit, [numberFormatter stringFromNumber:step]];
}

- (void)setUnit:(NSString *)newUnit {
	if ([newUnit isEqualToString:unit]) return;
	unit = newUnit;
	for (NSNumber *step in lineViews) {
		LineView *lineView = lineViews[step];
		lineView.labelText = [self descriptionForStep:step];
	}
}

- (void)setMax:(CGFloat)newMax animated:(BOOL)animated {
	float animationDuration = animated ? ANIMATION_DURATION : 0.0;
	
	[UIView animateWithDuration:animationDuration delay:0.0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState animations:^{
		// Don't attempt to do a transition animation if there were no lines visible before.
        BOOL wasEmpty = [self->lineViews count] == 0;
		
		// Calculate which lines should be visible.
		CGFloat totalHeight = self.bounds.size.height;
		NSInteger pickedUnit = 0;
        for (NSNumber *possibleUnit in self->possibleUnits) {
			NSInteger unitCount = (NSInteger)newMax / possibleUnit.integerValue;
			CGFloat unitHeight = totalHeight / unitCount;
			if (unitHeight >= 25.0f) {
				pickedUnit = possibleUnit.integerValue;
				break;
			}
		}
		NSMutableSet *steps = [NSMutableSet set];
		NSInteger step = pickedUnit;
		while ((step <= newMax) && (pickedUnit != 0)) {
			[steps addObject:@(step)];
			step += pickedUnit;
		}
		
		// Remove lines that should not be visible anymore and animate the others to their new position.
        for (NSNumber *existingStep in [self->lineViews allKeys]) {
            LineView *lineView = self->lineViews[existingStep];
			if (![steps containsObject:existingStep]) {
				CGFloat y = totalHeight - (totalHeight * (existingStep.floatValue / newMax));
				CGRect lineFrame = CGRectMake(40.0f, (NSInteger)y, self.superview.bounds.size.width, 1.0f);
				if (steps.count > 0) {
					lineView.frame = lineFrame;
				}
				lineView.alpha = 0.0f;
                [self->lineViews removeObjectForKey:existingStep];
			} else {
				CGFloat y = totalHeight - (totalHeight * (existingStep.floatValue / newMax));
				CGRect lineFrame = CGRectMake(40.0f, (NSInteger)y, self.superview.bounds.size.width, 1.0f);
				lineView.frame = lineFrame;
			}
		}
		
		// Add new lines, animating them from their hypothetical previous position (relative to the previous max value).
		for (NSNumber *step in steps) {
            LineView *lineView = self->lineViews[step];
			if (!lineView) {
                CGFloat oldY = totalHeight - (totalHeight * (step.floatValue / self->max));
				CGFloat newY = totalHeight - (totalHeight * (step.floatValue / newMax));
				CGRect toLineFrame = CGRectMake(40.0f, (NSInteger)newY, self.superview.bounds.size.width, 1.0f);
				CGRect fromLineFrame = CGRectMake(40.0f, (NSInteger)oldY, self.superview.bounds.size.width, 1.0f);
				LineView *lineView = [[LineView alloc] initWithFrame:(wasEmpty ? toLineFrame : fromLineFrame)];
				lineView.alpha = 0.0f;
				lineView.labelText = [self descriptionForStep:step];
				[self addSubview:lineView];
				lineView.frame = toLineFrame;
				lineView.alpha = 1.0f;
                self->lineViews[step] = lineView;
			}
		}
	
	} completion:^(BOOL finished) {
		for (UIView *v in self.subviews) {
			// Clean up, remove lines that have faded out.
			if (v.alpha <= 0.0f) {
				[v removeFromSuperview];
			}
		}
	}];
	max = newMax;
}

@end


@implementation LineView

- (instancetype)initWithFrame:(CGRect)frameRect {
	self = [super initWithFrame:frameRect];
	if (self) {
		if (@available(iOS 13.0, *)) {
			self.backgroundColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
				switch (traitCollection.userInterfaceStyle) {
					case UIUserInterfaceStyleDark:
						return [UIColor colorWithWhite:0.75f alpha:0.2f];
					default:
						return [UIColor colorWithWhite:0.75f alpha:1.0f];
				}
			}];
		} else {
			self.backgroundColor = [UIColor colorWithWhite:0.75f alpha:1.0f];
		}
		label = [[UILabel alloc] initWithFrame:CGRectMake(-40.0f, -8.0f, 40.0f, 16.0f)];
		label.backgroundColor = [UIColor clearColor];
		label.font = [UIFont systemFontOfSize:12.0f weight:UIFontWeightSemibold];
		if (@available(iOS 13.0, *)) {
			label.textColor = [UIColor secondaryLabelColor];
		} else {
			label.textColor = [UIColor darkGrayColor];
		}
		label.textAlignment = NSTextAlignmentRight;
		label.adjustsFontSizeToFitWidth = YES;
		[self addSubview:label];
	}
	return self;
}

- (void)setLabelText:(NSString *)labelText {
	label.text = labelText;
}

@end


@implementation TouchCancellingScrollView

- (BOOL)touchesShouldCancelInContentView:(UIView *)view {
	return YES;
}

@end
