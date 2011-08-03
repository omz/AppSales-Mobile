//
//  BadgedCell.h
//  AppSales
//
//  Created by Ole Zorn on 01.08.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BadgedCell : UITableViewCell {

	UIImageView *badgeView;
	UILabel *badgeLabel;
	NSInteger badgeCount;
}

@property (nonatomic, assign) NSInteger badgeCount;

@end
