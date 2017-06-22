//
//  StatusToolbar.h
//  AppSales
//
//  Created by Nicolas Gomollon on 6/21/17.
//
//

#import <UIKit/UIKit.h>

@interface StatusToolbar : UIToolbar {
	UIActivityIndicatorView *activityIndicator;
	UILabel *statusLabel;
	UIProgressView *progressBar;
	UIBarButtonItem *stopButtonItem;
	BOOL visible;
}

@property (nonatomic, strong) NSString *status;
@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, readonly) BOOL isVisible;

- (void)show;
- (void)hide;

@end
