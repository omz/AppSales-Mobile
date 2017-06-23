//
//  ReviewListViewController.h
//  AppSales
//
//  Created by Nicolas Gomollon on 6/21/17.
//
//

#import <UIKit/UIKit.h>

@class Product, ReviewFilter, ReviewFilterViewController;

@interface ReviewListViewController : UITableViewController <NSFetchedResultsControllerDelegate, UIPopoverPresentationControllerDelegate> {
	Product *product;
	
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
