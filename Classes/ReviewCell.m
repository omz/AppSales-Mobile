//
//  ReviewCell.m
//  AppSales
//
//  Created by Nicolas Gomollon on 6/18/17.
//
//

#import "ReviewCell.h"
#import "StarRatingView.h"
#import "Review.h"
#import "Version.h"
#import "CountryDictionary.h"

CGFloat const kReviewMarginVertical = 14.0f;
CGFloat const kReviewMarginHorizontal = 18.0f;

CGFloat const kReviewTitleFontSize = 15.0f;
CGFloat const kReviewNicknameFontSize = 13.0f;
CGFloat const kReviewTextFontSize = 15.0f;
CGFloat const kReviewDetailsFontSize = 13.0f;

@implementation ReviewCellHelper

- (instancetype)init {
	self = [super init];
	if (self) {
		// Initialization code
		NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
		paragraphStyle.alignment = NSTextAlignmentLeft;
		
		titleAttrs = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:kReviewTitleFontSize],
					   NSParagraphStyleAttributeName: paragraphStyle};
		
		reviewAttrs = @{NSFontAttributeName: [UIFont systemFontOfSize:kReviewTextFontSize],
						NSParagraphStyleAttributeName: paragraphStyle};
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

- (CGFloat)titleLabelHeightForReview:(Review *)review thatFits:(CGFloat)width {
	NSString *titleText = review.title ?: NSLocalizedString(@"Untitled", nil);
	NSTextStorage *textStorage = [[NSTextStorage alloc] initWithString:titleText attributes:titleAttrs];
	
	NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:CGSizeMake(width - (kReviewMarginHorizontal * 2.0f), CGFLOAT_MAX)];
	textContainer.lineFragmentPadding = 0.0f;
	
	UIBezierPath *ratingRect = [UIBezierPath bezierPathWithRect:CGRectMake(textContainer.size.width - 70.0f - 4.0f, 0.0f, 70.0f + 4.0f, kReviewTitleFontSize + 3.0f)];
	textContainer.exclusionPaths = @[ratingRect];
	
	NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
	[layoutManager addTextContainer:textContainer];
	[textStorage addLayoutManager:layoutManager];
	
	CGRect titleFrame = [layoutManager usedRectForTextContainer:textContainer];
	return MAX(kReviewTitleFontSize + 3.0f, titleFrame.size.height);
}

- (CGFloat)reviewLabelHeightForReview:(Review *)review thatFits:(CGFloat)width {
	NSString *reviewText = review.text ?: NSLocalizedString(@"Lorem ipsum dolor sit amet.", nil);
	NSTextStorage *textStorage = [[NSTextStorage alloc] initWithString:reviewText attributes:reviewAttrs];
	
	NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:CGSizeMake(width - (kReviewMarginHorizontal * 2.0f), CGFLOAT_MAX)];
	textContainer.lineFragmentPadding = 0.0f;
	
	NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
	[layoutManager addTextContainer:textContainer];
	[textStorage addLayoutManager:layoutManager];
	
	CGRect reviewFrame = [layoutManager usedRectForTextContainer:textContainer];
	return MAX(kReviewTextFontSize + 3.0f, reviewFrame.size.height);
}

- (CGFloat)heightForReview:(Review *)review thatFits:(CGFloat)width {
	// Top Margin
	CGFloat intrinsicHeight = kReviewMarginVertical;
	
	// titleLabel + starRatingView
	intrinsicHeight += [self titleLabelHeightForReview:review thatFits:width];
	
	// nicknameLabel + padding
	intrinsicHeight += (4.0f + (kReviewNicknameFontSize + 3.0f) + 4.0f);
	
	// reviewLabel
	intrinsicHeight += [self reviewLabelHeightForReview:review thatFits:width];
	
	// detailsLabel + padding
	intrinsicHeight += (4.0f + (kReviewDetailsFontSize + 3.0f));
	
	// Bottom Margin
	intrinsicHeight += kReviewMarginVertical;
	
	return intrinsicHeight;
}

@end

@implementation ReviewCell

