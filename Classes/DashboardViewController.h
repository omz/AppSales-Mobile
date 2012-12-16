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

@property (nonatomic, strong) ASAccount *account;
@property (nonatomic, strong) NSArray *products;
@property (nonatomic, strong) NSArray *visibleProducts;
@property (nonatomic, strong) NSMutableArray *selectedProducts;
@property (nonatomic, strong) UITableView *productsTableView;
@property (nonatomic, strong) UIView *topView;
@property (nonatomic, strong) UIImageView *shadowView;
@property (nonatomic, strong) UIPopoverController *colorPopover;
@property (nonatomic, strong) UIToolbar *statusToolbar;
@property (nonatomic, strong) UIBarButtonItem *stopButtonItem;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIProgressView *progressBar;
@property (nonatomic, strong) UIActionSheet *activeSheet;

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
