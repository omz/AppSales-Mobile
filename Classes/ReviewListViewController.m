//
//  ReviewListViewController.m
//  AppSales
//
//  Created by Ole Zorn on 27.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "ReviewListViewController.h"
#import "ReviewDetailViewController.h"
#import "ASAccount.h"
#import "Review.h"
#import "Product.h"


@implementation ReviewListViewController

@synthesize fetchedResultsController, managedObjectContext;

- (id)initWithAccount:(ASAccount *)acc product:(Product *)reviewProduct rating:(NSUInteger)ratingFilter
{
	self = [super initWithStyle:UITableViewStylePlain];
	if (self) {
		account = [acc retain];
		managedObjectContext = [[account managedObjectContext] retain];
		rating = ratingFilter;
		product = [reviewProduct retain];
		self.title = NSLocalizedString(@"Reviews", nil);
		
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Check.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(markAllAsRead:)] autorelease];
	}
	return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)markAllAsRead:(id)sender
{
	for (Review *review in self.fetchedResultsController.fetchedObjects) {
		if ([review.unread boolValue]) {
			review.unread = [NSNumber numberWithBool:NO];
		}
	}
	[self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [[[self.fetchedResultsController sections] objectAtIndex:section] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier = @"Cell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	
	Review *review = [self.fetchedResultsController objectAtIndexPath:indexPath];
	cell.textLabel.font = [UIFont boldSystemFontOfSize:14.0];
	cell.imageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png", review.countryCode]];
	NSString *ratingString = [@"" stringByPaddingToLength:[review.rating integerValue] withString:@"\u2605" startingAtIndex:0];
	cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@", ratingString, [review.product displayName]];
	cell.textLabel.text = review.title;
	if ([review.unread boolValue]) {
		cell.textLabel.textColor = [UIColor blackColor];
	} else {
		cell.textLabel.textColor = [UIColor grayColor];
	}
    
    return cell;
}

- (float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 50.0;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	Review *selectedReview = [self.fetchedResultsController objectAtIndexPath:indexPath];
	ReviewDetailViewController *vc = [[[ReviewDetailViewController alloc] initWithReview:selectedReview] autorelease];
	[self.navigationController pushViewController:vc animated:YES];
}


#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
	if (fetchedResultsController != nil) {
		return fetchedResultsController;
	}
	NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Review" inManagedObjectContext:self.managedObjectContext];
	if (product) {
		if (rating == 0) {
			[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"product == %@", product]];
		} else {
			[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"product == %@ AND rating == %@", product, [NSNumber numberWithInteger:rating]]];
		}
	} else {
		if (rating == 0) {
			[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"product.account == %@", account]];
		} else {
			[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"product.account == %@ AND rating == %@", account, [NSNumber numberWithInteger:rating]]];
		}
	}
	[fetchRequest setEntity:entity];
	[fetchRequest setFetchBatchSize:20];
    
	//Show latest unread reviews first:
	NSSortDescriptor *sortDescriptorUnread = [[[NSSortDescriptor alloc] initWithKey:@"unread" ascending:NO] autorelease];
	NSSortDescriptor *sortDescriptorDownloadDate = [[[NSSortDescriptor alloc] initWithKey:@"downloadDate" ascending:NO] autorelease];
	NSSortDescriptor *sortDescriptorReviewDate = [[[NSSortDescriptor alloc] initWithKey:@"reviewDate" ascending:NO] autorelease];
	
    NSArray *sortDescriptors = [NSArray arrayWithObjects:sortDescriptorUnread, sortDescriptorReviewDate, sortDescriptorDownloadDate, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    NSFetchedResultsController *aFetchedResultsController = [[[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest 
																								 managedObjectContext:self.managedObjectContext 
																								   sectionNameKeyPath:nil 
																											cacheName:nil] autorelease];
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

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
	[self.tableView reloadData];
}

- (void)dealloc
{
	[product release];
	[account release];
	[fetchedResultsController release];
	[managedObjectContext release];
	[super dealloc];
}

@end
