//
//  DashboardViewController.m
//  AppSales
//
//  Created by Ole Zorn on 30.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "DashboardViewController.h"
#import "DashboardAppCell.h"
#import "UIColor+Extensions.h"
#import "ASAccount.h"
#import "Product.h"

@implementation DashboardViewController

@synthesize account, products, visibleProducts, selectedProducts;
@synthesize productsTableView, topView, shadowView, statusToolbar, stopButtonItem, activityIndicator, statusLabel, progressBar;
@synthesize activeSheet;

- (instancetype)initWithAccount:(ASAccount *)anAccount {
	self = [super init];
	if (self) {
		self.account = anAccount;
		self.selectedProducts = nil;
		self.hidesBottomBarWhenPushed = [UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextDidChange:) name:NSManagedObjectContextObjectsDidChangeNotification object:[account managedObjectContext]];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowPasscodeLock:) name:ASWillShowPasscodeLockNotification object:nil];
	}
	return self;
}

- (void)willShowPasscodeLock:(NSNotification *)notification {
	if (self.activeSheet.visible) {
		[self.activeSheet dismissWithClickedButtonIndex:self.activeSheet.cancelButtonIndex animated:NO];
	}
}

- (void)contextDidChange:(NSNotification *)notification {
	NSSet *relevantEntityNames = [self entityNamesTriggeringReload];
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

- (NSSet *)entityNamesTriggeringReload {
	return [NSSet setWithObjects:@"Product", nil];
}

- (void)loadView {
	[super loadView];
	self.edgesForExtendedLayout = UIRectEdgeNone;
	
	BOOL iPad = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad);
	
	statusVisible = [self shouldShowStatusBar];
	self.topView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"TopBackground.png"]];
	topView.userInteractionEnabled = YES;
	topView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	topView.frame = CGRectMake(0, 0, self.view.bounds.size.width, iPad ? 450.0 : self.view.bounds.size.height * 0.5f);
	[self.view addSubview:topView];
	
	UIImageView *graphShadowView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ShadowBottom.png"]];
	graphShadowView.frame = CGRectMake(0, CGRectGetMaxY(topView.bounds), topView.bounds.size.width, 20);
	graphShadowView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
	[topView addSubview:graphShadowView];
	
	self.productsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(topView.frame), self.view.bounds.size.width, self.view.bounds.size.height - topView.bounds.size.height) style:UITableViewStylePlain];
	productsTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	productsTableView.dataSource = self;
	productsTableView.delegate = self;
	productsTableView.backgroundColor = [UIColor clearColor];
	
	productsTableView.tableHeaderView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ShadowTop.png"]];
	productsTableView.tableFooterView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ShadowBottom.png"]];
	UIEdgeInsets productsTableContentInset = statusVisible ? UIEdgeInsetsMake(-20, 0, 24, 0) : UIEdgeInsetsMake(-20, 0, -20, 0);
	UIEdgeInsets productsTableScrollIndicatorInset = statusVisible ? UIEdgeInsetsMake(0, 0, 44, 0) : UIEdgeInsetsMake(0, 0, 0, 0);
	productsTableView.contentInset = productsTableContentInset;
	productsTableView.scrollIndicatorInsets = productsTableScrollIndicatorInset;
	productsTableView.allowsMultipleSelection = YES;
	
	self.view.backgroundColor = [UIColor colorWithRed:111.0f/255.0f green:113.0f/255.0f blue:121.0f/255.0f alpha:1.0f];
	[self.view addSubview:self.productsTableView];
	
	self.shadowView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ShadowBottom.png"]];
	shadowView.frame = graphShadowView.frame;
	shadowView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	shadowView.alpha = 0.0;
	
	[self.view addSubview:shadowView];
	
	self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	if (statusVisible) [activityIndicator startAnimating];
	UIBarButtonItem *activityIndicatorItem = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
	
	self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 2, 200, 20)];
	statusLabel.font = [UIFont boldSystemFontOfSize:14.0];
	statusLabel.backgroundColor = [UIColor clearColor];
	statusLabel.textColor = [UIColor whiteColor];
	statusLabel.shadowColor = [UIColor blackColor];
	statusLabel.shadowOffset = CGSizeMake(0, -1);
	statusLabel.textAlignment = NSTextAlignmentCenter;
	
	self.progressBar = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 25, 200, 10)];
	
	UIView *statusView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 40)];
	[statusView addSubview:statusLabel];
	[statusView addSubview:progressBar];
	
	UIBarButtonItem *statusItem = [[UIBarButtonItem alloc] initWithCustomView:statusView];
	UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	self.stopButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(stopDownload:)];
	
	CGRect statusToolbarFrame = CGRectMake(0, self.view.bounds.size.height - (statusVisible ? 44 : 0), self.view.bounds.size.width, 44);
	self.statusToolbar = [[UIToolbar alloc] initWithFrame:statusToolbarFrame];
	statusToolbar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
	statusToolbar.translucent = YES;
	statusToolbar.barStyle = UIBarStyleBlackTranslucent;
	statusToolbar.items = @[activityIndicatorItem, flexSpace, statusItem, flexSpace, stopButtonItem];
	
	[self.view addSubview:statusToolbar];
}

