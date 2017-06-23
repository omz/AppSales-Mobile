//
//  ReviewFilterViewController.h
//  AppSales
//
//  Created by Nicolas Gomollon on 6/19/17.
//
//

#import <UIKit/UIKit.h>

@class ReviewFilter;

@interface ReviewFilterViewController : UITableViewController

@property (nonatomic, strong) NSMutableArray<ReviewFilter *> *filters;

@end
