//
//  ReviewDetailViewController.h
//  AppSales
//
//  Created by Ole Zorn on 28.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@class ASAccount, Product, Review;

@interface ReviewDetailViewController : UIViewController <NSFetchedResultsControllerDelegate, MFMailComposeViewControllerDelegate> {
	UIToolbar *toolbar;
	UIBarButtonItem *prevItem;
	UIBarButtonItem *nextItem;

	NSManagedObjectContext *managedObjectContext;
  
	ASAccount *account;
	Product *product;
	NSUInteger rating;
  NSUInteger index;
	Review *review;
	UIWebView *webView;
}

@property (nonatomic, retain) UIToolbar *toolbar;
@property (nonatomic, retain) UIBarButtonItem *prevItem;
@property (nonatomic, retain) UIBarButtonItem *nextItem;

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, retain) UIWebView *webView;

- (id)initWithAccount:(ASAccount *)acc product:(Product *)reviewProduct rating:(NSUInteger)ratingFilter index:(NSUInteger)aIndex;
- (Review *)fetchedReviewAtIndex:(NSUInteger)index;
- (void)reloadData;

@end