@synthesize review;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
	if (self) {
		// Initialization code
		self.accessoryType = UITableViewCellAccessoryNone;
		CGSize contentSize = self.contentView.bounds.size;
		
		dateFormatter = [[NSDateFormatter alloc] init];
		dateFormatter.dateStyle = NSDateFormatterMediumStyle;
		
		colorView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 4.0f, contentSize.height)];
		colorView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
		colorView.backgroundColor = self.tintColor;
		[self.contentView addSubview:colorView];
		
		starRatingView = [[StarRatingView alloc] init];
		starRatingView.origin = CGPointMake(contentSize.width - CGRectGetWidth(starRatingView.frame) - kReviewMarginHorizontal, kReviewMarginVertical);
		starRatingView.height = kReviewTitleFontSize + 3.0f;
		starRatingView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
		[self.contentView addSubview:starRatingView];
		
		titleLabel = [[UITextView alloc] initWithFrame:CGRectMake(kReviewMarginHorizontal, kReviewMarginVertical, contentSize.width - (kReviewMarginHorizontal * 2.0f), kReviewTitleFontSize + 3.0f)];
		titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
		titleLabel.backgroundColor = [UIColor clearColor];
		titleLabel.userInteractionEnabled = NO;
		titleLabel.scrollEnabled = NO;
		titleLabel.editable = NO;
		titleLabel.textAlignment = NSTextAlignmentLeft;
		titleLabel.font = [UIFont boldSystemFontOfSize:kReviewTitleFontSize];
		titleLabel.textColor = [UIColor blackColor];
		titleLabel.text = NSLocalizedString(@"Untitled", nil);
		[self.contentView addSubview:titleLabel];
		
		UIBezierPath *ratingRect = [UIBezierPath bezierPathWithRect:CGRectMake(CGRectGetWidth(titleLabel.frame) - CGRectGetWidth(starRatingView.frame) - 4.0f, 0.0f, CGRectGetWidth(starRatingView.frame) + 4.0f, CGRectGetHeight(starRatingView.frame))];
		titleLabel.textContainerInset = UIEdgeInsetsZero;
		titleLabel.textContainer.lineFragmentPadding = 0.0f;
		titleLabel.textContainer.exclusionPaths = @[ratingRect];
		
		replyView = [[UIImageView alloc] initWithFrame:CGRectMake(contentSize.width - 15.0f - kReviewMarginHorizontal, CGRectGetMaxY(titleLabel.frame) + 4.0f + 2.0f, 15.0f, kReviewNicknameFontSize - 1.0f)];
		replyView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
		replyView.backgroundColor = [UIColor clearColor];
		replyView.contentMode = UIViewContentModeScaleAspectFit;
		replyView.tintColor = [UIColor grayColor];
		replyView.image = [[UIImage imageNamed:@"Reply"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
		[self.contentView addSubview:replyView];
		
		nicknameLabel = [[UILabel alloc] initWithFrame:CGRectMake(kReviewMarginHorizontal, CGRectGetMaxY(titleLabel.frame) + 4.0f, contentSize.width - kReviewMarginHorizontal - 4.0f - CGRectGetWidth(replyView.frame) - kReviewMarginHorizontal, kReviewNicknameFontSize + 3.0f)];
		nicknameLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
		nicknameLabel.backgroundColor = [UIColor clearColor];
		nicknameLabel.textAlignment = NSTextAlignmentLeft;
		nicknameLabel.font = [UIFont systemFontOfSize:kReviewNicknameFontSize];
		nicknameLabel.textColor = [UIColor grayColor];
		nicknameLabel.text = NSLocalizedString(@"by Username - Jun 29, 2007", nil);
		[self.contentView addSubview:nicknameLabel];
		
		reviewLabel = [[UILabel alloc] initWithFrame:CGRectMake(kReviewMarginHorizontal, CGRectGetMaxY(nicknameLabel.frame) + 4.0f, contentSize.width - (kReviewMarginHorizontal * 2.0f), kReviewTextFontSize + 3.0f)];
		reviewLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
		reviewLabel.backgroundColor = [UIColor clearColor];
		reviewLabel.textAlignment = NSTextAlignmentLeft;
		reviewLabel.font = [UIFont systemFontOfSize:kReviewTextFontSize];
		reviewLabel.textColor = [UIColor blackColor];
		reviewLabel.numberOfLines = 0;
		reviewLabel.text = NSLocalizedString(@"Lorem ipsum dolor sit amet.", nil);
		[self.contentView addSubview:reviewLabel];
		
		detailsLabel = [[UILabel alloc] initWithFrame:CGRectMake(kReviewMarginHorizontal, CGRectGetMaxY(reviewLabel.frame) + 4.0f, contentSize.width - (kReviewMarginHorizontal * 2.0f), kReviewDetailsFontSize + 3.0f)];
		detailsLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
		detailsLabel.backgroundColor = [UIColor clearColor];
		detailsLabel.textAlignment = NSTextAlignmentLeft;
		detailsLabel.font = [UIFont systemFontOfSize:kReviewDetailsFontSize];
		detailsLabel.textColor = [UIColor grayColor];
		detailsLabel.text = NSLocalizedString(@"Version 1.0  |  United States", nil);
		[self.contentView addSubview:detailsLabel];
	}
	return self;
}

