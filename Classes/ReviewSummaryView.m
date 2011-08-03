//
//  ReviewSummaryView.m
//  AppSales
//
//  Created by Ole Zorn on 27.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "ReviewSummaryView.h"

@implementation ReviewSummaryView

@synthesize dataSource, delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		barViews = [NSMutableArray new];
		barLabels = [NSMutableArray new];
		
		for (int rating = 5; rating >= 1; rating--) {
			CGRect barFrame = [self barFrameForRating:rating];
			
			UILabel *starLabel = [[[UILabel alloc] initWithFrame:CGRectMake(10, barFrame.origin.y-2, 90, 29)] autorelease];
			starLabel.backgroundColor = [UIColor clearColor];
			starLabel.textAlignment = UITextAlignmentRight;
			starLabel.textColor = [UIColor darkGrayColor];
			starLabel.shadowColor = [UIColor whiteColor];
			starLabel.shadowOffset = CGSizeMake(0, 1);
			starLabel.font = [UIFont systemFontOfSize:15.0];
			starLabel.text = [@"" stringByPaddingToLength:rating withString:@"\u2605" startingAtIndex:0];
			[self addSubview:starLabel];
			
			UIView *barBackgroundView = [[[UIView alloc] initWithFrame:barFrame] autorelease];
			barBackgroundView.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1.0]; //[UIColor lightGrayColor];
			barBackgroundView.userInteractionEnabled = NO;
			[self addSubview:barBackgroundView];
			
			UIView *barView = [[[UIView alloc] initWithFrame:barBackgroundView.frame] autorelease];
			barView.backgroundColor = [UIColor colorWithRed:0.541 green:0.612 blue:0.671 alpha:1.0];// [UIColor darkGrayColor];
			barView.userInteractionEnabled = NO;
			[self addSubview:barView];
			[barViews addObject:barView];
			
			UIButton *showReviewsButton = [UIButton buttonWithType:UIButtonTypeCustom];
			CGRect showReviewsButtonFrame = CGRectMake(10, barBackgroundView.frame.origin.y - 2, self.bounds.size.width - 20, 28);
			[showReviewsButton setBackgroundImage:[[UIImage imageNamed:@"ReviewBarButton.png"] stretchableImageWithLeftCapWidth:8 topCapHeight:0] forState:UIControlStateHighlighted];
			showReviewsButton.frame = showReviewsButtonFrame;
			showReviewsButton.tag = rating;
			[self insertSubview:showReviewsButton atIndex:0];
			[showReviewsButton addTarget:self action:@selector(showReviews:) forControlEvents:UIControlEventTouchUpInside];
			
			UILabel *barLabel = [[[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(barFrame) + 5, barFrame.origin.y, 30, barFrame.size.height)] autorelease];
			barLabel.backgroundColor = [UIColor clearColor];
			barLabel.textColor = [UIColor darkGrayColor];
			barLabel.font = [UIFont systemFontOfSize:13.0];
			barLabel.adjustsFontSizeToFitWidth = YES;
			barLabel.shadowColor = [UIColor whiteColor];
			barLabel.shadowOffset = CGSizeMake(0, 1);
			
			[self addSubview:barLabel];
			[barLabels addObject:barLabel];
		}
		
		UIView *separator = [[[UIView alloc] initWithFrame:CGRectMake(10, self.bounds.size.height - 44, self.bounds.size.width - 20, 1)] autorelease];
		separator.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1.0];
		[self addSubview:separator];
		
		UIButton *allReviewsButton = [UIButton buttonWithType:UIButtonTypeCustom];
		allReviewsButton.frame = CGRectMake(110, self.bounds.size.height - 37, 145, 28);
		[allReviewsButton setBackgroundImage:[[UIImage imageNamed:@"AllReviewsButton.png"] stretchableImageWithLeftCapWidth:18 topCapHeight:0] forState:UIControlStateNormal];
		[allReviewsButton setBackgroundImage:[[UIImage imageNamed:@"AllReviewsButtonHighlighted.png"] stretchableImageWithLeftCapWidth:18 topCapHeight:0] forState:UIControlStateHighlighted];
		[allReviewsButton setTitle:NSLocalizedString(@"Show All Reviews", nil) forState:UIControlStateNormal];
		[allReviewsButton setTitleEdgeInsets:UIEdgeInsetsMake(0, -10, 0, 0)];
		allReviewsButton.titleLabel.font = [UIFont boldSystemFontOfSize:13.0];
		[allReviewsButton setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
		allReviewsButton.titleLabel.shadowOffset = CGSizeMake(0, 1);
		[allReviewsButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
		allReviewsButton.tag = 0;
		[self addSubview:allReviewsButton];
		[allReviewsButton addTarget:self action:@selector(showReviews:) forControlEvents:UIControlEventTouchUpInside];
		
		averageLabel = [[[UILabel alloc] initWithFrame:CGRectMake(10, allReviewsButton.frame.origin.y, 90, 29)] autorelease];
		averageLabel.font = [UIFont boldSystemFontOfSize:15.0];
		averageLabel.backgroundColor = [UIColor clearColor];
		averageLabel.textColor = [UIColor darkGrayColor];
		averageLabel.textAlignment = UITextAlignmentRight;
		[self addSubview:averageLabel];
		
		sumLabel = [[[UILabel alloc] initWithFrame:CGRectMake(260, allReviewsButton.frame.origin.y, 30, allReviewsButton.frame.size.height)] autorelease];
		sumLabel.font = [UIFont systemFontOfSize:13.0];
		sumLabel.backgroundColor = [UIColor clearColor];
		sumLabel.textColor = [UIColor darkGrayColor];
		[self addSubview:sumLabel];
    }
    return self;
}

