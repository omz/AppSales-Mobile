//
//  ASProgressHUD.m
//  AppSales
//
//  Created by Nicolas Gomollon on 2/19/18.
//
//

#import "ASProgressHUD.h"

@implementation ASProgressHUD

#pragma mark - Lifecycle

- (instancetype)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame])) {
		[self customInit];
	}
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	if ((self = [super initWithCoder:aDecoder])) {
		[self customInit];
	}
	return self;
}

- (void)customInit {
	self.bezelView.layer.cornerRadius = 9.0f;
	self.bezelView.blurEffectStyle = UIBlurEffectStyleDark;
	self.contentColor = [UIColor whiteColor];
}

@end
