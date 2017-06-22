//
//  ReviewsViewController.h
//  AppSales
//
//  Created by Nicolas Gomollon on 12/7/15.
//
//

#import <UIKit/UIKit.h>

@class ASAccount, StatusToolbar;

@interface ReviewsViewController : UITableViewController {
	ASAccount *account;
	NSArray *sortedApps;
	StatusToolbar *statusToolbar;
}

- (instancetype)initWithAccount:(ASAccount *)_account;

@end
