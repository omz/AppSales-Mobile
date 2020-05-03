//
//  ASAccount.h
//  AppSales
//
//  Created by Ole Zorn on 30.06.11.
//  Copyright (c) 2011 omz:software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface ASAccount : NSManagedObject {
	BOOL isDownloadingReports;
	NSString *downloadStatus;
	float downloadProgress;
}

@property (nonatomic, assign) BOOL isDownloadingReports;
@property (nonatomic, strong) NSString *downloadStatus;
@property (nonatomic, assign) float downloadProgress;

@property (nonatomic, strong) NSString *password;    // these properties encapsulate the keychain access,
@property (nonatomic, strong) NSString *accessToken; // they are not actually stored in the Core Data model

// Core Data properties:
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *providerID;
@property (nonatomic, strong) NSString *vendorID;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSNumber *sortIndex;
@property (nonatomic, strong) NSSet *dailyReports;
@property (nonatomic, strong) NSSet *weeklyReports;
@property (nonatomic, strong) NSSet *products;
@property (nonatomic, strong) NSSet *payments;
@property (nonatomic, strong) NSSet *paymentReports;
@property (nonatomic, strong) NSNumber *reportsBadge;
@property (nonatomic, strong) NSNumber *paymentsBadge;

- (void)deletePassword;
- (void)deleteAccessToken;
- (NSString *)displayName;

@end
