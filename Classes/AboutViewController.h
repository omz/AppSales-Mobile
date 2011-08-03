//
//  AboutViewController.h
//  AppSales
//
//  Created by Ole Zorn on 02.08.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AboutViewController : UIViewController <UIWebViewDelegate> {
	
	UIWebView *webView;
}

@property (nonatomic, retain) UIWebView *webView;


@end