- (void)reloadDataAnimated:(BOOL)animated
{
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
		[ratings setObject:[NSNumber numberWithInteger:n] forKey:[NSNumber numberWithInteger:rating]];
		NSInteger unread = [self.dataSource reviewSummaryView:self numberOfUnreadReviewsForRating:rating];
		[unreadRatings setObject:[NSNumber numberWithInteger:unread] forKey:[NSNumber numberWithInteger:rating]];
	}
	
	for (NSInteger rating = 5; rating >= 1; rating--) {
		NSInteger numberOfReviews = [[ratings objectForKey:[NSNumber numberWithInteger:rating]] integerValue];
		float percentage = (total == 0) ? 0 : (float)numberOfReviews / (float)max;
		CGRect barFrame = [self barFrameForRating:rating];
		barFrame.size.width = barFrame.size.width * percentage;
		[[barViews objectAtIndex:5-rating] setFrame:barFrame];
		
		UILabel *barLabel = [barLabels objectAtIndex:5-rating];
		barLabel.text = [NSString stringWithFormat:@"%i", numberOfReviews];
		if ([[unreadRatings objectForKey:[NSNumber numberWithInteger:rating]] integerValue] > 0) {
			barLabel.font = [UIFont boldSystemFontOfSize:13.0];
			barLabel.textColor = [UIColor colorWithRed:0.141 green:0.439 blue:0.847 alpha:1.0];
		} else {
			barLabel.font = [UIFont systemFontOfSize:13.0];
			barLabel.textColor = [UIColor darkGrayColor];
		}
	}
	sumLabel.text = [NSString stringWithFormat:@"%i", total];
	
	float average = (float)starSum / (float)total;
	NSNumberFormatter *averageFormatter = [[[NSNumberFormatter alloc] init] autorelease];
	[averageFormatter setMinimumFractionDigits:1];
	[averageFormatter setMaximumFractionDigits:1];
	averageLabel.text = [NSString stringWithFormat:@"\u2205 %@", [averageFormatter stringFromNumber:[NSNumber numberWithFloat:average]]];
	
	if (animated) {
		[UIView commitAnimations];
	}
}

- (CGRect)barFrameForRating:(NSInteger)rating
{
	CGRect barFrame = CGRectMake(110, 12 + (5-rating) * 30, 145, 24);
	return barFrame;
}

- (void)showReviews:(UIButton *)button
{
	if (self.delegate && [self.delegate respondsToSelector:@selector(reviewSummaryView:didSelectRating:)]) {
		[self.delegate reviewSummaryView:self didSelectRating:button.tag];
	}
}

- (void)dealloc
{
	[barViews release];
	[barLabels release];
	[super dealloc];
}

@end
