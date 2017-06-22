//
//  ReviewListViewController.m
//  AppSales
//
//  Created by Nicolas Gomollon on 6/21/17.
//
//

#import "ReviewListViewController.h"
#import "ReviewDetailViewController.h"
#import "ReviewFilterViewController.h"
#import "ReviewCell.h"
#import "ASAccount.h"
#import "Review.h"
#import "Product.h"
#import "Version.h"
#import "ReviewFilter.h"
#import "ReviewFilterOption.h"
#import "CountryDictionary.h"

@implementation ReviewListViewController

@synthesize fetchedResultsController, managedObjectContext;

- (instancetype)initWithProduct:(Product *)_product {
	self = [super initWithStyle:UITableViewStylePlain];
	if (self) {
		product = _product;
		managedObjectContext = product.managedObjectContext;
		self.title = product.displayName;
		
		filters = [[NSMutableDictionary alloc] init];
		applied = [[NSMutableArray alloc] init];
		{
			NSArray<Version *> *versions = [product.versions.allObjects sortedArrayUsingComparator:^NSComparisonResult(Version *version1, Version *version2) {
				return version1.identifier.integerValue < version2.identifier.integerValue;
			}];
			
			NSMutableArray<ReviewFilterOption *> *options = [[NSMutableArray alloc] init];
			[options addObject:[ReviewFilterOption title:NSLocalizedString(@"All", nil) predicate:@"" object:nil]];
			for (NSInteger i = 0; i < versions.count; i++) {
				Version *version = versions[i];
				ReviewFilterOption *option = [ReviewFilterOption title:version.number predicate:nil object:version];
				if (i == 0) {
					option.subtitle = NSLocalizedString(@"Latest", nil);
				}
				[options addObject:option];
			}
			filters[@(0)] = [ReviewFilter title:NSLocalizedString(@"Version", nil) predicate:@"(version == %@)" options:options];
		}
		{
			NSEntityDescription *entity = [NSEntityDescription entityForName:@"Review" inManagedObjectContext:self.managedObjectContext];
			NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Review"];
			fetchRequest.predicate = [NSPredicate predicateWithFormat:@"(product == %@)" argumentArray:@[product]];
			fetchRequest.resultType = NSDictionaryResultType;
			fetchRequest.propertiesToFetch = @[entity.propertiesByName[@"countryCode"]];
			fetchRequest.returnsDistinctResults = YES;
			
			NSMutableArray<ReviewFilterOption *> *countries = [[NSMutableArray alloc] init];
			NSArray<NSDictionary<NSString *, NSString *> *> *cDicts = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
			for (NSDictionary<NSString *, NSString *> *cDict in cDicts) {
				NSString *countryCode = cDict[@"countryCode"].uppercaseString;
				NSString *countryName = [[CountryDictionary sharedDictionary] nameForCountryCode:countryCode];
				[countries addObject:[ReviewFilterOption title:countryName predicate:nil object:countryCode]];
			}
			NSArray<ReviewFilterOption *> *options = [countries sortedArrayUsingComparator:^NSComparisonResult(ReviewFilterOption *option1, ReviewFilterOption *option2) {
				return [option1.title compare:option2.title options:(NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch)];
			}];
			options = [@[[ReviewFilterOption title:NSLocalizedString(@"All", nil) predicate:@"" object:nil]] arrayByAddingObjectsFromArray:options];
			
			filters[@(1)] = [ReviewFilter title:NSLocalizedString(@"Country", nil) predicate:@"(countryCode == %@)" options:options];
		}
		{
			NSArray<ReviewFilterOption *> *options = @[[ReviewFilterOption title:NSLocalizedString(@"All", nil) predicate:@"" object:nil],
													   [ReviewFilterOption title:@"\u2605\u2605\u2605\u2605\u2605" predicate:nil object:@(5)],
													   [ReviewFilterOption title:@"\u2605\u2605\u2605\u2605\u2606" predicate:nil object:@(4)],
													   [ReviewFilterOption title:@"\u2605\u2605\u2605\u2606\u2606" predicate:nil object:@(3)],
													   [ReviewFilterOption title:@"\u2605\u2605\u2606\u2606\u2606" predicate:nil object:@(2)],
													   [ReviewFilterOption title:@"\u2605\u2606\u2606\u2606\u2606" predicate:nil object:@(1)]];
			filters[@(2)] = [ReviewFilter title:NSLocalizedString(@"Rating", nil) predicate:@"(rating == %@)" options:options];
		}
		{
			NSArray<ReviewFilterOption *> *options = @[[ReviewFilterOption title:NSLocalizedString(@"All", nil) predicate:@"" object:nil],
													   [ReviewFilterOption title:NSLocalizedString(@"With Reply", nil) predicate:@"(developerResponse != nil)" object:nil],
													   [ReviewFilterOption title:NSLocalizedString(@"Without Reply", nil) predicate:@"(developerResponse == nil)" object:nil],
													   [ReviewFilterOption title:NSLocalizedString(@"Edited", nil) predicate:@"(edited == %@)" object:@YES]];
			filters[@(3)] = [ReviewFilter title:NSLocalizedString(@"Review", nil) predicate:nil options:options];
		}
		{
			NSArray<ReviewFilterOption *> *options = @[[ReviewFilterOption title:NSLocalizedString(@"All", nil) predicate:@"" object:nil],
													   [ReviewFilterOption title:NSLocalizedString(@"Unread", nil) predicate:nil object:@YES],
													   [ReviewFilterOption title:NSLocalizedString(@"Read", nil) predicate:nil object:@NO]];
			filters[@(4)] = [ReviewFilter title:NSLocalizedString(@"Status", nil) predicate:@"(unread == %@)" options:options];
		}
		reviewFilter = [[ReviewFilterViewController alloc] init];
		reviewFilter.filters = filters;
		reviewFilter.applied = applied;
	}
	return self;
}

