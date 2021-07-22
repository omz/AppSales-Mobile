//
//  DashboardViewController.h
//  AppSales
//
//  Created by Ole Zorn on 30.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CrayonColorPickerViewController.h"

#define DashboardViewControllerSelectedProductsDidChangeNotification @"DashboardViewControllerSelectedProductsDidChangeNotification"

@class ASAccount, Product;

@interface DashboardViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, CrayonColorPickerViewControllerDelegate> {
	NSMutableArray *selectedProducts;
	ASAccount *account;
	UITableView *productsTableView;
	UIView *topView;
	CAGradientLayer *gradientLayer;
	UIView *topHighlight;
	UIView *bottomHighlight;
	UIImageView *shadowView;
	
	NSArray *products;
	NSArray *visibleProducts;
	
	BOOL statusVisible;
	UIToolbar *statusToolbar;
	UIBarButtonItem *stopButtonItem;
	UIActivityIndicatorView *activityIndicator;
	UILabel *statusLabel;
	UIProgressView *progressBar;
	
    UIAlertController *activeAlertSheet;
}

@property (nonatomic, strong) ASAccount *account;
@property (nonatomic, strong) NSArray *products;
@property (nonatomic, strong) NSArray *visibleProducts;
@property (nonatomic, strong) NSMutableArray *selectedProducts;
@property (nonatomic, strong) UITableView *productsTableView;
@property (nonatomic, strong) UIView *topView;
@property (nonatomic, strong) UIImageView *shadowView;
@property (nonatomic, strong) UIToolbar *statusToolbar;
@property (nonatomic, strong) UIBarButtonItem *stopButtonItem;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIProgressView *progressBar;
@property (nonatomic, strong) UIAlertController *activeAlertSheet;

- (instancetype)initWithAccount:(ASAccount *)anAccount;
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
