//
//  ImportExportViewController.h
//  AppSalesMobile
//
//  Created by Ole Zorn on 17.03.10.
//  Copyright 2010 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HTTPServer;

@interface ImportExportViewController : UIViewController {

	HTTPServer *httpServer;
	NSString *info;
}

@property (retain) NSString *info;

- (void)showInfo;

@end
