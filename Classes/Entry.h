/*
 Entry.h
 AppSalesMobile
 
 * Copyright (c) 2008, omz:software
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the <organization> nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY omz:software ''AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL <copyright holder> BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <UIKit/UIKit.h>

@class Country;

@interface Entry : NSObject {
    @private
	Country *country;
	NSString *productName;
	NSString *productIdentifier;
	NSString *currency;
	int transactionType;
	int units;
	float royalties;
	BOOL inAppPurchase;
}

@property (readonly, retain) Country *country;
@property (readonly, retain) NSString *productName;
@property (readonly, retain) NSString *productIdentifier;
@property (readonly, retain) NSString *currency;
@property (readonly) int transactionType;
@property (readonly) float royalties;
@property (readonly) int units;
@property (readonly) BOOL isPurchase; // as opposed to a free download
@property (readonly, getter=isInAppPurchase) BOOL inAppPurchase;

- (id)initWithProductIdentifier:(NSString*)identifier name:(NSString *)name transactionType:(int)type units:(int)u 
					  royalties:(float)r currency:(NSString *)currencyCode country:(Country *)aCountry inAppPurchase:(BOOL)inApp;
- (float)totalRevenueInBaseCurrency;

@end
