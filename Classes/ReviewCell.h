//
//  ReviewCell.h
//  AppSales
//
//  Created by Nicolas Gomollon on 6/18/17.
//
//

#import <UIKit/UIKit.h>

@class Review, StarRatingView;

@interface ReviewCellHelper : NSObject {
	NSDictionary<NSString *, id> *titleAttrs;
	NSDictionary<NSString *, id> *reviewAttrs;
}

- (instancetype)init;
+ (instancetype)sharedHelper;

- (CGFloat)titleLabelHeightForReview:(Review *)review thatFits:(CGFloat)width;
- (CGFloat)reviewLabelHeightForReview:(Review *)review thatFits:(CGFloat)width;
- (CGFloat)heightForReview:(Review *)review thatFits:(CGFloat)width;

@end

@interface ReviewCell : UITableViewCell {
	NSDateFormatter *dateFormatter;
	UIView *colorView;
	StarRatingView *starRatingView;
	UITextView *titleLabel;
	UIImageView *replyView;
	UILabel *nicknameLabel;
	UILabel *reviewLabel;
	UILabel *detailsLabel;
}

@property (nonatomic, strong) Review *review;

@end