- (void)stopDownload:(id)sender {
	// Subclasses should override this.
}

- (void)viewDidLoad {
	[super viewDidLoad];
	[self reloadData];
}

- (void)viewDidUnload {
	[super viewDidUnload];
	self.productsTableView = nil;
	self.shadowView = nil;
	self.statusToolbar = nil;
	self.activityIndicator = nil;
	self.statusLabel = nil;
	self.progressBar = nil;
}

- (BOOL)shouldShowStatusBar {
	return NO;
}

- (void)showOrHideStatusBar {
	BOOL statusBarShouldBeVisible = [self shouldShowStatusBar];
	if (statusBarShouldBeVisible == statusVisible) return;
	statusVisible = statusBarShouldBeVisible;
	
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.4];
	if (statusVisible) {
		self.stopButtonItem.enabled = YES;
		[self.activityIndicator startAnimating];
	} else {
		[self.activityIndicator stopAnimating];
	}
	UIEdgeInsets productsTableContentInset = statusVisible ? UIEdgeInsetsMake(-20, 0, 24, 0) : UIEdgeInsetsMake(-20, 0, -20, 0);
	UIEdgeInsets productsTableScrollIndicatorInset = statusVisible ? UIEdgeInsetsMake(0, 0, 44, 0) : UIEdgeInsetsMake(0, 0, 0, 0);
	CGRect statusToolbarFrame = CGRectMake(0, self.view.bounds.size.height - (statusVisible ? 44 : 0), self.view.bounds.size.width, 44);
	if (statusVisible) {
		self.statusToolbar.frame = statusToolbarFrame;
		self.productsTableView.contentInset = productsTableContentInset;
		self.productsTableView.scrollIndicatorInsets = productsTableScrollIndicatorInset;
	} else {
		double delayInSeconds = 1.5;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
			[UIView beginAnimations:nil context:nil];
			[UIView setAnimationDuration:0.4];
			self.statusToolbar.frame = statusToolbarFrame;
			self.productsTableView.contentInset = productsTableContentInset;
			self.productsTableView.scrollIndicatorInsets = productsTableScrollIndicatorInset;
			[UIView commitAnimations];
		});
	}
	[UIView commitAnimations];
}

