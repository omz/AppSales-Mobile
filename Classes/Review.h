//
//  Review.h
//  AppSales
//
//  Created by Nicolas Gomollon on 12/7/15.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Product, Version;

@interface Review : NSManagedObject

@property (nonatomic, strong) NSNumber *identifier;
@property (nonatomic, strong) NSDate *created;
@property (nonatomic, strong) Version *version;
@property (nonatomic, strong) Product *product;
@property (nonatomic, strong) NSString *countryCode;
@property (nonatomic, strong) NSString *nickname;
@property (nonatomic, strong) NSNumber *rating;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSNumber *unread;
@property (nonatomic, strong) NSString *sectionName;

@end
