//
//  ReviewListViewController.h
//  AppSales
//
//  Created by Nicolas Gomollon on 6/21/17.
//
//

#import <UIKit/UIKit.h>
#import "ReviewListHeaderView.h"

@class Product, ReviewListHeaderView, ReviewFilter, ReviewFilterViewController;

@interface ReviewListViewController : UITableViewController <NSFetchedResultsControllerDelegate, UIPopoverPresentationControllerDelegate, ReviewListHeaderViewDataSource> {
	Product *product;
	ReviewListHeaderView *headerView;
	
	NSMutableArray<ReviewFilter *> *filters;
	ReviewFilterViewController *reviewFilter;
	UIBarButtonItem *filterButton;
	
	NSFetchedResultsController *fetchedResultsController;
	NSManagedObjectContext *managedObjectContext;
}

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

- (instancetype)initWithProduct:(Product *)_product;

@end
