//
//  ReviewFilterDetailViewController.h
//  AppSales
//
//  Created by Nicolas Gomollon on 6/21/17.
//
//

#import <UIKit/UIKit.h>

@class ReviewFilter;

@interface ReviewFilterDetailViewController : UITableViewController {
	ReviewFilter *filter;
}

- (instancetype)initWithFilter:(ReviewFilter *)_filter;

@end
