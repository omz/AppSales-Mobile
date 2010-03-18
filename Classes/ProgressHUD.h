//
//  ProgressHUD.h
//  AppSales
//
//  Created by Ole Zorn on 05.12.08.
//  Copyright 2008 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ProgressHUD : UIView {

	UILabel *label;
	UIImageView *hudFrameView;
}

+ (ProgressHUD *)sharedHUD;
- (void)setText:(NSString *)newText;
- (void)show;
- (void)hide;

@end
