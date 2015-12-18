//
//  ReviewListViewController.m
//  AppSales
//
//  Created by Ole Zorn on 27.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "ReviewListViewController.h"
#import "ReviewDetailViewController.h"
#import "ReviewCell.h"
#import "ASAccount.h"
#import "Review.h"
#import "Product.h"
#import "Version.h"

@implementation ReviewListViewController

@synthesize fetchedResultsController, managedObjectContext;

- (instancetype)initWithProduct:(Product *)_product versions:(NSArray<Version *> *)_versions rating:(NSUInteger)ratingFilter {
	self = [super initWithStyle:UITableViewStylePlain];
	if (self) {
		product = _product;
		versions = _versions;
		rating = ratingFilter;
		managedObjectContext = [product managedObjectContext];
		self.title = product.displayName;
	}
	return self;
}

- (void)loadView {
	[super loadView];
	self.edgesForExtendedLayout = UIRectEdgeNone;
	self.tableView.tableFooterView = [UIView new];
	[self.tableView registerClass:[ReviewCell class] forCellReuseIdentifier:@"Cell"];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	// Do any additional setup after loading the view.
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Mark All…", nil) style:UIBarButtonItemStyleDone target:self action:@selector(markAllReviews)];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)markAllReviewsUnread:(BOOL)unread {
	NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] init];
	moc.persistentStoreCoordinator = self.fetchedResultsController.managedObjectContext.persistentStoreCoordinator;
	moc.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
	
	for (Review *review in self.fetchedResultsController.fetchedObjects) {
		review.unread = @(unread);
	}
	
	[moc.persistentStoreCoordinator performBlockAndWait:^{
		NSError *saveError = nil;
		[moc save:&saveError];
		if (saveError) {
			NSLog(@"Could not save context: %@", saveError);
		}
	}];
}

- (void)markAllReviews {
	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
																			 message:nil
																	  preferredStyle:UIAlertControllerStyleActionSheet];
	
	[alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Mark All Unread", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
		[self markAllReviewsUnread:YES];
	}]];
	
	[alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Mark All Read", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
		[self markAllReviewsUnread:NO];
	}]];
	
	[alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
	
	[self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return self.fetchedResultsController.sections.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return self.fetchedResultsController.sections[section].name;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.fetchedResultsController.sections[section].numberOfObjects;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 50.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	ReviewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	
	// Configure the cell...
	Review *review = [self.fetchedResultsController objectAtIndexPath:indexPath];
	cell.review = review;
	
	return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	ReviewDetailViewController *vc = [[ReviewDetailViewController alloc] initWithReviews:self.fetchedResultsController.sections[indexPath.section].objects selectedIndex:indexPath.row];
	[self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController {
	if (fetchedResultsController != nil) {
		return fetchedResultsController;
	}
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	fetchRequest.entity = [NSEntityDescription entityForName:@"Review" inManagedObjectContext:product.managedObjectContext];
	
	NSMutableString *pred = [NSMutableString stringWithString:@"product == %@"];
	NSMutableArray *args = [NSMutableArray arrayWithObject:product];
	
	if (rating > 0) {
		[pred appendString:@" AND rating = %@"];
		[args addObject:@(rating)];
	}
	
	if (versions.count > 0) {
		[pred appendString:@" AND (version == nil"];
		for (Version *version in versions) {
			[pred appendString:@" OR version == %@"];
			[args addObject:version];
		}
		[pred appendString:@")"];
	}
	
	fetchRequest.predicate = [NSPredicate predicateWithFormat:pred argumentArray:args];
	fetchRequest.fetchBatchSize = 20;
	
	// Show latest unread reviews first.
	NSSortDescriptor *sortDescriptorVersion = [NSSortDescriptor sortDescriptorWithKey:@"version.number" ascending:NO];
	NSSortDescriptor *sortDescriptorReviewDate = [[NSSortDescriptor alloc] initWithKey:@"created" ascending:NO];
	
	fetchRequest.sortDescriptors = @[sortDescriptorVersion, sortDescriptorReviewDate];
	
	NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest 
																								 managedObjectContext:self.managedObjectContext 
																								   sectionNameKeyPath:@"version.number"
																											cacheName:nil];
	aFetchedResultsController.delegate = self;
	self.fetchedResultsController = aFetchedResultsController;
	
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	}
	
	return fetchedResultsController;
}

#pragma mark - Fetched results controller delegate

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	[self.tableView reloadData];
}

@end
