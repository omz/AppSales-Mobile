//
//  ReviewCell.h
//  AppSales
//
//  Created by Nicolas Gomollon on 6/18/17.
//
//

#import <UIKit/UIKit.h>

@class Review, StarRatingView;

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

+ (CGFloat)heightForReview:(Review *)review thatFits:(CGFloat)width;

@end
