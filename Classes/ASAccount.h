//
//  Account.h
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
@property (nonatomic, strong) NSString *password;	// this property encapsulates the keychain access,
													// it is not actually stored in the Core Data model
@property (nonatomic, strong) NSString *downloadStatus;
@property (nonatomic, assign) float downloadProgress;

// Core Data properties:
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *vendorID;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSNumber *sortIndex;
@property (nonatomic, strong) NSSet *dailyReports;
@property (nonatomic, strong) NSSet *weeklyReports;
@property (nonatomic, strong) NSSet *products;
@property (nonatomic, strong) NSSet *payments;
@property (nonatomic, strong) NSNumber *reportsBadge;
@property (nonatomic, strong) NSNumber *paymentsBadge;

- (void)deletePassword;
- (NSString *)displayName;

@end
