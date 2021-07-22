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
#import "ReviewListHeaderView.h"
#import "ReviewCell.h"
#import "ASAccount.h"
#import "Review.h"
#import "Product.h"
#import "Version.h"
#import "ReviewFilter.h"
#import "ReviewFilterOption.h"
#import "ReviewFilterComparator.h"
#import "CountryDictionary.h"

@implementation ReviewListViewController

@synthesize fetchedResultsController, managedObjectContext;

- (instancetype)initWithProduct:(Product *)_product {
	self = [super initWithStyle:UITableViewStylePlain];
	if (self) {
		product = _product;
		managedObjectContext = product.managedObjectContext;
		self.title = product.displayName;
		
		filters = [[NSMutableArray alloc] init];
		{
			NSArray<Version *> *versions = [product.versions.allObjects sortedArrayUsingComparator:^NSComparisonResult(Version *version1, Version *version2) {
				return version1.identifier.integerValue < version2.identifier.integerValue;
			}];
			
			NSMutableArray<ReviewFilterOption *> *options = [[NSMutableArray alloc] init];
			for (NSInteger i = 0; i < versions.count; i++) {
				Version *version = versions[i];
				ReviewFilterOption *option = [ReviewFilterOption title:version.number predicate:nil object:version];
				if (i == 0) {
					option.subtitle = NSLocalizedString(@"Latest", nil);
				}
				[options addObject:option];
			}
			
			ReviewFilter *filter = [ReviewFilter title:NSLocalizedString(@"Version", nil) predicate:@"(version %@ %@)" options:options];
			filter.comparators = @[[ReviewFilterComparator comparator:@"==" title:@"Equals"],
								   [ReviewFilterComparator comparator:@"!=" title:@"Does Not Equal"],
								   [ReviewFilterComparator comparator:@">" title:@"Is Greater Than"],
								   [ReviewFilterComparator comparator:@">=" title:@"Is Greater Than or Equal To"],
								   [ReviewFilterComparator comparator:@"<" title:@"Is Less Than"],
								   [ReviewFilterComparator comparator:@"<=" title:@"Is Less Than or Equal To"]];
			[filters addObject:filter];
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
			
			ReviewFilter *filter = [ReviewFilter title:NSLocalizedString(@"Country", nil) predicate:@"(countryCode %@ %@)" options:options];
			filter.comparators = @[[ReviewFilterComparator comparator:@"==" title:@"Equals"],
								   [ReviewFilterComparator comparator:@"!=" title:@"Does Not Equal"]];
			[filters addObject:filter];
		}
		{
			NSArray<ReviewFilterOption *> *options = @[[ReviewFilterOption title:@"\u2605\u2605\u2605\u2605\u2605" predicate:nil object:@(5)],
													   [ReviewFilterOption title:@"\u2605\u2605\u2605\u2605\u2606" predicate:nil object:@(4)],
													   [ReviewFilterOption title:@"\u2605\u2605\u2605\u2606\u2606" predicate:nil object:@(3)],
													   [ReviewFilterOption title:@"\u2605\u2605\u2606\u2606\u2606" predicate:nil object:@(2)],
													   [ReviewFilterOption title:@"\u2605\u2606\u2606\u2606\u2606" predicate:nil object:@(1)]];
			ReviewFilter *filter = [ReviewFilter title:NSLocalizedString(@"Rating", nil) predicate:@"(rating %@ %@)" options:options];
			filter.comparators = @[[ReviewFilterComparator comparator:@"==" title:@"Equals"],
								   [ReviewFilterComparator comparator:@"!=" title:@"Does Not Equal"],
								   [ReviewFilterComparator comparator:@">" title:@"Is Greater Than"],
								   [ReviewFilterComparator comparator:@">=" title:@"Is Greater Than or Equal To"],
								   [ReviewFilterComparator comparator:@"<" title:@"Is Less Than"],
								   [ReviewFilterComparator comparator:@"<=" title:@"Is Less Than or Equal To"]];
			[filters addObject:filter];
		}
		{
			NSArray<ReviewFilterOption *> *options = @[[ReviewFilterOption title:NSLocalizedString(@"With Reply", nil) predicate:@"(developerResponse != nil)" object:nil],
													   [ReviewFilterOption title:NSLocalizedString(@"Without Reply", nil) predicate:@"(developerResponse == nil)" object:nil],
													   [ReviewFilterOption title:NSLocalizedString(@"Edited", nil) predicate:@"(edited == %@)" object:@YES]];
			[filters addObject:[ReviewFilter title:NSLocalizedString(@"Review", nil) predicate:nil options:options]];
		}
		{
			NSArray<ReviewFilterOption *> *options = @[[ReviewFilterOption title:NSLocalizedString(@"Unread", nil) predicate:nil object:@YES],
													   [ReviewFilterOption title:NSLocalizedString(@"Read", nil) predicate:nil object:@NO]];
			[filters addObject:[ReviewFilter title:NSLocalizedString(@"Status", nil) predicate:@"(unread == %@)" options:options]];
		}
		reviewFilter = [[ReviewFilterViewController alloc] init];
		reviewFilter.filters = filters;
	}
	return self;
}

