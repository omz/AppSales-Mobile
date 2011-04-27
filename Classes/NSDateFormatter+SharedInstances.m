//
//  NSDateFormatter+SharedInstances.m
//  AppSales
//
//  Created by Ole Zorn on 01.01.10.
//  Copyright 2010 omz:software. All rights reserved.
//

#import "NSDateFormatter+SharedInstances.h"
#import "AppSalesUtils.h"

@implementation NSDateFormatter (SharedInstances)

+ (NSDateFormatter *)sharedFullDateFormatter
{
    ASSERT_IS_MAIN_THREAD();
	static NSDateFormatter *sharedDateFormatter = nil;
	if (!sharedDateFormatter) {
		sharedDateFormatter = [NSDateFormatter new];
		[sharedDateFormatter setTimeStyle:NSDateFormatterNoStyle];
		[sharedDateFormatter setDateStyle:NSDateFormatterFullStyle];
	}
	return sharedDateFormatter;
}

+ (NSDateFormatter *)sharedLongDateFormatter
{
    ASSERT_IS_MAIN_THREAD();
	static NSDateFormatter *sharedDateFormatter = nil;
	if (!sharedDateFormatter) {
		sharedDateFormatter = [NSDateFormatter new];
		[sharedDateFormatter setTimeStyle:NSDateFormatterNoStyle];
		[sharedDateFormatter setDateStyle:NSDateFormatterLongStyle];
	}
	return sharedDateFormatter;
}

+ (NSDateFormatter *)sharedMediumDateFormatter
{
    ASSERT_IS_MAIN_THREAD();
	static NSDateFormatter *sharedDateFormatter = nil;
	if (!sharedDateFormatter) {
		sharedDateFormatter = [NSDateFormatter new];
        [sharedDateFormatter setTimeStyle:NSDateFormatterNoStyle];
        [sharedDateFormatter setDateStyle:NSDateFormatterMediumStyle];
	}
	return sharedDateFormatter;
}


+ (NSDateFormatter *)sharedShortDateFormatter
{
    ASSERT_IS_MAIN_THREAD();
	static NSDateFormatter *sharedDateFormatter = nil;
	if (!sharedDateFormatter) {
		sharedDateFormatter = [NSDateFormatter new];
		[sharedDateFormatter setTimeStyle:NSDateFormatterNoStyle];
		[sharedDateFormatter setDateStyle:NSDateFormatterShortStyle];
	}
	return sharedDateFormatter;
}

@end
