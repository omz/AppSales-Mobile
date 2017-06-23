//
//  ReviewFilterComparator.h
//  AppSales
//
//  Created by Nicolas Gomollon on 6/21/17.
//
//

#import <Foundation/Foundation.h>

@interface ReviewFilterComparator : NSObject

@property (nonatomic, strong) NSString *comparator;
@property (nonatomic, strong) NSString *title;

+ (instancetype)comparator:(NSString *)_comparator title:(NSString *)_title;
- (instancetype)initWithComparator:(NSString *)_comparator title:(NSString *)_title;

@end