- (void)loadView {
	[super loadView];
	[self.tableView registerClass:[ReviewCell class] forCellReuseIdentifier:@"Cell"];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	// Do any additional setup after loading the view.
	filterButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Filter"] style:UIBarButtonItemStylePlain target:self action:@selector(filterButtonPressed:)];
	filterButton.image = (applied.count > 0) ? [UIImage imageNamed:@"FilterActive"] : [UIImage imageNamed:@"Filter"];
	
	UIBarButtonItem *markAllButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Circle"] style:UIBarButtonItemStylePlain target:self action:@selector(markAllReviews)];
	
	self.navigationItem.rightBarButtonItems = @[filterButton, markAllButton];
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

- (void)filterButtonPressed:(id)sender {
	reviewFilter.filters = filters;
	reviewFilter.applied = applied;
	
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:reviewFilter];
	navController.modalPresentationStyle = UIModalPresentationPopover;
	
	UIPopoverPresentationController *popoverController = navController.popoverPresentationController;
	popoverController.permittedArrowDirections = UIPopoverArrowDirectionUp;
	popoverController.barButtonItem = sender;
	popoverController.delegate = self;
	
	[self presentViewController:navController animated:YES completion:nil];
}

- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
	filters = reviewFilter.filters;
	applied = reviewFilter.applied;
	
	filterButton.image = (applied.count > 0) ? [UIImage imageNamed:@"FilterActive"] : [UIImage imageNamed:@"Filter"];
	fetchedResultsController = nil;
	[self.tableView reloadData];
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
	return UIModalPresentationNone;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return self.fetchedResultsController.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.fetchedResultsController.sections[section].numberOfObjects;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	Review *review = [self.fetchedResultsController objectAtIndexPath:indexPath];
	return [[ReviewCellHelper sharedHelper] heightForReview:review thatFits:tableView.contentSize.width];
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
	fetchRequest.entity = [NSEntityDescription entityForName:@"Review" inManagedObjectContext:managedObjectContext];
	
	NSMutableString *pred = [NSMutableString stringWithString:@"(product == %@)"];
	NSMutableArray *args = [NSMutableArray arrayWithObject:product];
	
	for (NSNumber *index in applied) {
		ReviewFilter *filter = filters[index];
		[pred appendString:[@" AND " stringByAppendingString:filter.predicate]];
		if (filter.object != nil) {
			[args addObject:filter.object];
		}
	}
	
	fetchRequest.predicate = [NSPredicate predicateWithFormat:pred argumentArray:args];
	fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"lastModified" ascending:NO]];
	fetchRequest.fetchBatchSize = 20;
	
	fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
																   managedObjectContext:managedObjectContext
																	 sectionNameKeyPath:nil
																			  cacheName:nil];
	fetchedResultsController.delegate = self;
	
	NSError *error = nil;
	if (![fetchedResultsController performFetch:&error]) {
		NSLog(@"Unresolved error %@, %@", error, error.userInfo);
		abort();
	}
	
	return fetchedResultsController;
}

#pragma mark - Fetched results controller delegate

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	[self.tableView reloadData];
}

@end
