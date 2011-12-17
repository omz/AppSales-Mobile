//
//  ReviewSummaryView.h
//  AppSales
//
//  Created by Ole Zorn on 27.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ReviewSummaryView;

@protocol ReviewSummaryViewDataSource <NSObject>

- (NSUInteger)reviewSummaryView:(ReviewSummaryView *)view numberOfReviewsForRating:(NSInteger)rating;
- (NSUInteger)reviewSummaryView:(ReviewSummaryView *)view numberOfUnreadReviewsForRating:(NSInteger)rating;

@end

@protocol ReviewSummaryViewDelegate <NSObject>

- (void)reviewSummaryView:(ReviewSummaryView *)view didSelectRating:(NSInteger)rating;

@end

@interface ReviewSummaryView : UIView {

	id<ReviewSummaryViewDataSource> __unsafe_unretained dataSource;
	id<ReviewSummaryViewDelegate> __unsafe_unretained delegate;
	NSMutableArray *barViews;
	NSMutableArray *barLabels;
	UILabel *averageLabel;
	UILabel *sumLabel;
}

@property (nonatomic, unsafe_unretained) id<ReviewSummaryViewDataSource> dataSource;
@property (nonatomic, unsafe_unretained) id<ReviewSummaryViewDelegate> delegate;

- (void)reloadDataAnimated:(BOOL)animated;
- (CGRect)barFrameForRating:(NSInteger)rating;

@end
