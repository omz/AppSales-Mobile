//
//  ReviewDetailViewController.h
//  AppSales
//
//  Created by Ole Zorn on 28.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@class Review;

@interface ReviewDetailViewController : UIViewController <MFMailComposeViewControllerDelegate> {
	NSArray<Review *> *reviews;
	NSInteger index;
	UIWebView *webView;
	UIToolbar *toolbar;
	UIBarButtonItem *previousItem;
	UIBarButtonItem *nextItem;
	UIBarButtonItem *markItem;
	NSDateFormatter *dateFormatter;
}

- (instancetype)initWithReviews:(NSArray<Review *> *)_reviews selectedIndex:(NSInteger)_index;

@end
