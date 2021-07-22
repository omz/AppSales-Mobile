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

- (instancetype)initWithAccount:(ASAccount *)anAccount {
	self = [super initWithStyle:UITableViewStyleGrouped];
	if (self) {
		account = anAccount;
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextDidChange:) name:NSManagedObjectContextObjectsDidChangeNotification object:account.managedObjectContext];
		
		self.title = NSLocalizedString(@"Promo Codes", nil);
		self.tabBarItem.image = [UIImage imageNamed:@"PromoCodes"];
	}
	return self;
}

- (void)loadView {
	[super loadView];
	[self.tableView registerClass:[BadgedCell class] forCellReuseIdentifier:@"Cell"];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	[self reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.toolbarItems = nil;
	self.navigationController.toolbarHidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	self.navigationController.toolbarHidden = NO;
}

- (void)contextDidChange:(NSNotification *)notification {
	NSSet *relevantEntityNames = [NSSet setWithObject:@"PromoCode"];
	NSSet *insertedObjects = notification.userInfo[NSInsertedObjectsKey];
	NSSet *updatedObjects = notification.userInfo[NSUpdatedObjectsKey];
	NSSet *deletedObjects = notification.userInfo[NSDeletedObjectsKey];
	
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

- (void)reloadData {
	NSString *productSortByValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"ProductSortby"];
	NSArray *allApps;
	if ([productSortByValue isEqualToString:@"productName"]) {
		// Sort products by name.
		allApps = [[account.products allObjects] sortedArrayUsingComparator:^NSComparisonResult(Product *product1, Product *product2) {
			return [product1.name caseInsensitiveCompare:product2.name];
		}];
	} else {
		allApps = [[account.products allObjects] sortedArrayUsingComparator:^NSComparisonResult(Product *product1, Product *product2) {
			NSInteger productID1 = product1.productID.integerValue;
			NSInteger productID2 = product2.productID.integerValue;
			if (productID1 < productID2) {
				return NSOrderedDescending;
			} else if (productID1 > productID2) {
				return NSOrderedAscending;
			}
			return NSOrderedSame;
		}];
	}
	
	self.sortedApps = [allApps filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(Product *product, NSDictionary *bindings) {
		return !product.hidden.boolValue && !(product.parentSKU.length > 1); // In-App Purchases don't have promo codes, so don't include them.
	}]];
	
	[self.tableView reloadData];
}

- (NSInteger)unusedCount:(Product *)product {
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	fetchRequest.entity = [NSEntityDescription entityForName:@"PromoCode" inManagedObjectContext:product.managedObjectContext];
	fetchRequest.predicate = [NSPredicate predicateWithFormat:@"product == %@ AND used == FALSE", product];
	return [product.managedObjectContext countForFetchRequest:fetchRequest error:nil];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [sortedApps count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 44.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	BadgedCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	
	// Configure the cell...
	Product *product = sortedApps[indexPath.row];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	cell.badgeCount = [self unusedCount:product];
	cell.product = product;
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	Product *product = sortedApps[indexPath.row];
	PromoCodesAppViewController *vc = [[PromoCodesAppViewController alloc] initWithProduct:product];
	[self.navigationController pushViewController:vc animated:YES];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        return UIInterfaceOrientationMaskAll;
    }
    return UIInterfaceOrientationMaskPortrait;
}

@end
