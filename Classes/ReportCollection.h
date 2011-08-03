//
//  ReportCollection.h
//  AppSales
//
//  Created by Ole Zorn on 23.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ReportSummary.h"

@interface ReportCollection : NSObject <ReportSummary> {

	NSArray *reports;
	NSString *title;
}

@property (nonatomic, retain) NSString *title;

- (id)initWithReports:(NSArray *)reportsArray;

@end
