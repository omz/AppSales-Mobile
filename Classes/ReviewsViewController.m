//
//  ReviewsViewController.m
//  AppSales
//
//  Created by Nicolas Gomollon on 12/7/15.
//
//

#import "ReviewsViewController.h"
#import "ASAccount.h"
#import "Product.h"
#import "BadgedCell.h"
#import "ReviewsByVersionViewController.h"

@implementation ReviewsViewController

- (instancetype)initWithAccount:(ASAccount *)_account {
	account = _account;
	self = [super initWithStyle:UITableViewStyleGrouped];
	if (self) {
		self.title = NSLocalizedString(@"Reviews", nil);
		self.tabBarItem.image = [UIImage imageNamed:@"Reviews"];
		self.hidesBottomBarWhenPushed = [UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad;
	}
	return self;
}

- (void)loadView {
	[super loadView];
	
	[self.tableView registerClass:[BadgedCell class] forCellReuseIdentifier:@"Cell"];
	
	sortedApps = [[[account.products allObjects] sortedArrayUsingComparator:^NSComparisonResult(Product *product1, Product *product2) {
		NSInteger productID1 = product1.productID.integerValue;
		NSInteger productID2 = product2.productID.integerValue;
		if (productID1 < productID2) {
			return NSOrderedDescending;
		} else if (productID1 > productID2) {
			return NSOrderedAscending;
		}
		return NSOrderedSame;
	}] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(Product *product, NSDictionary *bindings) {
		return !product.hidden.boolValue && !(product.parentSKU.length > 1); // In-App Purchases don't have reviews, so don't include them.
	}]];
	
	[self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self.tableView reloadData];
	[[NSNotificationCenter defaultCenter] addObserver:self.tableView selector:@selector(reloadData) name:NSManagedObjectContextObjectsDidChangeNotification object:account.managedObjectContext];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver:self.tableView];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (NSInteger)unreadCount:(Product *)product {
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	fetchRequest.entity = [NSEntityDescription entityForName:@"Review" inManagedObjectContext:product.managedObjectContext];
	fetchRequest.predicate = [NSPredicate predicateWithFormat:@"product == %@ AND unread == TRUE", product];
	return [product.managedObjectContext countForFetchRequest:fetchRequest error:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return sortedApps.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 44.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	BadgedCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	
	// Configure the cell...
	Product *product = sortedApps[indexPath.row];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	cell.badgeCount = [self unreadCount:product];
	cell.product = product;
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	Product *product = sortedApps[indexPath.row];
	ReviewsByVersionViewController *reviewsByVersionVC = [[ReviewsByVersionViewController alloc] initWithProduct:product];
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
		[self.navigationController pushViewController:reviewsByVersionVC animated:YES];
	} else {
		UINavigationController *reviewsByVersionNC = [[UINavigationController alloc] initWithRootViewController:reviewsByVersionVC];
		reviewsByVersionNC.modalPresentationStyle = UIModalPresentationFormSheet;
		reviewsByVersionNC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
		[self presentViewController:reviewsByVersionNC animated:YES completion:nil];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
		return YES;
	}
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
	return UIInterfaceOrientationMaskPortrait;
}

@end
