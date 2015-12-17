//
//  ReviewSummaryView.m
//  AppSales
//
//  Created by Ole Zorn on 27.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "ReviewSummaryView.h"

CGFloat const barWidth = 130.0f;
CGFloat const barHeight = 24.0f;
CGFloat const labelWidth = 75.0f;
CGFloat const contentViewHeight = 44.0f;
CGFloat const buttonWidth = 145.0f;
CGFloat const buttonHeight = 28.0f;
CGFloat const padding = 10.0f;

@implementation ReviewSummaryView

@synthesize dataSource, delegate;

- (instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		barViews = [NSMutableArray new];
		barLabels = [NSMutableArray new];
		
		for (NSInteger rating = 5; rating >= 1; rating--) {
			
			UIButton *showReviewsButton = [UIButton buttonWithType:UIButtonTypeCustom];
			[showReviewsButton setBackgroundImage:[[UIImage imageNamed:@"ReviewBarButton"] resizableImageWithCapInsets:UIEdgeInsetsMake(7.0f, 7.0f, 7.0f, 7.0f) resizingMode:UIImageResizingModeTile] forState:UIControlStateHighlighted];
			[showReviewsButton addTarget:self action:@selector(showReviews:) forControlEvents:UIControlEventTouchUpInside];
			showReviewsButton.translatesAutoresizingMaskIntoConstraints = NO;
			showReviewsButton.tag = rating;
			[self addSubview:showReviewsButton];
			
			[self addConstraint:[NSLayoutConstraint constraintWithItem:showReviewsButton
															 attribute:NSLayoutAttributeTop
															 relatedBy:NSLayoutRelationEqual
																toItem:self
															 attribute:NSLayoutAttributeTop
															multiplier:1.0f
															  constant:(14.0f + ((CGFloat)(5 - rating) * 30.0f) + padding)]];
			
			[self addConstraint:[NSLayoutConstraint constraintWithItem:showReviewsButton
															 attribute:NSLayoutAttributeCenterX
															 relatedBy:NSLayoutRelationEqual
																toItem:self
															 attribute:NSLayoutAttributeCenterX
															multiplier:1.0f
															  constant:0.0f]];
			
			[self addConstraint:[NSLayoutConstraint constraintWithItem:showReviewsButton
															 attribute:NSLayoutAttributeWidth
															 relatedBy:NSLayoutRelationEqual
																toItem:nil
															 attribute:NSLayoutAttributeNotAnAttribute
															multiplier:1.0f
															  constant:(padding + labelWidth + padding + barWidth + padding + labelWidth + padding)]];
			
			[self addConstraint:[NSLayoutConstraint constraintWithItem:showReviewsButton
															 attribute:NSLayoutAttributeHeight
															 relatedBy:NSLayoutRelationEqual
																toItem:nil
															 attribute:NSLayoutAttributeNotAnAttribute
															multiplier:1.0f
															  constant:(2.0f + barHeight + 2.0f)]];
			
			UIView *barBackgroundView = [[UIView alloc] init];
			barBackgroundView.backgroundColor = [UIColor colorWithWhite:0.8f alpha:1.0f];
			barBackgroundView.userInteractionEnabled = NO;
			barBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
			[showReviewsButton addSubview:barBackgroundView];
			
			[showReviewsButton addConstraint:[NSLayoutConstraint constraintWithItem:barBackgroundView
																		  attribute:NSLayoutAttributeCenterX
																		  relatedBy:NSLayoutRelationEqual
																			 toItem:showReviewsButton
																		  attribute:NSLayoutAttributeCenterX
																		 multiplier:1.0f
																		   constant:0.0f]];
			
			[showReviewsButton addConstraint:[NSLayoutConstraint constraintWithItem:barBackgroundView
																		  attribute:NSLayoutAttributeCenterY
																		  relatedBy:NSLayoutRelationEqual
																			 toItem:showReviewsButton
																		  attribute:NSLayoutAttributeCenterY
																		 multiplier:1.0f
																		   constant:0.0f]];
			
			[showReviewsButton addConstraint:[NSLayoutConstraint constraintWithItem:barBackgroundView
																		  attribute:NSLayoutAttributeHeight
																		  relatedBy:NSLayoutRelationEqual
																			 toItem:nil
																		  attribute:NSLayoutAttributeNotAnAttribute
																		 multiplier:1.0f
																		   constant:barHeight]];
			
			UIView *barView = [[UIView alloc] initWithFrame:CGRectMake(padding + labelWidth + padding, 2.0f, 0.0f, barHeight)];
			barView.backgroundColor = [UIColor colorWithRed:138.0f/255.0f green:156.0f/255.0f blue:171.0f/255.0f alpha:1.0f];
			barView.userInteractionEnabled = NO;
			barView.translatesAutoresizingMaskIntoConstraints = NO;
			[showReviewsButton addSubview:barView];
			[barViews addObject:barView];
			
			UILabel *starLabel = [[UILabel alloc] init];
			starLabel.backgroundColor = [UIColor clearColor];
			starLabel.textAlignment = NSTextAlignmentRight;
			starLabel.textColor = [UIColor darkGrayColor];
			starLabel.shadowColor = [UIColor whiteColor];
			starLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
			starLabel.font = [UIFont systemFontOfSize:15.0f];
			starLabel.text = [@"" stringByPaddingToLength:rating withString:@"\u2605" startingAtIndex:0];
			starLabel.translatesAutoresizingMaskIntoConstraints = NO;
			[showReviewsButton addSubview:starLabel];
			
			[showReviewsButton addConstraint:[NSLayoutConstraint constraintWithItem:starLabel
																		  attribute:NSLayoutAttributeCenterY
																		  relatedBy:NSLayoutRelationEqual
																			 toItem:barBackgroundView
																		  attribute:NSLayoutAttributeCenterY
																		 multiplier:1.0f
																		   constant:0.0f]];
			
			[showReviewsButton addConstraint:[NSLayoutConstraint constraintWithItem:starLabel
																		  attribute:NSLayoutAttributeHeight
																		  relatedBy:NSLayoutRelationEqual
																			 toItem:barBackgroundView
																		  attribute:NSLayoutAttributeHeight
																		 multiplier:1.0f
																		   constant:0.0f]];
			
			UILabel *barLabel = [[UILabel alloc] init];
			barLabel.backgroundColor = [UIColor clearColor];
			barLabel.textAlignment = NSTextAlignmentLeft;
			barLabel.textColor = [UIColor darkGrayColor];
			barLabel.shadowColor = [UIColor whiteColor];
			barLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
			barLabel.font = [UIFont systemFontOfSize:13.0f];
			barLabel.adjustsFontSizeToFitWidth = YES;
			barLabel.translatesAutoresizingMaskIntoConstraints = NO;
			[showReviewsButton addSubview:barLabel];
			[barLabels addObject:barLabel];
			
			[showReviewsButton addConstraint:[NSLayoutConstraint constraintWithItem:barLabel
																		  attribute:NSLayoutAttributeCenterY
																		  relatedBy:NSLayoutRelationEqual
																			 toItem:barBackgroundView
																		  attribute:NSLayoutAttributeCenterY
																		 multiplier:1.0f
																		   constant:0.0f]];
			
			[showReviewsButton addConstraint:[NSLayoutConstraint constraintWithItem:barLabel
																		  attribute:NSLayoutAttributeHeight
																		  relatedBy:NSLayoutRelationEqual
																			 toItem:barBackgroundView
																		  attribute:NSLayoutAttributeHeight
																		 multiplier:1.0f
																		   constant:0.0f]];
			
			[showReviewsButton addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[starLabel(l)]-p-[barBackgroundView(b)]-p-[barLabel(l)]"
																					  options:0
																					  metrics:@{@"b": @(barWidth), @"l": @(labelWidth), @"p": @(padding)}
																						views:@{@"starLabel": starLabel, @"barBackgroundView": barBackgroundView, @"barLabel": barLabel}]];
		}
		
		UIView *separator = [[UIView alloc] init];
		separator.backgroundColor = [UIColor colorWithWhite:0.8f alpha:1.0f];
		separator.translatesAutoresizingMaskIntoConstraints = NO;
		[self addSubview:separator];
		
		UIView *contentView = [[UIView alloc] init];
		contentView.backgroundColor = [UIColor clearColor];
		contentView.translatesAutoresizingMaskIntoConstraints = NO;
		[self addSubview:contentView];
		
		[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-p-[contentView]-p-|"
																	 options:0
																	 metrics:@{@"p": @(padding)}
																	   views:@{@"contentView": contentView}]];
		
		[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[separator(1)][contentView(h)]|"
																	 options:0
																	 metrics:@{@"h": @(contentViewHeight)}
																	   views:@{@"contentView": contentView, @"separator": separator}]];
		
		[self addConstraint:[NSLayoutConstraint constraintWithItem:separator
														 attribute:NSLayoutAttributeCenterX
														 relatedBy:NSLayoutRelationEqual
															toItem:contentView
														 attribute:NSLayoutAttributeCenterX
														multiplier:1.0f
														  constant:0.0f]];
		
		[self addConstraint:[NSLayoutConstraint constraintWithItem:separator
														 attribute:NSLayoutAttributeWidth
														 relatedBy:NSLayoutRelationEqual
															toItem:contentView
														 attribute:NSLayoutAttributeWidth
														multiplier:1.0f
														  constant:0.0f]];
		
		UIButton *allReviewsButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[allReviewsButton setBackgroundImage:[[UIImage imageNamed:@"AllReviewsButton"] resizableImageWithCapInsets:UIEdgeInsetsMake(6.0f, 18.0f, 6.0f, 18.0f) resizingMode:UIImageResizingModeStretch] forState:UIControlStateNormal];
		[allReviewsButton setBackgroundImage:[[UIImage imageNamed:@"AllReviewsButtonHighlighted"] resizableImageWithCapInsets:UIEdgeInsetsMake(6.0f, 18.0f, 6.0f, 18.0f) resizingMode:UIImageResizingModeStretch] forState:UIControlStateHighlighted];
		[allReviewsButton addTarget:self action:@selector(showReviews:) forControlEvents:UIControlEventTouchUpInside];
		[allReviewsButton setTitle:NSLocalizedString(@"Show All Reviews", nil) forState:UIControlStateNormal];
		allReviewsButton.titleLabel.font = [UIFont boldSystemFontOfSize:13.0f];
		[allReviewsButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0f, -10.0f, 0.0f, 0.0f)];
		[allReviewsButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
		[allReviewsButton setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
		allReviewsButton.titleLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
		allReviewsButton.translatesAutoresizingMaskIntoConstraints = NO;
		allReviewsButton.tag = 0;
		[contentView addSubview:allReviewsButton];
		
		[contentView addConstraint:[NSLayoutConstraint constraintWithItem:allReviewsButton
																attribute:NSLayoutAttributeCenterX
																relatedBy:NSLayoutRelationEqual
																   toItem:contentView
																attribute:NSLayoutAttributeCenterX
															   multiplier:1.0f
																 constant:0.0f]];
		
		[contentView addConstraint:[NSLayoutConstraint constraintWithItem:allReviewsButton
																attribute:NSLayoutAttributeCenterY
																relatedBy:NSLayoutRelationEqual
																   toItem:contentView
																attribute:NSLayoutAttributeCenterY
															   multiplier:1.0f
																 constant:0.0f]];
		
		[contentView addConstraint:[NSLayoutConstraint constraintWithItem:allReviewsButton
																attribute:NSLayoutAttributeHeight
																relatedBy:NSLayoutRelationEqual
																   toItem:nil
																attribute:NSLayoutAttributeNotAnAttribute
															   multiplier:1.0f
																 constant:buttonHeight]];
		
		averageLabel = [[UILabel alloc] init];
		averageLabel.backgroundColor = [UIColor clearColor];
		averageLabel.textAlignment = NSTextAlignmentRight;
		averageLabel.textColor = [UIColor darkGrayColor];
		averageLabel.shadowColor = [UIColor whiteColor];
		averageLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
		averageLabel.font = [UIFont boldSystemFontOfSize:15.0f];
		averageLabel.translatesAutoresizingMaskIntoConstraints = NO;
		[contentView addSubview:averageLabel];
		
		[contentView addConstraint:[NSLayoutConstraint constraintWithItem:averageLabel
																attribute:NSLayoutAttributeCenterY
																relatedBy:NSLayoutRelationEqual
																   toItem:allReviewsButton
																attribute:NSLayoutAttributeCenterY
															   multiplier:1.0f
																 constant:0.0f]];
		
		[contentView addConstraint:[NSLayoutConstraint constraintWithItem:averageLabel
																attribute:NSLayoutAttributeHeight
																relatedBy:NSLayoutRelationEqual
																   toItem:allReviewsButton
																attribute:NSLayoutAttributeHeight
															   multiplier:1.0f
																 constant:0.0f]];
		
		sumLabel = [[UILabel alloc] init];
		sumLabel.backgroundColor = [UIColor clearColor];
		sumLabel.textAlignment = NSTextAlignmentLeft;
		sumLabel.textColor = [UIColor darkGrayColor];
		sumLabel.shadowColor = [UIColor whiteColor];
		sumLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
		sumLabel.font = [UIFont systemFontOfSize:13.0f];
		sumLabel.translatesAutoresizingMaskIntoConstraints = NO;
		[contentView addSubview:sumLabel];
		
		[contentView addConstraint:[NSLayoutConstraint constraintWithItem:sumLabel
																attribute:NSLayoutAttributeCenterY
																relatedBy:NSLayoutRelationEqual
																   toItem:allReviewsButton
																attribute:NSLayoutAttributeCenterY
															   multiplier:1.0f
																 constant:0.0f]];
		
		[contentView addConstraint:[NSLayoutConstraint constraintWithItem:sumLabel
																attribute:NSLayoutAttributeHeight
																relatedBy:NSLayoutRelationEqual
																   toItem:allReviewsButton
																attribute:NSLayoutAttributeHeight
															   multiplier:1.0f
																 constant:0.0f]];
		
		[contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[averageLabel]-p-[allReviewsButton(w)]-p-[sumLabel]|"
																			options:0
																			metrics:@{@"w": @(buttonWidth), @"p": @(padding)}
																			  views:@{@"averageLabel": averageLabel, @"allReviewsButton": allReviewsButton, @"sumLabel": sumLabel}]];
	}
	return self;
}

