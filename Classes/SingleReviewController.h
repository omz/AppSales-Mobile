//
//  SingleReviewController.h
//  AppSalesMobile
//
//  Created by Ole Zorn on 12.09.09.
//  Copyright 2009 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Review;

@interface SingleReviewController : UIViewController {
	UIWebView *webView;
	Review *review;
}

@property (nonatomic, retain) UIWebView *webView;
@property (nonatomic, retain) Review *review;

@end