- (void)loadView {
	[super loadView];
	headerView = [[ReviewListHeaderView alloc] init];
	headerView.dataSource = self;
	[self.tableView registerClass:[ReviewCell class] forCellReuseIdentifier:@"Cell"];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	// Do any additional setup after loading the view.
	filterButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Filter"] style:UIBarButtonItemStylePlain target:self action:@selector(filterButtonPressed:)];
	filterButton.image = (self.enabledFilters.count > 0) ? [UIImage imageNamed:@"FilterActive"] : [UIImage imageNamed:@"Filter"];
	
	UIBarButtonItem *markAllButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Circle"] style:UIBarButtonItemStylePlain target:self action:@selector(markAllReviews)];
	
	self.navigationItem.rightBarButtonItems = @[filterButton, markAllButton];
	
	headerView.frame = CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.tableView.frame), CGRectGetHeight(headerView.frame));
	self.tableView.tableHeaderView = headerView;
	
	[headerView reloadData];
}

- (NSArray<ReviewFilter *> *)enabledFilters {
	return [filters filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(ReviewFilter *_Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
		return evaluatedObject.isEnabled;
	}]];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        return UIInterfaceOrientationMaskAll;
    }
    return UIInterfaceOrientationMaskPortrait;
}

- (void)markAllReviewsUnread:(BOOL)unread {
    NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
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
	
	filterButton.image = (self.enabledFilters.count > 0) ? [UIImage imageNamed:@"FilterActive"] : [UIImage imageNamed:@"Filter"];
	fetchedResultsController = nil;
	
	[headerView reloadData];
	[self.tableView reloadData];
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
	return UIModalPresentationNone;
}

#pragma mark - UITableViewDataSource

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

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	ReviewDetailViewController *vc = [[ReviewDetailViewController alloc] initWithReviews:self.fetchedResultsController.sections[indexPath.section].objects selectedIndex:indexPath.row];
	[self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - NSFetchedResultsController

- (NSFetchedResultsController *)fetchedResultsController {
	if (fetchedResultsController != nil) {
		return fetchedResultsController;
	}
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	fetchRequest.entity = [NSEntityDescription entityForName:@"Review" inManagedObjectContext:managedObjectContext];
	
	NSMutableString *pred = [NSMutableString stringWithString:@"(product == %@)"];
	NSMutableArray *args = [NSMutableArray arrayWithObject:product];
	
	for (ReviewFilter *filter in filters) {
		if (!filter.isEnabled) { continue; }
		if (filter.predicate.length == 0) { continue; }
		[pred appendString:[@" AND " stringByAppendingString:filter.predicate]];
		if (filter.object == nil) { continue; }
		[args addObject:filter.object];
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

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	[headerView reloadData];
	[self.tableView reloadData];
}

#pragma mark - ReviewListHeaderViewDataSource

- (NSUInteger)reviewListHeaderView:(ReviewListHeaderView *)headerView numberOfReviewsForRating:(NSInteger)rating {
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	fetchRequest.entity = [NSEntityDescription entityForName:@"Review" inManagedObjectContext:managedObjectContext];
	
	NSMutableString *pred = [NSMutableString stringWithString:@"(product == %@)"];
	NSMutableArray *args = [NSMutableArray arrayWithObject:product];
	
	[pred appendString:@" AND (rating == %@)"];
	[args addObject:@(rating)];
	
	for (ReviewFilter *filter in filters) {
		if (!filter.isEnabled) { continue; }
		if (filter.predicate.length == 0) { continue; }
		[pred appendString:[@" AND " stringByAppendingString:filter.predicate]];
		if (filter.object == nil) { continue; }
		[args addObject:filter.object];
	}
	
	fetchRequest.predicate = [NSPredicate predicateWithFormat:pred argumentArray:args];
	return [product.managedObjectContext countForFetchRequest:fetchRequest error:nil];
}

@end
