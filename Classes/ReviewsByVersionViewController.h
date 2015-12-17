//
//  ReviewsByVersionViewController.h
//  AppSales
//
//  Created by Nicolas Gomollon on 12/7/15.
//
//

#import <UIKit/UIKit.h>
#import "ReviewDownloader.h"
#import "ReviewSummaryView.h"

@class Product;

@interface ReviewsByVersionViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, ReviewSummaryViewDataSource, ReviewSummaryViewDelegate, ReviewDownloaderDelegate> {
	Product *product;
	ReviewDownloader *downloader;
	
	UIView *topView;
	ReviewSummaryView *reviewSummaryView;
	UITableView *versionsTableView;
	
	NSArray *versions;
}

- (instancetype)initWithProduct:(Product *)_product;

@end
