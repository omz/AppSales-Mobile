//
//  ReviewListHeaderView.m
//  AppSales
//
//  Created by Nicolas Gomollon on 6/23/17.
//
//

#import "ReviewListHeaderView.h"

@implementation StarRatingProgressView

- (CGSize)sizeThatFits:(CGSize)size {
	return CGSizeMake(size.width, self.frame.size.height);
}

@end

@implementation ReviewListHeaderView

- (instancetype)init {
	return [self initWithFrame:CGRectZero];
}

- (instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 108.0f)];
	if (self) {
		// Initialization code
		self.backgroundColor = [UIColor clearColor];
		
		formatter = [[NSNumberFormatter alloc] init];
		formatter.locale = [NSLocale currentLocale];
		formatter.numberStyle = NSNumberFormatterDecimalStyle;
		formatter.usesGroupingSeparator = YES;
		
		avgFormatter = [[NSNumberFormatter alloc] init];
		avgFormatter.minimumFractionDigits = 1;
		avgFormatter.maximumFractionDigits = 1;
		
		averageLabel = [[UILabel alloc] initWithFrame:CGRectMake(16.0f, 14.0f, 96.0f, 62.0f)];
		averageLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
		averageLabel.backgroundColor = [UIColor clearColor];
		averageLabel.textAlignment = NSTextAlignmentCenter;
		if (@available(iOS 13.0, *)) {
			averageLabel.textColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
				switch (traitCollection.userInterfaceStyle) {
					case UIUserInterfaceStyleDark:
						return [UIColor colorWithRed:235.0f/255.0f green:235.0f/255.0f blue:244.0f/255.0f alpha:1.0f];
					default:
						return [UIColor colorWithRed:74.0f/255.0f green:74.0f/255.0f blue:78.0f/255.0f alpha:1.0f];
				}
			}];
		} else {
			averageLabel.textColor = [UIColor colorWithRed:92.0f/255.0f green:92.0f/255.0f blue:98.0f/255.0f alpha:1.0f];
		}
		averageLabel.font = [UIFont systemFontOfSize:60.0f weight:UIFontWeightBold];
		averageLabel.text = @"0.0";
		[self addSubview:averageLabel];
		
		UILabel *outOfLabel = [[UILabel alloc] initWithFrame:CGRectMake(16.0f, CGRectGetHeight(self.frame) - 20.0f - 14.0f, 96.0f, 20.0f)];
		outOfLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin;
		outOfLabel.backgroundColor = [UIColor clearColor];
		outOfLabel.textAlignment = NSTextAlignmentCenter;
		if (@available(iOS 13.0, *)) {
			outOfLabel.textColor = [UIColor secondaryLabelColor];
		} else {
			outOfLabel.textColor = [UIColor colorWithRed:146.0f/255.0f green:146.0f/255.0f blue:146.0f/255.0f alpha:1.0f];
		}
		outOfLabel.font = [UIFont systemFontOfSize:15.0f weight:UIFontWeightBold];
		outOfLabel.text = NSLocalizedString(@"out of 5", nil);
		[self addSubview:outOfLabel];
		
		totalReviewsLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.frame) - 180.0f - 18.0f, CGRectGetHeight(self.frame) - 20.0f - 14.0f, 180.0f, 20.0f)];
		totalReviewsLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
		totalReviewsLabel.backgroundColor = [UIColor clearColor];
		totalReviewsLabel.textAlignment = NSTextAlignmentRight;
		if (@available(iOS 13.0, *)) {
			totalReviewsLabel.textColor = [UIColor secondaryLabelColor];
		} else {
			totalReviewsLabel.textColor = [UIColor colorWithRed:146.0f/255.0f green:146.0f/255.0f blue:146.0f/255.0f alpha:1.0f];
		}
		totalReviewsLabel.font = [UIFont systemFontOfSize:15.0f];
		totalReviewsLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ Reviews", nil), [formatter stringFromNumber:@(0)]];
		[self addSubview:totalReviewsLabel];
		
		UILabel *starLabel5 = [self newStarLabelWithFrame:CGRectMake(CGRectGetWidth(self.frame) - 52.0f - 12.0f - 90.0f - 10.0f - 52.0f - 18.0f, 23.0f, 52.0f, 9.0f)];
		starLabel5.text = [@"" stringByPaddingToLength:5 withString:@"\u2605" startingAtIndex:0];
		[self addSubview:starLabel5];
		
		reviewLabel5 = [self newReviewLabelWithFrame:CGRectMake(CGRectGetWidth(self.frame) - 52.0f - 18.0f, 23.0f, 52.0f, 9.0f)];
		reviewLabel5.text = @"0";
		[self addSubview:reviewLabel5];
		
		progressView5 = [self newProgressViewWithFrame:CGRectMake(CGRectGetWidth(self.frame) - 90.0f - 10.0f - 52.0f - 18.0f, 26.0f, 90.0f, 3.0f)];
		progressView5.progress = 0.29f;
		[self addSubview:progressView5];
		
		UILabel *starLabel4 = [self newStarLabelWithFrame:CGRectMake(CGRectGetWidth(self.frame) - 52.0f - 12.0f - 90.0f - 10.0f - 52.0f - 18.0f, CGRectGetMaxY(starLabel5.frame), 52.0f, 9.0f)];
		starLabel4.text = [@"" stringByPaddingToLength:4 withString:@"\u2605" startingAtIndex:0];
		[self addSubview:starLabel4];
		
		reviewLabel4 = [self newReviewLabelWithFrame:CGRectMake(CGRectGetWidth(self.frame) - 52.0f - 18.0f, CGRectGetMaxY(reviewLabel5.frame), 52.0f, 9.0f)];
		reviewLabel4.text = @"0";
		[self addSubview:reviewLabel4];
		
		progressView4 = [self newProgressViewWithFrame:CGRectMake(CGRectGetWidth(self.frame) - 90.0f - 10.0f - 52.0f - 18.0f, CGRectGetMaxY(progressView5.frame) + 6.0f, 90.0f, 3.0f)];
		progressView4.progress = 0.1f;
		[self addSubview:progressView4];
		
		UILabel *starLabel3 = [self newStarLabelWithFrame:CGRectMake(CGRectGetWidth(self.frame) - 52.0f - 12.0f - 90.0f - 10.0f - 52.0f - 18.0f, CGRectGetMaxY(starLabel4.frame), 52.0f, 9.0f)];
		starLabel3.text = [@"" stringByPaddingToLength:3 withString:@"\u2605" startingAtIndex:0];
		[self addSubview:starLabel3];
		
		reviewLabel3 = [self newReviewLabelWithFrame:CGRectMake(CGRectGetWidth(self.frame) - 52.0f - 18.0f, CGRectGetMaxY(reviewLabel4.frame), 52.0f, 9.0f)];
		reviewLabel3.text = @"0";
		[self addSubview:reviewLabel3];
		
		progressView3 = [self newProgressViewWithFrame:CGRectMake(CGRectGetWidth(self.frame) - 90.0f - 10.0f - 52.0f - 18.0f, CGRectGetMaxY(progressView4.frame) + 6.0f, 90.0f, 3.0f)];
		progressView3.progress = 0.12f;
		[self addSubview:progressView3];
		
		UILabel *starLabel2 = [self newStarLabelWithFrame:CGRectMake(CGRectGetWidth(self.frame) - 52.0f - 12.0f - 90.0f - 10.0f - 52.0f - 18.0f, CGRectGetMaxY(starLabel3.frame), 52.0f, 9.0f)];
		starLabel2.text = [@"" stringByPaddingToLength:2 withString:@"\u2605" startingAtIndex:0];
		[self addSubview:starLabel2];
		
		reviewLabel2 = [self newReviewLabelWithFrame:CGRectMake(CGRectGetWidth(self.frame) - 52.0f - 18.0f, CGRectGetMaxY(reviewLabel3.frame), 52.0f, 9.0f)];
		reviewLabel2.text = @"0";
		[self addSubview:reviewLabel2];
		
		progressView2 = [self newProgressViewWithFrame:CGRectMake(CGRectGetWidth(self.frame) - 90.0f - 10.0f - 52.0f - 18.0f, CGRectGetMaxY(progressView3.frame) + 6.0f, 90.0f, 3.0f)];
		progressView2.progress = 0.13f;
		[self addSubview:progressView2];
		
		UILabel *starLabel1 = [self newStarLabelWithFrame:CGRectMake(CGRectGetWidth(self.frame) - 52.0f - 12.0f - 90.0f - 10.0f - 52.0f - 18.0f, CGRectGetMaxY(starLabel2.frame), 52.0f, 9.0f)];
		starLabel1.text = [@"" stringByPaddingToLength:1 withString:@"\u2605" startingAtIndex:0];
		[self addSubview:starLabel1];
		
		reviewLabel1 = [self newReviewLabelWithFrame:CGRectMake(CGRectGetWidth(self.frame) - 52.0f - 18.0f, CGRectGetMaxY(reviewLabel2.frame), 52.0f, 9.0f)];
		reviewLabel1.text = @"0";
		[self addSubview:reviewLabel1];
		
		progressView1 = [self newProgressViewWithFrame:CGRectMake(CGRectGetWidth(self.frame) - 90.0f - 10.0f - 52.0f - 18.0f, CGRectGetMaxY(progressView2.frame) + 6.0f, 90.0f, 3.0f)];
		progressView1.progress = 0.36f;
		[self addSubview:progressView1];
		
		separator = [[UIView alloc] initWithFrame:CGRectMake(18.0f, CGRectGetHeight(self.frame) - 0.5f, CGRectGetWidth(self.frame) - (18.0f * 2.0f), 0.5f)];
		separator.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
		if (@available(iOS 13.0, *)) {
			separator.backgroundColor = [UIColor separatorColor];
		} else {
			separator.backgroundColor = [UIColor colorWithRed:200.0f/255.0f green:199.0f/255.0f blue:204.0f/255.0f alpha:1.0f];
		}
		[self addSubview:separator];
	}
	return self;
}

