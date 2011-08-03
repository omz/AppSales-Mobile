//
//  WeeklyReport.h
//  AppSales
//
//  Created by Ole Zorn on 13.07.11.
//  Copyright (c) 2011 omz:software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Report.h"

@class Account;

@interface WeeklyReport : Report {
@private
}
@property (nonatomic, retain) NSDate * endDate;
@property (nonatomic, retain) Account *account;

@end
