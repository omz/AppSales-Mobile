//
//  ReviewListViewController.h
//  AppSales
//
//  Created by Ole Zorn on 27.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Account, Product;

@interface ReviewListViewController : UITableViewController <NSFetchedResultsControllerDelegate> {

	Account *account;
	Product *product;
	NSUInteger rating;
	
	NSFetchedResultsController *fetchedResultsController;
	NSManagedObjectContext *managedObjectContext;
}

@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

- (id)initWithAccount:(Account *)acc product:(Product *)reviewProduct rating:(NSUInteger)ratingFilter;

@end
