//
//  ReviewsViewController.m
//  AppSales
//
//  Created by Nicolas Gomollon on 12/7/15.
//
//

#import "ReviewsViewController.h"
#import "ReviewListViewController.h"
#import "ReportDownloadCoordinator.h"
#import "ASAccount.h"
#import "Product.h"
#import "BadgedCell.h"
#import "StatusToolbar.h"

@implementation ReviewsViewController

- (instancetype)initWithAccount:(ASAccount *)_account {
	account = _account;
	self = [super initWithStyle:UITableViewStyleGrouped];
	if (self) {
		self.title = NSLocalizedString(@"Reviews", nil);
		self.tabBarItem.image = [UIImage imageNamed:@"Reviews"];
		self.hidesBottomBarWhenPushed = [UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad;
		
		statusToolbar = [[StatusToolbar alloc] init];
		[account addObserver:statusToolbar forKeyPath:@"downloadStatus" options:NSKeyValueObservingOptionNew context:nil];
		[account addObserver:statusToolbar forKeyPath:@"downloadProgress" options:NSKeyValueObservingOptionNew context:nil];
		
		ReportDownloadCoordinator *coordinator = [ReportDownloadCoordinator sharedReportDownloadCoordinator];
		[coordinator addObserver:self forKeyPath:@"isBusy" options:NSKeyValueObservingOptionNew context:nil];
	}
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self.tableView name:NSManagedObjectContextObjectsDidChangeNotification object:account.managedObjectContext];
	ReportDownloadCoordinator *coordinator = [ReportDownloadCoordinator sharedReportDownloadCoordinator];
	[coordinator removeObserver:self forKeyPath:@"isBusy" context:nil];
	[account removeObserver:statusToolbar forKeyPath:@"downloadStatus" context:nil];
	[account removeObserver:statusToolbar forKeyPath:@"downloadProgress" context:nil];
	[statusToolbar hide];
	[statusToolbar removeFromSuperview];
}

- (void)loadView {
	[super loadView];
	
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
	
	sortedApps = [allApps filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(Product *product, NSDictionary *bindings) {
		return !product.hidden.boolValue && !(product.parentSKU.length > 1); // In-App Purchases don't have promo codes, so don't include them.
	}]];
	
	[self.tableView registerClass:[BadgedCell class] forCellReuseIdentifier:@"Cell"];
	[self.tableView reloadData];
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(downloadReviews)];
	
	[self.navigationController.view addSubview:statusToolbar];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self.tableView reloadData];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self.tableView name:NSManagedObjectContextObjectsDidChangeNotification object:account.managedObjectContext];
	[[NSNotificationCenter defaultCenter] addObserver:self.tableView selector:@selector(reloadData) name:NSManagedObjectContextObjectsDidChangeNotification object:account.managedObjectContext];
	
	ReportDownloadCoordinator *coordinator = [ReportDownloadCoordinator sharedReportDownloadCoordinator];
	self.navigationItem.rightBarButtonItem.enabled = !coordinator.isBusy;
	if (coordinator.isBusy) {
		statusToolbar.status = account.downloadStatus;
		statusToolbar.progress = account.downloadProgress;
		[statusToolbar show];
	}
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver:self.tableView];
}

- (void)downloadReviews {
	ReportDownloadCoordinator *coordinator = [ReportDownloadCoordinator sharedReportDownloadCoordinator];
	if (coordinator.isBusy) { return; }
	self.navigationItem.rightBarButtonItem.enabled = NO;
	statusToolbar.status = account.downloadStatus;
	statusToolbar.progress = account.downloadProgress;
	[statusToolbar show];
	[coordinator downloadReviewsForAccount:account products:sortedApps];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
	if ([keyPath isEqualToString:@"isBusy"]) {
		dispatch_async(dispatch_get_main_queue(), ^{
			ReportDownloadCoordinator *coordinator = [ReportDownloadCoordinator sharedReportDownloadCoordinator];
			if (!coordinator.isBusy) {
                [self->statusToolbar hide];
				[self.tableView reloadData];
				self.navigationItem.rightBarButtonItem.enabled = YES;
			}
		});
	}
}

- (NSInteger)unreadCount:(Product *)product {
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	fetchRequest.entity = [NSEntityDescription entityForName:@"Review" inManagedObjectContext:product.managedObjectContext];
	fetchRequest.predicate = [NSPredicate predicateWithFormat:@"(product == %@) AND (unread == %@)", product, @YES];
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
	ReviewListViewController *reviewListVC = [[ReviewListViewController alloc] initWithProduct:product];
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
		[self.navigationController pushViewController:reviewListVC animated:YES];
	} else {
		UINavigationController *reviewListNC = [[UINavigationController alloc] initWithRootViewController:reviewListVC];
		reviewListNC.modalPresentationStyle = UIModalPresentationFormSheet;
		reviewListNC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
		[self presentViewController:reviewListNC animated:YES completion:nil];
	}
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        return UIInterfaceOrientationMaskAll;
    }
    return UIInterfaceOrientationMaskPortrait;
}

@end
