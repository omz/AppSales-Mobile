//
//  Product.h
//  AppSales
//
//  Created by Ole Zorn on 19.07.11.
//  Copyright (c) 2011 omz:software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#define kProductPlatformiPhone		@"iPhone"
#define kProductPlatformiPad		@"iPad"
#define kProductPlatformUniversal	@"Universal"
#define kProductPlatformMac			@"Mac"
#define kProductPlatformInApp		@"In-App"

@class ASAccount;

@interface Product : NSManagedObject {

    BOOL isDownloadingPromoCodes;
}

@property (nonatomic, assign) BOOL isDownloadingPromoCodes;

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *platform;
@property (nonatomic, retain) NSString *productID;
@property (nonatomic, retain) NSDictionary *reviewSummary;
@property (nonatomic, retain) UIColor *color;
@property (nonatomic, retain) ASAccount *account;
@property (nonatomic, retain) NSSet *reviews;
@property (nonatomic, retain) NSSet *transactions;
@property (nonatomic, retain) NSNumber *hidden;
@property (nonatomic, retain) NSString *customName;
@property (nonatomic, retain) NSString *SKU;
@property (nonatomic, retain) NSString *parentSKU;
@property (nonatomic, retain) NSString *currentVersion;
@property (nonatomic, retain) NSDate *lastModified;
@property (nonatomic, retain) NSSet *promoCodes;

- (NSString *)displayName;
- (NSString *)defaultDisplayName;

@end

