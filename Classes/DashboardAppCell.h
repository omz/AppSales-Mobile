//
//  DashboardAppCell.h
//  AppSales
//
//  Created by Ole Zorn on 19.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Product, ColorButton, AppIconView;

@interface DashboardAppCell : UITableViewCell {

	ColorButton *colorButton;
	AppIconView *iconView;
	UILabel *nameLabel;
	Product *product;
}

@property (nonatomic, retain) Product *product;
@property (nonatomic, readonly) ColorButton *colorButton;

@end
