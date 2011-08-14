//
//  PromoCodesViewController.m
//  AppSales
//
//  Created by Ole Zorn on 13.08.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "PromoCodesViewController.h"
#import "PromoCodesAppViewController.h"
#import "ASAccount.h"
#import "Product.h"
#import "BadgedCell.h"

@implementation PromoCodesViewController

@synthesize sortedApps;

- (id)initWithAccount:(ASAccount *)anAccount
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
		account = [anAccount retain];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextDidChange:) name:NSManagedObjectContextObjectsDidChangeNotification object:[account managedObjectContext]];
				
		self.title = NSLocalizedString(@"Promo Codes", nil);
    }
    return self;
}

- (void)viewDidLoad
{
	[self reloadData];
}

- (void)contextDidChange:(NSNotification *)notification
{
	NSSet *relevantEntityNames = [NSSet setWithObject:@"PromoCode"];
	NSSet *insertedObjects = [[notification userInfo] objectForKey:NSInsertedObjectsKey];
	NSSet *updatedObjects = [[notification userInfo] objectForKey:NSUpdatedObjectsKey];
	NSSet *deletedObjects = [[notification userInfo] objectForKey:NSDeletedObjectsKey];
	
	BOOL shouldReload = NO;
	for (NSManagedObject *insertedObject in insertedObjects) {
		if ([relevantEntityNames containsObject:insertedObject.entity.name]) {
			shouldReload = YES;
			break;
		}
	}
	if (!shouldReload) {
		for (NSManagedObject *updatedObject in updatedObjects) {
			if ([relevantEntityNames containsObject:updatedObject.entity.name]) {
				shouldReload = YES;
				break;
			}
		}
	}
	if (!shouldReload) {
		for (NSManagedObject *deletedObject in deletedObjects) {
			if ([relevantEntityNames containsObject:deletedObject.entity.name]) {
				shouldReload = YES;
				break;
			}
		}
	}
	if (shouldReload) {
		[NSObject cancelPreviousPerformRequestsWithTarget:self];
		[self performSelector:@selector(reloadData) withObject:nil afterDelay:0.1];
	}
}

- (void)reloadData
{
	NSArray *allApps = [[account.products allObjects] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"productID" ascending:NO] autorelease]]];
	NSMutableArray *filteredApps = [NSMutableArray array];
	for (Product *app in allApps) {
		//Don't show in-app purchases
		if (!app.parentSKU) {
			[filteredApps addObject:app];
		}
	}
	self.sortedApps = [NSArray arrayWithArray:filteredApps];
	[self.tableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [sortedApps count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier = @"Cell";
	BadgedCell *cell = (BadgedCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[[BadgedCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
	}
    
	Product *app = [sortedApps objectAtIndex:indexPath.row];
	
	NSFetchRequest *unusedPromoCodesRequest = [[[NSFetchRequest alloc] init] autorelease];
	[unusedPromoCodesRequest setEntity:[NSEntityDescription entityForName:@"PromoCode" inManagedObjectContext:[app managedObjectContext]]];
	[unusedPromoCodesRequest setPredicate:[NSPredicate predicateWithFormat:@"product == %@ AND used == FALSE", app]];
	NSInteger count = [[app managedObjectContext] countForFetchRequest:unusedPromoCodesRequest error:NULL];
	
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	cell.badgeCount = count;
	cell.textLabel.text = [app displayName];
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	Product *product = [sortedApps objectAtIndex:indexPath.row];
	PromoCodesAppViewController *vc = [[[PromoCodesAppViewController alloc] initWithProduct:product] autorelease];
	[self.navigationController pushViewController:vc animated:YES];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[sortedApps release];
	[account release];
	[super dealloc];
}

@end
