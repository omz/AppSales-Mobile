//
//  DashboardViewController.m
//  AppSales
//
//  Created by Ole Zorn on 30.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "DashboardViewController.h"
#import "DashboardAppCell.h"
#import "ColorButton.h"
#import "UIColor+Extensions.h"
#import "ASAccount.h"
#import "Product.h"

@implementation DashboardViewController

@synthesize account, products, visibleProducts, selectedProducts;
@synthesize productsTableView, topView, shadowView, colorPopover, statusToolbar, stopButtonItem, activityIndicator, statusLabel, progressBar;
@synthesize activeSheet;

- (id)initWithAccount:(ASAccount *)anAccount
{
	self = [super initWithNibName:nil bundle:nil];
	if (self) {
		self.account = anAccount;
		self.selectedProducts = nil;
		self.hidesBottomBarWhenPushed = [[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPad;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextDidChange:) name:NSManagedObjectContextObjectsDidChangeNotification object:[account managedObjectContext]];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowPasscodeLock:) name:ASWillShowPasscodeLockNotification object:nil];
	}
	return self;
}

- (void)willShowPasscodeLock:(NSNotification *)notification
{
	if (self.colorPopover.popoverVisible) {
		[self.colorPopover dismissPopoverAnimated:NO];
	}
	if (self.activeSheet.visible) {
		[self.activeSheet dismissWithClickedButtonIndex:self.activeSheet.cancelButtonIndex animated:NO];
	}
}

- (void)contextDidChange:(NSNotification *)notification
{
	NSSet *relevantEntityNames = [self entityNamesTriggeringReload];
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

- (NSSet *)entityNamesTriggeringReload
{
	return [NSSet setWithObjects:@"Product", nil];
}

- (void)loadView
{
	[super loadView];
	BOOL iPad = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad);
	
	statusVisible = [self shouldShowStatusBar];
	self.topView = [[[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"TopBackground.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10)]] autorelease];
	topView.userInteractionEnabled = YES;
	topView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	topView.frame = CGRectMake(0, 0, self.view.bounds.size.width, iPad ? 450.0 : (self.view.bounds.size.height - 44.0) * 0.5);
	[self.view addSubview:topView];
	
	self.productsTableView = [[[UITableView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(topView.frame), self.view.bounds.size.width, self.view.bounds.size.height - topView.bounds.size.height) style:UITableViewStylePlain] autorelease];
	productsTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	productsTableView.dataSource = self;
	productsTableView.delegate = self;
	productsTableView.backgroundColor = [UIColor clearColor];
	
	productsTableView.allowsMultipleSelection = YES;
	
	self.view.backgroundColor = [UIColor whiteColor];
	[self.view addSubview:self.productsTableView];
	
	self.activityIndicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite] autorelease];
	if (statusVisible) [activityIndicator startAnimating];
	UIBarButtonItem *activityIndicatorItem = [[[UIBarButtonItem alloc] initWithCustomView:activityIndicator] autorelease];
	
	self.statusLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, 2, 200, 20)] autorelease];
	statusLabel.font = [UIFont boldSystemFontOfSize:14.0];
	statusLabel.backgroundColor = [UIColor clearColor];
	statusLabel.textColor = [UIColor whiteColor];
	statusLabel.textAlignment = NSTextAlignmentCenter;
	
	self.progressBar = [[[UIProgressView alloc] initWithFrame:CGRectMake(0, 25, 200, 10)] autorelease];
	
	UIView *statusView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 40)] autorelease];
	[statusView addSubview:statusLabel];
	[statusView addSubview:progressBar];
	
	UIBarButtonItem *statusItem = [[[UIBarButtonItem alloc] initWithCustomView:statusView] autorelease];
	UIBarButtonItem *flexSpace = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
	self.stopButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(stopDownload:)] autorelease];
	self.stopButtonItem.tintColor = [UIColor whiteColor];
	
	CGRect statusToolbarFrame = CGRectMake(0, self.view.bounds.size.height - ((statusVisible) ? 44 : 0), self.view.bounds.size.width, 44);
	self.statusToolbar = [[[UIToolbar alloc] initWithFrame:statusToolbarFrame] autorelease];
	statusToolbar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
	statusToolbar.translucent = YES;
	statusToolbar.barStyle = UIBarStyleBlackTranslucent;
	statusToolbar.items = [NSArray arrayWithObjects:activityIndicatorItem, flexSpace, statusItem, flexSpace, stopButtonItem, nil];
	
	[self.view addSubview:statusToolbar];
}

- (void)stopDownload:(id)sender
{
	//subclasses should override this
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	[self reloadData];
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	self.productsTableView = nil;
	self.shadowView = nil;
	self.statusToolbar = nil;
	self.activityIndicator = nil;
	self.statusLabel = nil;
	self.progressBar = nil;
}

- (BOOL)shouldShowStatusBar
{
	return NO;
}

