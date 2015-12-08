//
//  DashboardAppCell.h
//  AppSales
//
//  Created by Ole Zorn on 19.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>

extern CGFloat const kIconSize;
extern CGFloat const kIconPadding;
extern CGFloat const kLabelPadding;

@class Product, ColorButton, AppIconView;

@interface DashboardAppCell : UITableViewCell {
	UIView *colorView;
	AppIconView *iconView;
	UILabel *nameLabel;
}

@property (nonatomic, strong) Product *product;

@end
