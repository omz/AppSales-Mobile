//
//  DashboardViewController.h
//  AppSales
//
//  Created by Ole Zorn on 30.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ColorPickerViewController.h"

@class ASAccount, Product;

@interface DashboardViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, ColorPickerViewControllerDelegate> {

	NSMutableArray *selectedProducts;
	ASAccount *account;
	UITableView *productsTableView;
	UIView *topView;
	
	NSArray *products;
	NSArray *visibleProducts;
	
	UIImageView *shadowView;
	UIPopoverController *colorPopover;
	
	BOOL statusVisible;
	UIToolbar *statusToolbar;
	UIBarButtonItem *stopButtonItem;
	UIActivityIndicatorView *activityIndicator;
	UILabel *statusLabel;
	UIProgressView *progressBar;
	
	UIActionSheet *activeSheet;
}

@property (nonatomic, retain) ASAccount *account;
@property (nonatomic, retain) NSArray *products;
@property (nonatomic, retain) NSArray *visibleProducts;
@property (nonatomic, retain) NSMutableArray *selectedProducts;
@property (nonatomic, retain) UITableView *productsTableView;
@property (nonatomic, retain) UIView *topView;
@property (nonatomic, retain) UIImageView *shadowView;
@property (nonatomic, retain) UIPopoverController *colorPopover;
@property (nonatomic, retain) UIToolbar *statusToolbar;
@property (nonatomic, retain) UIBarButtonItem *stopButtonItem;
@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, retain) UILabel *statusLabel;
@property (nonatomic, retain) UIProgressView *progressBar;
@property (nonatomic, retain) UIActionSheet *activeSheet;

- (id)initWithAccount:(ASAccount *)anAccount;
- (void)willShowPasscodeLock:(NSNotification *)notification;
- (NSSet *)entityNamesTriggeringReload;
- (void)reloadData;
- (void)reloadTableView;
- (void)showOrHideStatusBar;
- (BOOL)shouldShowStatusBar;
- (void)stopDownload:(id)sender;
- (UIView *)accessoryViewForRowAtIndexPath:(NSIndexPath *)indexPath;

- (void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer;

@end
