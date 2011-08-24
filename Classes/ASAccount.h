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
@property (nonatomic, retain) NSString *password;	// this property encapsulates the keychain access,
													// it is not actually stored in the Core Data model
@property (nonatomic, retain) NSString *downloadStatus;
@property (nonatomic, assign) float downloadProgress;

// Core Data properties:
@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) NSString *vendorID;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSNumber *sortIndex;
@property (nonatomic, retain) NSSet *dailyReports;
@property (nonatomic, retain) NSSet *weeklyReports;
@property (nonatomic, retain) NSSet *products;
@property (nonatomic, retain) NSSet *payments;
@property (nonatomic, retain) NSNumber *reportsBadge;
@property (nonatomic, retain) NSNumber *paymentsBadge;

- (void)deletePassword;
- (NSString *)displayName;

@end