- (void)showOrHideStatusBar
{
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
	UIEdgeInsets productsTableContentInset = (statusVisible) ? UIEdgeInsetsMake(0, 0, 44, 0) : UIEdgeInsetsMake(0, 0, 0, 0);
	UIEdgeInsets productsTableScrollIndicatorInset = (statusVisible) ? UIEdgeInsetsMake(0, 0, 44, 0) : UIEdgeInsetsMake(0, 0, 0, 0);
	CGRect statusToolbarFrame = CGRectMake(0, self.view.bounds.size.height - ((statusVisible) ? 44 : 0), self.view.bounds.size.width, 44);
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

- (void)reloadData
{
	NSString* productSortByValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"ProductSortby"];
	NSArray *allProducts;
	if ([productSortByValue isEqualToString:@"color"]) {
		// Sort products by color
		allProducts = [[self.account.products allObjects] sortedArrayUsingComparator:^(id obj1, id obj2){
			Product* product1 = (Product*)obj1;
			Product* product2 = (Product*)obj2;
			if ([product1.color luminance] < [product2.color luminance]) {
				return (NSComparisonResult)NSOrderedAscending;
			} else if ([product1.color luminance]> [product2.color luminance]) {
				return (NSComparisonResult)NSOrderedDescending;
			}  
			return (NSComparisonResult)NSOrderedSame;
		}];
	} else {
		// Sort products by ID (this will put the most recently released apps on top):
		allProducts = [[self.account.products allObjects] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"productID" ascending:NO] autorelease]]];
	}
	self.products = allProducts;
	self.visibleProducts = [allProducts filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^ (id obj, NSDictionary *bindings) { return (BOOL)![[(Product *)obj hidden] boolValue]; }]];	
	[self reloadTableView];
}


- (void)reloadTableView
{
	//Reload the table view, preserving the current selection:
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

- (void)changeColor:(UIButton *)sender
{
	int row = sender.tag;
	Product *product = [self.visibleProducts objectAtIndex:row - 1];
	
	NSArray *palette = [UIColor crayonColorPalette];
	ColorPickerViewController *vc = [[[ColorPickerViewController alloc] initWithColors:palette] autorelease];
	vc.delegate = self;
	vc.context = product;
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
		vc.modalTransitionStyle = UIModalTransitionStylePartialCurl;
		[self presentViewController:vc animated:YES completion:nil];
	} else {
		vc.preferredContentSize = CGSizeMake(320, 210);
		self.colorPopover = [[[UIPopoverController alloc] initWithContentViewController:vc] autorelease];
		[self.colorPopover presentPopoverFromRect:sender.bounds inView:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
	}
}

- (void)colorPicker:(ColorPickerViewController *)picker didPickColor:(UIColor *)color atIndex:(int)colorIndex
{
	Product *product = (Product *)picker.context;
	product.color = color;
	[product.managedObjectContext save:NULL];
	[self reloadTableView];
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
		[picker dismissViewControllerAnimated:YES completion:nil];
	} else {
		[self.colorPopover dismissPopoverAnimated:YES];
	}
}

#pragma mark - Tableview data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [self.visibleProducts count] + 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 40.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString *cellIdentifier = @"DashboardApp";
	DashboardAppCell *cell = (DashboardAppCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (!cell) {
		cell = [[[DashboardAppCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
	}
	if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
		[cell setSeparatorInset:UIEdgeInsetsMake(0, 44, 0, 8)];
	}
	
	Product *product = nil;
	if (indexPath.row != 0) {
		product = [self.visibleProducts objectAtIndex:indexPath.row - 1];
	}
	
	cell.product = product;
	cell.colorButton.tag = indexPath.row;
	[cell.colorButton addTarget:self action:@selector(changeColor:) forControlEvents:UIControlEventTouchUpInside];
	
	cell.accessoryView = [self accessoryViewForRowAtIndexPath:indexPath];
	
	if ([self.selectedProducts containsObject:product]) {
		[tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
	}
	
	UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
	[cell addGestureRecognizer:longPressRecognizer];
	[longPressRecognizer release];
	
	return cell;
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
	if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
		DashboardAppCell * cell = ((DashboardAppCell*)gestureRecognizer.view);
		NSUInteger i = [self.visibleProducts indexOfObject:cell.product];
		NSIndexPath * indexPath = [NSIndexPath indexPathForRow:i + 1 inSection:0];
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
						NSIndexPath * indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
						[self.productsTableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
					}
				}
			} else {
				self.selectedProducts = [NSMutableArray arrayWithObject:cell.product];
				NSIndexPath * indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
				[self.productsTableView deselectRowAtIndexPath:indexPath animated:NO];
			}
		} else {
			self.selectedProducts = nil;
			[self deselectAllRowsInTableView:self.productsTableView exceptForIndexPath:nil];
			NSIndexPath * indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
			[self.productsTableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
		}
	}
}

- (UIView *)accessoryViewForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return nil;
}

#pragma mark - Table view delegate

- (void)deselectAllRowsInTableView:(UITableView*)tableView exceptForIndexPath:(NSIndexPath*)indexPath 
{
	for (NSIndexPath *i in [tableView indexPathsForSelectedRows]) {
		if ([i isEqual:indexPath]) continue;
		[tableView deselectRowAtIndexPath:i animated:NO];
	}
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	[self deselectAllRowsInTableView:tableView exceptForIndexPath:indexPath];
	[tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
	if (indexPath.row != 0) {
		Product *p = [self.visibleProducts objectAtIndex:indexPath.row - 1];
		self.selectedProducts = [NSMutableArray arrayWithObject:p];
	} else {
		self.selectedProducts = nil;
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[self deselectAllRowsInTableView:tableView exceptForIndexPath:indexPath];
	self.selectedProducts = (indexPath.row == 0) ? nil : [NSMutableArray arrayWithObject:[self.visibleProducts objectAtIndex:indexPath.row - 1]];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	self.shadowView.alpha = MAX(0.0, MIN(1.0, (scrollView.contentOffset.y - 20) / 20.0));
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[account release];
	[products release];
	[visibleProducts release];
	[selectedProducts release];
	[productsTableView release];
	[topView release];
	[shadowView release];
	[statusToolbar release];
	[stopButtonItem release];
	[activityIndicator release];
	[statusLabel release];
	[progressBar release];
	[colorPopover release];
	[activeSheet release];
	[super dealloc];
}

@end
