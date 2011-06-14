//
//  ReviewCell.h
//  AppSalesMobile
//
//  Created by Ole Zorn on 12.09.09.
//  Copyright 2009 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Review, ReviewCellView;

@interface ReviewCell : UITableViewCell {
	ReviewCellView *cellView; // weak reference
	Review *review;
}

@property (nonatomic, retain) Review *review;

@end



@interface ReviewCellView : UIView {
	ReviewCell *cell; // weak reference
}

- (id)initWithCell:(ReviewCell *)reviewCell;

@end