- (UILabel *)newReviewLabelWithFrame:(CGRect)frame {
	UILabel *reviewLabel = [self newStarLabelWithFrame:frame];
	reviewLabel.font = [UIFont boldSystemFontOfSize:9.0f];
	return reviewLabel;
}

- (UILabel *)newStarLabelWithFrame:(CGRect)frame {
	UILabel *starLabel = [[UILabel alloc] initWithFrame:frame];
	starLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin;
	starLabel.backgroundColor = [UIColor clearColor];
	starLabel.textAlignment = NSTextAlignmentRight;
	if (@available(iOS 13.0, *)) {
		starLabel.textColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
			switch (traitCollection.userInterfaceStyle) {
				case UIUserInterfaceStyleDark:
					return [UIColor colorWithRed:158.0f/255.0f green:158.0f/255.0f blue:165.0f/255.0f alpha:1.0f];
				default:
					return [UIColor colorWithRed:127.0f/255.0f green:127.0f/255.0f blue:131.0f/255.0f alpha:1.0f];
			}
		}];
	} else {
		starLabel.textColor = [UIColor colorWithRed:153.0f/255.0f green:153.0f/255.0f blue:158.0f/255.0f alpha:1.0f];
	}
	starLabel.font = [UIFont systemFontOfSize:9.0f];
	return starLabel;
}

