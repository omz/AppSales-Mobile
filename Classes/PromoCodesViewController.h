//
//  PromoCodesViewController.h
//  AppSales
//
//  Created by Ole Zorn on 13.08.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ASAccount;

@interface PromoCodesViewController : UITableViewController {
	ASAccount *account;
	NSArray *sortedApps;
}

@property (nonatomic, strong) NSArray *sortedApps;

- (instancetype)initWithAccount:(ASAccount *)anAccount;
- (void)reloadData;

@end
