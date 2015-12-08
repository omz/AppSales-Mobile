//
//  AppIconView.m
//  AppSales
//
//  Created by Ole Zorn on 25.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "AppIconView.h"
#import "IconManager.h"

@implementation AppIconView

- (void)setProduct:(Product *)product {
	if ((productID != nil) && [product.productID isEqualToString:productID]) { return; }
	if (product.productID != nil) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(iconDownloaded:) name:IconManagerDownloadedIconNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(iconCleared:) name:IconManagerClearedIconNotification object:nil];
	} else {
		[[NSNotificationCenter defaultCenter] removeObserver:self];
	}
	
	productID = product.productID;
	
	if (product.parentSKU.length > 1) {
		self.image = [UIImage imageNamed:@"InAppPurchase"];
		[self enableMask];
	} else if (product.productID.length > 1) {
		self.image = [[IconManager sharedManager] iconForAppID:product.productID];
		[self enableMask];
	} else {
		self.image = nil;
		if (self.maskEnabled) {
			[self enableMask];
		} else {
			[self disableMask];
		}
	}
}

- (void)enableMask {
	self.contentMode = UIViewContentModeScaleAspectFit;
	self.clipsToBounds = YES;
	self.layer.cornerRadius = roundf(7.0f / (30.0f / self.frame.size.width));
	self.layer.borderColor = [[UIColor blackColor] colorWithAlphaComponent:0.1f].CGColor;
	self.layer.borderWidth = 0.5f;
}

- (void)disableMask {
	self.contentMode = UIViewContentModeCenter;
	self.clipsToBounds = NO;
	self.layer.cornerRadius = 0.0f;
	self.layer.borderColor = nil;
	self.layer.borderWidth = 0.0f;
}

- (void)setMaskEnabled:(BOOL)maskEnabled {
	if (productID == nil) {
		if (maskEnabled) {
			[self enableMask];
		} else {
			[self disableMask];
		}
	}
}

- (void)iconDownloaded:(NSNotification *)notification {
	if ([notification.userInfo[kIconManagerDownloadedIconNotificationAppID] isEqualToString:productID]) {
		self.image = [[IconManager sharedManager] iconForAppID:productID];
	}
}

- (void)iconCleared:(NSNotification *)notification {
	if ([notification.userInfo[kIconManagerClearedIconNotificationAppID] isEqualToString:productID]) {
		self.image = [UIImage imageNamed:@"GenericApp"];
	}
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
