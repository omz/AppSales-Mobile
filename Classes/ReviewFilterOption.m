//
//  ReviewFilterOption.m
//  AppSales
//
//  Created by Nicolas Gomollon on 6/21/17.
//
//

#import "ReviewFilterOption.h"

@implementation ReviewFilterOption

@synthesize title, subtitle, predicate, object;

+ (instancetype)title:(NSString *)_title predicate:(NSString *)_predicate object:(NSObject *)_object {
	return [[ReviewFilterOption alloc] initWithTitle:_title predicate:_predicate object:_object];
}

- (instancetype)initWithTitle:(NSString *)_title predicate:(NSString *)_predicate object:(NSObject *)_object {
	self = [super init];
	if (self) {
		// Initialization code
		title = _title;
		predicate = _predicate;
		object = _object;
	}
	return self;
}

@end
