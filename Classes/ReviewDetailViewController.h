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

	Review *review;
	UIWebView *webView;
}

@property (nonatomic, retain) UIWebView *webView;

- (id)initWithReview:(Review *)review;

@end