- (void)reloadDataAnimated:(BOOL)animated {
	if (animated) {
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationBeginsFromCurrentState:YES];
		[UIView setAnimationDuration:0.4];
	}
	NSMutableDictionary *ratings = [NSMutableDictionary dictionary];
	NSMutableDictionary *unreadRatings = [NSMutableDictionary dictionary];
	NSInteger total = 0;
	NSInteger starSum = 0;
	NSInteger max = 0;
	for (NSInteger rating = 5; rating >= 1; rating--) {
		NSInteger n = [self.dataSource reviewSummaryView:self numberOfReviewsForRating:rating];
		total += n;
		starSum += n * rating;
		if (n > max) max = n;
		[ratings setObject:@(n) forKey:@(rating)];
		NSInteger unread = [self.dataSource reviewSummaryView:self numberOfUnreadReviewsForRating:rating];
		[unreadRatings setObject:@(unread) forKey:@(rating)];
	}
	
	for (NSInteger rating = 5; rating >= 1; rating--) {
		NSInteger numberOfReviews = [ratings[@(rating)] integerValue];
		CGFloat percentage = (total == 0) ? 0 : (CGFloat)numberOfReviews / (CGFloat)max;
		UIView *barView = barViews[5 - rating];
		CGRect barFrame = barView.frame;
		barFrame.size.width = barWidth * percentage;
		barView.frame = barFrame;
		
		UILabel *barLabel = barLabels[5 - rating];
		barLabel.text = [NSString stringWithFormat:@"%li", (long)numberOfReviews];
		if ([unreadRatings[@(rating)] integerValue] > 0) {
			barLabel.font = [UIFont boldSystemFontOfSize:13.0];
			barLabel.textColor = [UIColor colorWithRed:0.141 green:0.439 blue:0.847 alpha:1.0];
		} else {
			barLabel.font = [UIFont systemFontOfSize:13.0];
			barLabel.textColor = [UIColor darkGrayColor];
		}
	}
	sumLabel.text = [NSString stringWithFormat:@"%li", (long)total];
	
	float average = (float)starSum / (float)total;
	NSNumberFormatter *averageFormatter = [[NSNumberFormatter alloc] init];
	[averageFormatter setMinimumFractionDigits:1];
	[averageFormatter setMaximumFractionDigits:1];
	averageLabel.text = [NSString stringWithFormat:@"\u2205 %@", [averageFormatter stringFromNumber:@(average)]];
	
	if (animated) {
		[UIView commitAnimations];
	}
}

- (void)showReviews:(UIButton *)button {
	if (self.delegate && [self.delegate respondsToSelector:@selector(reviewSummaryView:didSelectRating:)]) {
		[self.delegate reviewSummaryView:self didSelectRating:button.tag];
	}
}

@end
