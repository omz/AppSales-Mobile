//
//  BadgedCell.h
//  AppSales
//
//  Created by Ole Zorn on 01.08.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>
#import "DashboardAppCell.h"

@interface BadgedCell : DashboardAppCell {
	NSLayoutConstraint *textLabelLeftConstraint;
	NSLayoutConstraint *textLabelLeftMarginConstraint;
	NSLayoutConstraint *badgeViewWidthConstraint;
	NSLayoutConstraint *badgeViewRightConstraint;
	NSLayoutConstraint *badgeViewRightMarginConstraint;
	UIImageView *badgeView;
	UILabel *badgeLabel;
	NSNumberFormatter *numberFormatter;
}

@property (nonatomic, strong) NSString *imageName;
@property (nonatomic, assign) NSInteger badgeCount;

@end
