//
//  ReviewsListController.h
//  AppSalesMobile
//
//  Created by Ole Zorn on 12.09.09.
//  Copyright 2009 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ReviewsListController : UITableViewController {

	NSArray *reviews;
}

@property (nonatomic, retain) NSArray *reviews;

@end
