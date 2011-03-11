//
//  NSDateFormatter+SharedInstances.h
//  AppSales
//
//  Created by Ole Zorn on 01.01.10.
//  Copyright 2010 omz:software. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSDateFormatter (SharedInstances)

+ (NSDateFormatter *)sharedFullDateFormatter;
+ (NSDateFormatter *)sharedLongDateFormatter;
+ (NSDateFormatter *)sharedMediumDateFormatter;
+ (NSDateFormatter *)sharedShortDateFormatter;

@end
