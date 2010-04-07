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
	static NSDateFormatter *sharedDateFormatter = nil;
	if (!sharedDateFormatter) {
		sharedDateFormatter = [[NSDateFormatter alloc] init];
		[sharedDateFormatter setTimeStyle:NSDateFormatterNoStyle];
		[sharedDateFormatter setDateStyle:NSDateFormatterFullStyle];
	}
	return sharedDateFormatter;
}

+ (NSDateFormatter *)sharedLongDateFormatter
{
	static NSDateFormatter *sharedDateFormatter = nil;
	if (!sharedDateFormatter) {
		sharedDateFormatter = [[NSDateFormatter alloc] init];
		[sharedDateFormatter setTimeStyle:NSDateFormatterNoStyle];
		[sharedDateFormatter setDateStyle:NSDateFormatterLongStyle];
	}
	return sharedDateFormatter;
}

+ (NSDateFormatter *)sharedShortDateFormatter
{
	static NSDateFormatter *sharedDateFormatter = nil;
	if (!sharedDateFormatter) {
		sharedDateFormatter = [[NSDateFormatter alloc] init];
		[sharedDateFormatter setTimeStyle:NSDateFormatterNoStyle];
		[sharedDateFormatter setDateStyle:NSDateFormatterShortStyle];
	}
	return sharedDateFormatter;
}

@end
