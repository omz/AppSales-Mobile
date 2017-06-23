//
//  ReviewFilter.m
//  AppSales
//
//  Created by Nicolas Gomollon on 6/20/17.
//
//

#import "ReviewFilter.h"
#import "ReviewFilterOption.h"
#import "ReviewFilterComparator.h"

@implementation ReviewFilter

@synthesize enabled, title, predicate, comparators, cIndex, options, index;

+ (instancetype)title:(NSString *)_title predicate:(NSString *)_predicate options:(NSArray<ReviewFilterOption *> *)_options {
	return [[ReviewFilter alloc] initWithTitle:_title predicate:_predicate options:_options];
}

- (instancetype)initWithTitle:(NSString *)_title predicate:(NSString *)_predicate options:(NSArray<ReviewFilterOption *> *)_options {
	self = [super init];
	if (self) {
		// Initialization code
		enabled = NO;
		title = _title;
		predicate = _predicate;
		comparators = @[];
		cIndex = 0;
		options = _options;
		index = 0;
	}
	return self;
}

- (BOOL)isEnabled {
	return enabled;
}

- (void)setEnabled:(BOOL)_enabled {
	enabled = _enabled;
	if (!enabled) {
		cIndex = 0;
		index = 0;
	}
}

- (void)setCIndex:(NSInteger)_cIndex {
	if ((0 <= _cIndex) && (_cIndex < self.comparators.count)) {
		cIndex = _cIndex;
	} else {
		cIndex = 0;
	}
}

- (ReviewFilterComparator *)selectedComparator {
	if ((0 <= self.cIndex) && (self.cIndex < self.comparators.count)) {
		return self.comparators[self.cIndex];
	}
	return nil;
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
	if (self.selectedOption.predicate) {
		return self.selectedOption.predicate;
	} else if (self.selectedComparator) {
		if (self.object) {
			return [NSString stringWithFormat:predicate, self.selectedComparator.comparator, @"%@"];
		} else {
			return [NSString stringWithFormat:predicate, self.selectedComparator.comparator];
		}
	}
	return predicate;
}

- (NSObject *)object {
	return self.selectedOption.object;
}

@end