- (StarRatingProgressView *)newProgressViewWithFrame:(CGRect)frame {
	StarRatingProgressView *progressView = [[StarRatingProgressView alloc] initWithFrame:frame];
	progressView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin;
	progressView.backgroundColor = [UIColor clearColor];
	if (@available(iOS 13.0, *)) {
		progressView.progressTintColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
			switch (traitCollection.userInterfaceStyle) {
				case UIUserInterfaceStyleDark:
					return [UIColor colorWithRed:158.0f/255.0f green:158.0f/255.0f blue:165.0f/255.0f alpha:1.0f];
				default:
					return [UIColor colorWithRed:127.0f/255.0f green:127.0f/255.0f blue:131.0f/255.0f alpha:1.0f];
			}
		}];
		progressView.trackTintColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
			switch (traitCollection.userInterfaceStyle) {
				case UIUserInterfaceStyleDark:
					return [UIColor colorWithRed:43.0f/255.0f green:43.0f/255.0f blue:46.0f/255.0f alpha:1.0f];
				default:
					return [UIColor colorWithRed:228.0f/255.0f green:228.0f/255.0f blue:229.0f/255.0f alpha:1.0f];
			}
		}];
	} else {
		progressView.progressTintColor = [UIColor colorWithRed:153.0f/255.0f green:153.0f/255.0f blue:158.0f/255.0f alpha:1.0f];
		progressView.trackTintColor = [UIColor colorWithRed:239.0f/255.0f green:239.0f/255.0f blue:241.0f/255.0f alpha:1.0f];
	}
	return progressView;
}

- (void)reloadData {
	NSMutableDictionary<NSNumber *, NSNumber *> *ratings = [[NSMutableDictionary alloc] init];
	NSUInteger sumOfRatings = 0;
	NSUInteger totalRatings = 0;
	for (NSUInteger rating = 5; rating >= 1; rating--) {
		NSUInteger n = [self.dataSource reviewListHeaderView:self numberOfReviewsForRating:rating];
		sumOfRatings += n * rating;
		totalRatings += n;
		ratings[@(rating)] = @(n);
	}
	
	{
		NSUInteger numberOfReviews = ratings[@(5)].unsignedIntegerValue;
		progressView5.progress = (CGFloat)numberOfReviews / (CGFloat)totalRatings;
		reviewLabel5.text = [formatter stringFromNumber:@(numberOfReviews)];
	}
	{
		NSUInteger numberOfReviews = ratings[@(4)].unsignedIntegerValue;
		progressView4.progress = (CGFloat)numberOfReviews / (CGFloat)totalRatings;
		reviewLabel4.text = [formatter stringFromNumber:@(numberOfReviews)];
	}
	{
		NSUInteger numberOfReviews = ratings[@(3)].unsignedIntegerValue;
		progressView3.progress = (CGFloat)numberOfReviews / (CGFloat)totalRatings;
		reviewLabel3.text = [formatter stringFromNumber:@(numberOfReviews)];
	}
	{
		NSUInteger numberOfReviews = ratings[@(2)].unsignedIntegerValue;
		progressView2.progress = (CGFloat)numberOfReviews / (CGFloat)totalRatings;
		reviewLabel2.text = [formatter stringFromNumber:@(numberOfReviews)];
	}
	{
		NSUInteger numberOfReviews = ratings[@(1)].unsignedIntegerValue;
		progressView1.progress = (CGFloat)numberOfReviews / (CGFloat)totalRatings;
		reviewLabel1.text = [formatter stringFromNumber:@(numberOfReviews)];
	}
	
	totalReviewsLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ Reviews", nil), [formatter stringFromNumber:@(totalRatings)]];
	
	CGFloat average = (CGFloat)sumOfRatings / (CGFloat)totalRatings;
	averageLabel.text = [avgFormatter stringFromNumber:@(average)];
}

@end
