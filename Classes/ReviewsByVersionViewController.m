//
//  ReviewsByVersionViewController.m
//  AppSales
//
//  Created by Nicolas Gomollon on 12/7/15.
//
//

#import "ReviewsByVersionViewController.h"
#import "ReviewListViewController.h"
#import "BadgedCell.h"
#import "Product.h"
#import "Version.h"

@implementation ReviewsByVersionViewController

- (instancetype)initWithProduct:(Product *)_product {
	product = _product;
	self = [super init];
	if (self) {
		// Initialization code
		self.title = product.displayName;
	}
	return self;
}

- (void)loadView {
	[super loadView];
	self.edgesForExtendedLayout = UIRectEdgeNone;
	
	self.view.backgroundColor = [UIColor colorWithRed:111.0f/255.0f green:113.0f/255.0f blue:121.0f/255.0f alpha:1.0f];
	
	versions = [@[@"All Versions"] arrayByAddingObjectsFromArray:[[NSArray arrayWithArray:product.versions.allObjects] sortedArrayUsingComparator:^NSComparisonResult(Version *version1, Version *version2) {
		return version1.identifier.integerValue < version2.identifier.integerValue;
	}]];
	
	topView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"TopBackground.png"]];
	topView.frame = CGRectMake(0.0f, 0.0f, self.view.bounds.size.width, 240.0f);
	topView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	topView.userInteractionEnabled = YES;
	[self.view addSubview:topView];
	
	reviewSummaryView = [[ReviewSummaryView alloc] initWithFrame:topView.frame];
	reviewSummaryView.dataSource = self;
	reviewSummaryView.delegate = self;
	reviewSummaryView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[topView addSubview:reviewSummaryView];
	
	versionsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0f, CGRectGetMaxY(topView.frame), self.view.bounds.size.width, self.view.bounds.size.height - CGRectGetHeight(topView.frame)) style:UITableViewStylePlain];
	versionsTableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	versionsTableView.backgroundColor = [UIColor clearColor];
	versionsTableView.dataSource = self;
	versionsTableView.delegate = self;
	versionsTableView.allowsMultipleSelection = YES;
	versionsTableView.tableFooterView = [UIView new];
	[self.view addSubview:versionsTableView];
	
	[versionsTableView registerClass:[BadgedCell class] forCellReuseIdentifier:@"Cell"];
	[versionsTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
	[reviewSummaryView reloadDataAnimated:NO];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	// Do any additional setup after loading the view.
	UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", nil) style:UIBarButtonItemStylePlain target:self action:nil];
	self.navigationItem.backBarButtonItem = backButton;
	
	if ([UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPhone) {
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed)];
	}
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(downloadReviews)];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self reloadData:animated];
}

