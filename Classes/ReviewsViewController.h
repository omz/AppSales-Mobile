//
//  ReviewsViewController.h
//  AppSales
//
//  Created by Nicolas Gomollon on 12/7/15.
//
//

#import <UIKit/UIKit.h>

@class ASAccount;

@interface ReviewsViewController : UITableViewController {
	ASAccount *account;
	NSArray *sortedApps;
}

- (instancetype)initWithAccount:(ASAccount *)_account;

@end
