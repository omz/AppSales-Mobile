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

@synthesize productID;

- (void)setProductID:(NSString *)newProductID
{
	if ([newProductID isEqualToString:productID]) return;
	if (!productID) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(iconDownloaded:) name:IconManagerDownloadedIconNotification object:nil];
	}
	
	[newProductID retain];
	[productID release];
	productID = newProductID;
	
	if (productID) {
		self.image = [[IconManager sharedManager] iconForAppID:productID];
	} else {
		self.image = nil;
	}
}

- (void)iconDownloaded:(NSNotification *)notification
{
	if ([[[notification userInfo] objectForKey:kIconManagerDownloadedIconNotificationAppID] isEqualToString:self.productID]) {
		self.image = [[IconManager sharedManager] iconForAppID:productID];
	}
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[productID release];
	[super dealloc];
}

@end
