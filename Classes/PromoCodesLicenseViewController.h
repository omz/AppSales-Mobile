//
//  PromoCodesLicenseViewController.h
//  AppSales
//
//  Created by Ole Zorn on 14.08.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DownloadStepOperation;

@interface PromoCodesLicenseViewController : UIViewController <UIWebViewDelegate> {
	
	NSString *licenseAgreementHTML;
	DownloadStepOperation *downloadOperation;
	UIWebView *webView;
}

@property (nonatomic, retain) UIWebView *webView;

- (id)initWithLicenseAgreement:(NSString *)licenseAgreement operation:(DownloadStepOperation *)operation;

@end
