//
//  Review.h
//  AppSales
//
//  Created by Nicolas Gomollon on 12/7/15.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Product, Version, DeveloperResponse;

@interface Review : NSManagedObject

@property (nonatomic, strong) NSNumber *identifier;
@property (nonatomic, strong) NSDate *lastModified;
@property (nonatomic, strong) Version *version;
@property (nonatomic, strong) Product *product;
@property (nonatomic, strong) NSString *countryCode;
@property (nonatomic, strong) NSString *nickname;
@property (nonatomic, strong) NSNumber *rating;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSNumber *edited;
@property (nonatomic, strong) NSNumber *helpfulViews;
@property (nonatomic, strong) NSNumber *totalViews;
@property (nonatomic, strong) NSNumber *unread;
@property (nonatomic, strong) NSString *sectionName;
@property (nonatomic, strong) DeveloperResponse *developerResponse;

@end
