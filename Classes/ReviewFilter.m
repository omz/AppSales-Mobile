//
//  ReviewFilter.m
//  AppSales
//
//  Created by Nicolas Gomollon on 6/20/17.
//
//

#import "ReviewFilter.h"
#import "ReviewFilterOption.h"

@implementation ReviewFilter

@synthesize title, predicate, options, index;

+ (instancetype)title:(NSString *)_title predicate:(NSString *)_predicate options:(NSArray<ReviewFilterOption *> *)_options {
	return [[ReviewFilter alloc] initWithTitle:_title predicate:_predicate options:_options];
}

- (instancetype)initWithTitle:(NSString *)_title predicate:(NSString *)_predicate options:(NSArray<ReviewFilterOption *> *)_options {
	self = [super init];
	if (self) {
		// Initialization code
		title = _title;
		predicate = _predicate;
		options = _options;
		index = 0;
	}
	return self;
}

- (void)setIndex:(NSInteger)_index {
	if ((0 <= _index) && (_index < self.options.count)) {
		index = _index;
	} else {
		index = 0;
	}
}

- (ReviewFilterOption *)selectedOption {
	if ((0 <= self.index) && (self.index < self.options.count)) {
		return self.options[self.index];
	}
	return nil;
}

- (NSString *)value {
	return self.selectedOption.title;
}

- (NSString *)predicate {
	return self.selectedOption.predicate ?: predicate;
}

- (NSObject *)object {
	return self.selectedOption.object;
}

@end
