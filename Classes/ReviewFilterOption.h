//
//  ReviewFilterOption.h
//  AppSales
//
//  Created by Nicolas Gomollon on 6/21/17.
//
//

#import <Foundation/Foundation.h>

@interface ReviewFilterOption : NSObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *subtitle;
@property (nonatomic, strong) NSString *predicate;
@property (nonatomic, strong) NSObject *object;

+ (instancetype)title:(NSString *)_title predicate:(NSString *)_predicate object:(NSObject *)_object;
- (instancetype)initWithTitle:(NSString *)_title predicate:(NSString *)_predicate object:(NSObject *)_object;

@end
