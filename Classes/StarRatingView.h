//
//  StarRatingView.h
//  AppSales
//
//  Created by Nicolas Gomollon on 6/18/17.
//
//

#import <UIKit/UIKit.h>

@interface StarRatingView : UIView {
	UIImageView *star1;
	UIImageView *star2;
	UIImageView *star3;
	UIImageView *star4;
	UIImageView *star5;
}

@property (nonatomic, assign) NSInteger rating;
@property (nonatomic, assign) CGPoint origin;
@property (nonatomic, assign) CGFloat height;

- (instancetype)init;
- (instancetype)initWithOrigin:(CGPoint)origin;
- (instancetype)initWithOrigin:(CGPoint)origin height:(CGFloat)height;
- (instancetype)initWithFrame:(CGRect)frame;

@end
