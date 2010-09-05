//
//  ReviewsListController.h
//  AppSalesMobile
//
//  Created by Ole Zorn on 12.09.09.
//  Copyright 2009 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class App;

@interface ReviewsListController : UITableViewController {
	App *app;
	NSArray *reviews;
}

- (id) initWithApp:(App*)appToUse style:(UITableViewStyle)style;
- (void) readall;

@end
