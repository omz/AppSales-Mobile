//
//  NSDateFormatter+SharedInstances.m
//  AppSales
//
//  Created by Ole Zorn on 01.01.10.
//  Copyright 2010 omz:software. All rights reserved.
//

#import "NSDateFormatter+SharedInstances.h"

@implementation NSDateFormatter (SharedInstances)

+ (NSDateFormatter *)sharedFullDateFormatter
{
    NSAssert([NSThread isMainThread], nil);
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
    NSAssert([NSThread isMainThread], nil);
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
    NSAssert([NSThread isMainThread], nil);
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
    NSAssert([NSThread isMainThread], nil);
	static NSDateFormatter *sharedDateFormatter = nil;
	if (!sharedDateFormatter) {
		sharedDateFormatter = [NSDateFormatter new];
		[sharedDateFormatter setTimeStyle:NSDateFormatterNoStyle];
		[sharedDateFormatter setDateStyle:NSDateFormatterShortStyle];
	}
	return sharedDateFormatter;
}

@end
