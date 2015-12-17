//
//  Version.h
//  AppSales
//
//  Created by Nicolas Gomollon on 12/7/15.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Product, Review;

@interface Version : NSManagedObject

@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSString *number;

@property (nonatomic, strong) Product *product;
@property (nonatomic, strong) NSSet<Review *> *reviews;

@end