- (void)reloadData {
	NSString *productSortByValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"ProductSortby"];
	
	NSArray *allProducts;
	if ([productSortByValue isEqualToString:@"color"]) {
		// Sort products by color.
		allProducts = [[self.account.products allObjects] sortedArrayUsingComparator:^NSComparisonResult(Product *product1, Product *product2) {
			if (product1.color.luminance < product2.color.luminance) {
				return NSOrderedAscending;
			} else if (product1.color.luminance > product2.color.luminance) {
				return NSOrderedDescending;
			}
			return NSOrderedSame;
		}];
	} else {
		// Sort products by ID (this will put the most recently released apps on top).
		allProducts = [[self.account.products allObjects] sortedArrayUsingComparator:^NSComparisonResult(Product *product1, Product *product2) {
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
	
	self.products = allProducts;
	self.visibleProducts = [allProducts filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(Product *product, NSDictionary *bindings) {
		return !product.hidden.boolValue;
	}]];
	
	[self reloadTableView];
}


- (void)reloadTableView {
	// Reload the table view, preserving the current selection.
	NSArray *selectedIndexPaths = [self.productsTableView indexPathsForSelectedRows];
	[self.productsTableView reloadData];
	if ([selectedIndexPaths count] > 0) {
		for (NSIndexPath *selectedIndexPath in selectedIndexPaths) {
			[self.productsTableView selectRowAtIndexPath:selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
		}
	} else {
		NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
		[self.productsTableView selectRowAtIndexPath:selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
  	}
}

- (void)changeColorAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [self.productsTableView cellForRowAtIndexPath:indexPath];
	Product *product = self.visibleProducts[indexPath.row - 1];
	
	CrayonColorPickerViewController *colorPicker = [[CrayonColorPickerViewController alloc] initWithSelectedColor:product.color];
	colorPicker.context = product;
	colorPicker.delegate = self;
	
	colorPicker.popoverPresentationController.sourceView = cell;
	colorPicker.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMaxX(cell.bounds), 0.0f, 62.0f, 44.0f);
	[self presentViewController:colorPicker animated:YES completion:nil];
}

- (void)colorPicker:(CrayonColorPickerViewController *)picker didPickColor:(UIColor *)color {
	Product *product = (Product *)picker.context;
	product.color = color;
	[product.managedObjectContext save:nil];
	[self reloadTableView];
	picker.context = nil;
	picker.delegate = nil;
}

#pragma mark - Tableview data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.visibleProducts count] + 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 44.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *cellIdentifier = @"DashboardApp";
	DashboardAppCell *cell = (DashboardAppCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (!cell) {
		cell = [[DashboardAppCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
	}
	
	Product *product = nil;
	if (indexPath.row != 0) {
		product = self.visibleProducts[indexPath.row - 1];
	}
	
	cell.product = product;
	
	cell.accessoryView = [self accessoryViewForRowAtIndexPath:indexPath];
	
	if ([self.selectedProducts containsObject:product]) {
		[tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
	}
	
	UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
	[cell addGestureRecognizer:longPressRecognizer];
	
	return cell;
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer {
	if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
		DashboardAppCell *cell = ((DashboardAppCell *)gestureRecognizer.view);
		NSUInteger i = [self.visibleProducts indexOfObject:cell.product];
		NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i + 1 inSection:0];
		[self.productsTableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
		
		if (cell.product) {
			if (self.selectedProducts) {
				if (![self.selectedProducts containsObject:cell.product]) {
					[self.selectedProducts addObject:cell.product];
				} else {
					[self.selectedProducts removeObject:cell.product];
					[self.productsTableView deselectRowAtIndexPath:indexPath animated:NO];
					if (self.selectedProducts.count == 0) {
						self.selectedProducts = nil;
						[self deselectAllRowsInTableView:self.productsTableView exceptForIndexPath:nil];
						NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
						[self.productsTableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
					}
				}
			} else {
				self.selectedProducts = [NSMutableArray arrayWithObject:cell.product];
				NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
				[self.productsTableView deselectRowAtIndexPath:indexPath animated:NO];
			}
		} else {
			self.selectedProducts = nil;
			[self deselectAllRowsInTableView:self.productsTableView exceptForIndexPath:nil];
			NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
			[self.productsTableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
		}
		
		[[NSNotificationCenter defaultCenter] postNotificationName:DashboardViewControllerSelectedProductsDidChangeNotification object:nil];
	}
}

- (UIView *)accessoryViewForRowAtIndexPath:(NSIndexPath *)indexPath {
	return nil;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return (indexPath.row > 0);
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.selectedProducts.count > 0) {
		for (Product *product in self.selectedProducts) {
			NSUInteger row = [self.visibleProducts indexOfObject:product] + 1;
			[tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
		}
	} else {
		[tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
	}
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
	if ((indexPath.row <= 0) || (indexPath.row > self.visibleProducts.count)) { return nil; }
	UITableViewRowAction *changeColorAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:NSLocalizedString(@"Edit", nil) handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
		[self changeColorAtIndexPath:indexPath];
	}];
	Product *product = self.visibleProducts[indexPath.row - 1];
	changeColorAction.backgroundColor = product.color;
	return @[changeColorAction];
}

#pragma mark - Table view delegate

- (void)deselectAllRowsInTableView:(UITableView *)tableView exceptForIndexPath:(NSIndexPath *)indexPath  {
	for (NSIndexPath *i in [tableView indexPathsForSelectedRows]) {
		if ([i isEqual:indexPath]) continue;
		[tableView deselectRowAtIndexPath:i animated:NO];
	}
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath  {
	[self deselectAllRowsInTableView:tableView exceptForIndexPath:indexPath];
	[tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
	if (indexPath.row != 0) {
		Product *p = self.visibleProducts[indexPath.row - 1];
		self.selectedProducts = [NSMutableArray arrayWithObject:p];
	} else {
		self.selectedProducts = nil;
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self deselectAllRowsInTableView:tableView exceptForIndexPath:indexPath];
	self.selectedProducts = (indexPath.row == 0) ? nil : [NSMutableArray arrayWithObject:self.visibleProducts[indexPath.row - 1]];
	[[NSNotificationCenter defaultCenter] postNotificationName:DashboardViewControllerSelectedProductsDidChangeNotification object:nil];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	self.shadowView.alpha = MAX(0.0, MIN(1.0, (scrollView.contentOffset.y - 20) / 20.0));
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