- (void)doneButtonPressed {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)downloadReviews {
	if (downloader.isDownloading) { return; }
	self.navigationItem.rightBarButtonItem.enabled = NO;
	downloader = [[ReviewDownloader alloc] initWithProduct:product];
	downloader.delegate = self;
	[downloader start];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (void)reviewDownloaderDidFinish:(ReviewDownloader *)reviewDownloader {
	downloader = nil;
	[self reloadData:YES];
	self.navigationItem.rightBarButtonItem.enabled = YES;
}

- (void)reloadData:(BOOL)animated {
	versions = [@[@"All Versions"] arrayByAddingObjectsFromArray:[[NSArray arrayWithArray:product.versions.allObjects] sortedArrayUsingComparator:^NSComparisonResult(Version *version1, Version *version2) {
		return version1.identifier.integerValue < version2.identifier.integerValue;
	}]];
	
	NSArray *selectedRows = versionsTableView.indexPathsForSelectedRows;
	[versionsTableView reloadData];
	for (NSIndexPath *indexPath in selectedRows) {
		[versionsTableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
	}
	
	[reviewSummaryView reloadDataAnimated:animated];
}

#pragma mark - ReviewSummaryViewDataSource

- (NSInteger)unreadCount:(Version *)version {
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	fetchRequest.entity = [NSEntityDescription entityForName:@"Review" inManagedObjectContext:product.managedObjectContext];
	if (version == nil) {
		fetchRequest.predicate = [NSPredicate predicateWithFormat:@"product == %@ AND unread == TRUE", product];
	} else {
		fetchRequest.predicate = [NSPredicate predicateWithFormat:@"product == %@ AND version == %@ AND unread == TRUE", product, version];
	}
	return [product.managedObjectContext countForFetchRequest:fetchRequest error:nil];
}

- (NSUInteger)reviewSummaryView:(ReviewSummaryView *)view numberOfReviewsForRating:(NSInteger)rating {
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	fetchRequest.entity = [NSEntityDescription entityForName:@"Review" inManagedObjectContext:product.managedObjectContext];
	NSArray *selectedRows = versionsTableView.indexPathsForSelectedRows;
	if (selectedRows.count == 0) {
		fetchRequest.predicate = [NSPredicate predicateWithFormat:@"product == %@ AND rating == %@", product, @(rating)];
	} else {
		NSMutableString *pred = [NSMutableString stringWithString:@"product == %@ AND rating == %@ AND (version == nil"];
		NSMutableArray *args = [[NSMutableArray alloc] initWithObjects:product, @(rating), nil];
		for (NSIndexPath *selectedRow in selectedRows) {
			if (selectedRow.row == 0) {
				[args removeAllObjects];
				break;
			} else {
				[pred appendString:@" OR version == %@"];
				[args addObject:versions[selectedRow.row]];
			}
		}
		if (args.count == 0) {
			fetchRequest.predicate = [NSPredicate predicateWithFormat:@"product == %@ AND rating == %@", product, @(rating)];
		} else {
			[pred appendString:@")"];
			fetchRequest.predicate = [NSPredicate predicateWithFormat:pred argumentArray:args];
		}
	}
	return [product.managedObjectContext countForFetchRequest:fetchRequest error:nil];
}

- (NSUInteger)reviewSummaryView:(ReviewSummaryView *)view numberOfUnreadReviewsForRating:(NSInteger)rating {
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	fetchRequest.entity = [NSEntityDescription entityForName:@"Review" inManagedObjectContext:product.managedObjectContext];
	NSArray *selectedRows = versionsTableView.indexPathsForSelectedRows;
	if (selectedRows.count == 0) {
		fetchRequest.predicate = [NSPredicate predicateWithFormat:@"product == %@ AND rating == %@ AND unread == TRUE", product, @(rating)];
	} else {
		NSMutableString *pred = [NSMutableString stringWithString:@"product == %@ AND rating == %@ AND unread == TRUE AND (version == nil"];
		NSMutableArray *args = [[NSMutableArray alloc] initWithObjects:product, @(rating), nil];
		for (NSIndexPath *selectedRow in selectedRows) {
			if (selectedRow.row == 0) {
				[args removeAllObjects];
				break;
			} else {
				[pred appendString:@" OR version == %@"];
				[args addObject:versions[selectedRow.row]];
			}
		}
		if (args.count == 0) {
			fetchRequest.predicate = [NSPredicate predicateWithFormat:@"product == %@ AND rating == %@ AND unread == TRUE", product, @(rating)];
		} else {
			[pred appendString:@")"];
			fetchRequest.predicate = [NSPredicate predicateWithFormat:pred argumentArray:args];
		}
	}
	return [product.managedObjectContext countForFetchRequest:fetchRequest error:nil];
}

#pragma mark - ReviewSummaryViewDelegate

- (void)reviewSummaryView:(ReviewSummaryView *)view didSelectRating:(NSInteger)rating {
	NSMutableArray *selectedVersions = [[NSMutableArray alloc] init];
	for (NSIndexPath *selectedRow in versionsTableView.indexPathsForSelectedRows) {
		if (selectedRow.row == 0) {
			[selectedVersions removeAllObjects];
			break;
		} else {
			[selectedVersions addObject:versions[selectedRow.row]];
		}
	}
	
	ReviewListViewController *vc = [[ReviewListViewController alloc] initWithProduct:product versions:selectedVersions rating:rating];
	[self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return versions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	BadgedCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	
	// Configure the cell...
	id version = versions[indexPath.row];
	cell.accessoryType = UITableViewCellAccessoryNone;
	cell.textLabel.text = [version isKindOfClass:[NSString class]] ? version : ((Version *)version).number;
	cell.badgeCount = [self unreadCount:([version isKindOfClass:[Version class]] ? version : nil)];
	cell.tag = indexPath.row;
	
	for (UIGestureRecognizer *gestureRecognizer in cell.gestureRecognizers) {
		[cell removeGestureRecognizer:gestureRecognizer];
	}
	
	UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
	[cell addGestureRecognizer:longPressRecognizer];
	
	return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self deselectAllRowsInTableView:tableView exceptForIndexPath:indexPath];
	[reviewSummaryView reloadDataAnimated:YES];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self deselectAllRowsInTableView:tableView exceptForIndexPath:indexPath];
	[tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
	[reviewSummaryView reloadDataAnimated:YES];
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer {
	if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
		UITableViewCell *cell = (UITableViewCell *)gestureRecognizer.view;
		NSIndexPath *indexPath = [NSIndexPath indexPathForRow:cell.tag inSection:0];
		
		if (cell.tag > 0) {
			BOOL allIsSelected = NO;
			BOOL currIsSelected = NO;
			for (NSIndexPath *i in versionsTableView.indexPathsForSelectedRows) {
				if (i.row == 0) {
					allIsSelected = YES;
				} else if (i.row == cell.tag) {
					currIsSelected = YES;
				}
			}
			
			if (allIsSelected) {
				[self deselectAllRowsInTableView:versionsTableView exceptForIndexPath:nil];
				[versionsTableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
			} else if (!currIsSelected) {
				[versionsTableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
			} else {
				[versionsTableView deselectRowAtIndexPath:indexPath animated:NO];
				if (versionsTableView.indexPathsForSelectedRows.count == 0) {
					[versionsTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
				}
			}
		} else {
			[self deselectAllRowsInTableView:versionsTableView exceptForIndexPath:nil];
			[versionsTableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
		}
		
		[reviewSummaryView reloadDataAnimated:YES];
	}
}

- (void)deselectAllRowsInTableView:(UITableView *)tableView exceptForIndexPath:(NSIndexPath *)indexPath  {
	for (NSIndexPath *i in [tableView indexPathsForSelectedRows]) {
		if ([i isEqual:indexPath]) continue;
		[tableView deselectRowAtIndexPath:i animated:NO];
	}
}

#pragma mark - View Methods

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
