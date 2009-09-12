//
//  AppCell.h
//  AppSalesMobile
//
//  Created by Ole Zorn on 12.09.09.
//  Copyright 2009 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class App, AppCellView;

@interface AppCell : UITableViewCell {

	App *app;
	AppCellView *cellView;
}

@property (nonatomic, retain) App *app;

@end



@interface AppCellView : UIView {

	AppCell *cell;
}

- (id)initWithCell:(AppCell *)appCell;

@end