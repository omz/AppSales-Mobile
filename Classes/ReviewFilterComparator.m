//
//  ReviewFilterComparator.m
//  AppSales
//
//  Created by Nicolas Gomollon on 6/21/17.
//
//

#import "ReviewFilterComparator.h"

@implementation ReviewFilterComparator

@synthesize comparator, title;

+ (instancetype)comparator:(NSString *)_comparator title:(NSString *)_title {
	return [[ReviewFilterComparator alloc] initWithComparator:_comparator title:_title];
}

- (instancetype)initWithComparator:(NSString *)_comparator title:(NSString *)_title {
	self = [super init];
	if (self) {
		// Initialization code
		comparator = _comparator;
		title = _title;
	}
	return self;
}

@end
