//
//  ReviewListViewController.h
//  AppSales
//
//  Created by Ole Zorn on 27.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ASAccount, Product;

@interface ReviewListViewController : UITableViewController <NSFetchedResultsControllerDelegate> {

	ASAccount *account;
	NSArray *products;
	NSUInteger rating;
	
	NSFetchedResultsController *fetchedResultsController;
	NSManagedObjectContext *managedObjectContext;
}

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

- (id)initWithAccount:(ASAccount *)acc products:(NSArray *)reviewProducts rating:(NSUInteger)ratingFilter;

@end
