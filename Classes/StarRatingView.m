//
//  StarRatingView.m
//  AppSales
//
//  Created by Nicolas Gomollon on 6/18/17.
//
//

#import "StarRatingView.h"

CGFloat const kStarWidth  = 14.0f;
CGFloat const kStarHeight = 13.0f;

@implementation StarRatingViewHelper

- (instancetype)init {
	self = [super init];
	if (self) {
		// Initialization code
	}
	return self;
}

+ (instancetype)sharedHelper {
	static id sharedHelper = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedHelper = [[self alloc] init];
	});
	return sharedHelper;
}

- (UIImage *)starImage {
	if (starImage == nil) {
		starImage = [[UIImage imageNamed:@"Star"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	}
	return starImage;
}

- (UIImage *)starFilledImage {
	if (starFilledImage == nil) {
		starFilledImage = [[UIImage imageNamed:@"StarFilled"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	}
	return starFilledImage;
}

@end

@implementation StarRatingView

@synthesize origin, height, rating;

- (instancetype)init {
	return [self initWithFrame:CGRectZero];
}

- (instancetype)initWithOrigin:(CGPoint)_origin {
	return [self initWithOrigin:_origin height:0.0f];
}

- (instancetype)initWithOrigin:(CGPoint)_origin height:(CGFloat)_height {
	return [self initWithFrame:CGRectMake(_origin.x, _origin.y, 0.0f, _height)];
}

- (instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:CGRectMake(frame.origin.x, frame.origin.y, kStarWidth * 5.0f, MAX(kStarHeight, frame.size.height))];
	if (self) {
		// Initialization code
		self.backgroundColor = [UIColor clearColor];
		star1 = [self newStar:CGPointMake(kStarWidth * 0.0f, 0.0f)];
		star2 = [self newStar:CGPointMake(kStarWidth * 1.0f, 0.0f)];
		star3 = [self newStar:CGPointMake(kStarWidth * 2.0f, 0.0f)];
		star4 = [self newStar:CGPointMake(kStarWidth * 3.0f, 0.0f)];
		star5 = [self newStar:CGPointMake(kStarWidth * 4.0f, 0.0f)];
	}
	return self;
}

- (void)setRating:(NSInteger)_rating {
	rating = _rating;
	switch (rating) {
		case 0:
			star1.image = [StarRatingViewHelper sharedHelper].starImage;
		case 1:
			star2.image = [StarRatingViewHelper sharedHelper].starImage;
		case 2:
			star3.image = [StarRatingViewHelper sharedHelper].starImage;
		case 3:
			star4.image = [StarRatingViewHelper sharedHelper].starImage;
		case 4:
			star5.image = [StarRatingViewHelper sharedHelper].starImage;
		default:
			break;
	}
	switch (rating) {
		case 5:
			star5.image = [StarRatingViewHelper sharedHelper].starFilledImage;
		case 4:
			star4.image = [StarRatingViewHelper sharedHelper].starFilledImage;
		case 3:
			star3.image = [StarRatingViewHelper sharedHelper].starFilledImage;
		case 2:
			star2.image = [StarRatingViewHelper sharedHelper].starFilledImage;
		case 1:
			star1.image = [StarRatingViewHelper sharedHelper].starFilledImage;
		default:
			break;
	}
}

- (void)setOrigin:(CGPoint)_origin {
	self.frame = CGRectMake(_origin.x, _origin.y, self.frame.size.width, self.frame.size.height);
}

- (CGPoint)origin {
	return self.frame.origin;
}

- (void)setHeight:(CGFloat)_height {
	self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, _height);
}

- (CGFloat)height {
	return self.frame.size.height;
}

- (UIImageView *)newStar:(CGPoint)_origin {
	UIImageView *star = [[UIImageView alloc] initWithFrame:CGRectMake(_origin.x, _origin.y, kStarWidth, self.frame.size.height)];
	star.autoresizingMask = UIViewAutoresizingFlexibleHeight;
	star.backgroundColor = [UIColor clearColor];
	star.contentMode = UIViewContentModeCenter;
	star.tintColor = [UIColor colorWithRed:255.0f/255.0f green:149.0f/255.0f blue:0.0f/255.0f alpha:1.0f];
	star.image = [StarRatingViewHelper sharedHelper].starImage;
	[self addSubview:star];
	return star;
}

@end
