//
//  Product.h
//  AppSales
//
//  Created by Ole Zorn on 19.07.11.
//  Copyright (c) 2011 omz:software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#define kProductPlatformiPhone						@"iPhone"
#define kProductPlatformiPad						@"iPad"
#define kProductPlatformUniversal					@"Universal"
#define kProductPlatformMac							@"Mac"
#define kProductPlatformInApp						@"In-App"
#define kProductPlatformMacInApp					@"Mac In-App"
#define kProductPlatformAppBundle					@"App Bundle"
#define kProductPlatformMacAppBundle				@"Mac App Bundle"
#define kProductPlatformRenewableSubscription		@"Renewable Sub"
#define kProductPlatformMacRenewableSubscription	@"Mac Renewable Sub"

@class ASAccount, Version, Review;

@interface Product : NSManagedObject {
	BOOL isDownloadingPromoCodes;
}

@property (nonatomic, assign) BOOL isDownloadingPromoCodes;

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *platform;
@property (nonatomic, strong) NSString *productID;
@property (nonatomic, strong) NSDictionary *reviewSummary;
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, strong) ASAccount *account;
@property (nonatomic, strong) NSSet<Version *> *versions;
@property (nonatomic, strong) NSSet<Review *> *reviews;
@property (nonatomic, strong) NSSet *transactions;
@property (nonatomic, strong) NSNumber *hidden;
@property (nonatomic, strong) NSString *customName;
@property (nonatomic, strong) NSString *SKU;
@property (nonatomic, strong) NSString *parentSKU;
@property (nonatomic, strong) NSDate *lastModified;
@property (nonatomic, strong) NSSet *promoCodes;

- (NSString *)displayName;
- (NSString *)defaultDisplayName;

@end
