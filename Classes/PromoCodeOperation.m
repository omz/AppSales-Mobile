//
//  PromoCodeOperation.m
//  AppSales
//
//  Created by Ole Zorn on 14.08.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "PromoCodeOperation.h"
#import "DownloadStepOperation.h"
#import "Product.h"
#import "ASAccount.h"
#import "PromoCode.h"

@implementation PromoCodeOperation

- (instancetype)initWithProduct:(Product *)aProduct {
	return [self initWithProduct:aProduct numberOfCodes:0];
}

- (instancetype)initWithProduct:(Product *)aProduct numberOfCodes:(NSInteger)numberOfCodes {
	self = [super init];
	if (self) {
		// Initialization code
		// TODO: This class should be re-implemented if enough people actually use it.
	}
	return self;
}

+ (void)errorNotification:(NSString *)errorDescription {
	dispatch_async(dispatch_get_main_queue(), ^{
		[[NSNotificationCenter defaultCenter] postNotificationName:ASPromoCodeDownloadFailedNotification object:nil userInfo:@{kASPromoCodeDownloadFailedErrorDescription: errorDescription}];
	});
}

@end
