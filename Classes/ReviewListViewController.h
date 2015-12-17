//
//  ReviewListViewController.h
//  AppSales
//
//  Created by Ole Zorn on 27.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Product, Version;

@interface ReviewListViewController : UITableViewController <NSFetchedResultsControllerDelegate> {
	Product *product;
	NSArray<Version *> *versions;
	NSUInteger rating;
	
	NSFetchedResultsController *fetchedResultsController;
	NSManagedObjectContext *managedObjectContext;
}

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

- (instancetype)initWithProduct:(Product *)_product versions:(NSArray<Version *> *)_versions rating:(NSUInteger)ratingFilter;

@end