- (void)prepareForReuse {
	[super prepareForReuse];
	colorView.backgroundColor = self.tintColor;
	titleLabel.text = NSLocalizedString(@"Untitled", nil);
	nicknameLabel.text = NSLocalizedString(@"by Username - Jun 29, 2007", nil);
	reviewLabel.text = NSLocalizedString(@"Lorem ipsum dolor sit amet.", nil);
	detailsLabel.text = NSLocalizedString(@"Version 1.0  |  United States", nil);
}

- (void)tintColorDidChange {
	[super tintColorDidChange];
	colorView.backgroundColor = self.tintColor;
}

- (void)layoutContent {
	UIBezierPath *ratingRect = [UIBezierPath bezierPathWithRect:CGRectMake(CGRectGetWidth(titleLabel.frame) - CGRectGetWidth(starRatingView.frame) - 4.0f, 0.0f, CGRectGetWidth(starRatingView.frame) + 4.0f, CGRectGetHeight(starRatingView.frame))];
	titleLabel.textContainer.exclusionPaths = @[ratingRect];
	
	CGSize titleLabelSize = [titleLabel sizeThatFits:CGSizeMake(CGRectGetWidth(titleLabel.frame), CGFLOAT_MAX)];
	CGFloat titleLabelHeight = MAX(kReviewTitleFontSize + 3.0f, titleLabelSize.height);
	titleLabel.frame = CGRectMake(CGRectGetMinX(titleLabel.frame), CGRectGetMinY(titleLabel.frame), CGRectGetWidth(titleLabel.frame), titleLabelHeight);
	
	replyView.frame = CGRectMake(CGRectGetMinX(replyView.frame), CGRectGetMaxY(titleLabel.frame) + 4.0f + 2.0f, CGRectGetWidth(replyView.frame), CGRectGetHeight(replyView.frame));
	
	CGSize contentSize = self.contentView.bounds.size;
	CGFloat replyViewWidth = replyView.alpha ? (4.0f + CGRectGetWidth(replyView.frame)) : 0.0f;
	nicknameLabel.frame = CGRectMake(CGRectGetMinX(nicknameLabel.frame), CGRectGetMaxY(titleLabel.frame) + 4.0f, contentSize.width - kReviewMarginHorizontal - replyViewWidth - kReviewMarginHorizontal, CGRectGetHeight(nicknameLabel.frame));
	
	CGSize reviewLabelSize = [reviewLabel sizeThatFits:CGSizeMake(CGRectGetWidth(reviewLabel.frame), CGFLOAT_MAX)];
	CGFloat reviewLabelHeight = MAX(kReviewTextFontSize + 3.0f, reviewLabelSize.height);
	reviewLabel.frame = CGRectMake(CGRectGetMinX(reviewLabel.frame), CGRectGetMaxY(nicknameLabel.frame) + 4.0f, CGRectGetWidth(reviewLabel.frame), reviewLabelHeight);
	
	detailsLabel.frame = CGRectMake(CGRectGetMinX(detailsLabel.frame), CGRectGetMaxY(reviewLabel.frame) + 4.0f, CGRectGetWidth(detailsLabel.frame), CGRectGetHeight(detailsLabel.frame));
}

- (void)layoutSubviews {
	[super layoutSubviews];
	[self layoutContent];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated  {
	[super setHighlighted:highlighted animated:animated];
	colorView.backgroundColor = self.tintColor;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated  {
	[super setSelected:selected animated:animated];
	colorView.backgroundColor = self.tintColor;
}

- (void)setReview:(Review *)_review {
	review = _review;
	NSString *countryName = [[CountryDictionary sharedDictionary] nameForCountryCode:review.countryCode.uppercaseString];
	
	colorView.alpha = review.unread.boolValue;
	starRatingView.rating = review.rating.integerValue;
	replyView.alpha = (review.developerResponse != nil);
	titleLabel.text = review.title ?: NSLocalizedString(@"Untitled", nil);
	nicknameLabel.text = [NSString stringWithFormat:@"by %@ - %@", review.nickname ?: NSLocalizedString(@"Username", nil), [dateFormatter stringFromDate:review.lastModified]];
	reviewLabel.text = review.text ?: NSLocalizedString(@"Lorem ipsum dolor sit amet.", nil);
	detailsLabel.text = [NSString stringWithFormat:@"Version %@  |  %@", review.version.number, countryName];
	
	[self layoutContent];
}

@end
