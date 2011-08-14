//
//  PromoCodeOperation.h
//  AppSales
//
//  Created by Ole Zorn on 14.08.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MultiOperation.h"

#define ASPromoCodeDownloadFailedNotification		@"ASPromoCodeDownloadFailedNotification"
#define kASPromoCodeDownloadFailedErrorDescription	@"errorDescription"

@class Product;

@interface PromoCodeOperation : MultiOperation {
	
}

- (id)initWithProduct:(Product *)aProduct;
- (id)initWithProduct:(Product *)aProduct numberOfCodes:(NSInteger)numberOfCodes;

@end
