//
//  ReviewFilter.h
//  AppSales
//
//  Created by Nicolas Gomollon on 6/20/17.
//
//

#import <Foundation/Foundation.h>

@class ReviewFilterComparator, ReviewFilterOption;

@interface ReviewFilter : NSObject

@property (nonatomic, assign, getter=isEnabled) BOOL enabled;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *predicate;
@property (nonatomic, strong) NSArray<ReviewFilterComparator *> *comparators;
@property (nonatomic, assign) NSInteger cIndex;
@property (nonatomic, strong) NSArray<ReviewFilterOption *> *options;
@property (nonatomic, assign) NSInteger index;

+ (instancetype)title:(NSString *)_title predicate:(NSString *)_predicate options:(NSArray<ReviewFilterOption *> *)_options;
- (instancetype)initWithTitle:(NSString *)_title predicate:(NSString *)_predicate options:(NSArray<ReviewFilterOption *> *)_options;

- (ReviewFilterComparator *)selectedComparator;
- (ReviewFilterOption *)selectedOption;
- (NSString *)value;
- (NSObject *)object;

@end
