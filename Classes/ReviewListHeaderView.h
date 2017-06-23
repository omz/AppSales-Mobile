//
//  ReviewListHeaderView.h
//  AppSales
//
//  Created by Nicolas Gomollon on 6/23/17.
//
//

#import <UIKit/UIKit.h>

@class ReviewListHeaderView;

@protocol ReviewListHeaderViewDataSource <NSObject>
@required
- (NSUInteger)reviewListHeaderView:(ReviewListHeaderView *)headerView numberOfReviewsForRating:(NSInteger)rating;
@end

@interface StarRatingProgressView : UIProgressView
@end

@interface ReviewListHeaderView : UIView {
	NSNumberFormatter *formatter;
	NSNumberFormatter *avgFormatter;
	
	UILabel *averageLabel;
	UILabel *totalReviewsLabel;
	
	StarRatingProgressView *progressView5;
	UILabel *reviewLabel5;
	
	StarRatingProgressView *progressView4;
	UILabel *reviewLabel4;
	
	StarRatingProgressView *progressView3;
	UILabel *reviewLabel3;
	
	StarRatingProgressView *progressView2;
	UILabel *reviewLabel2;
	
	StarRatingProgressView *progressView1;
	UILabel *reviewLabel1;
	
	UIView *separator;
}

@property (nonatomic, weak) id<ReviewListHeaderViewDataSource> dataSource;

- (void)reloadData;

@end
