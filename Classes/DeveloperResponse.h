//
//  DeveloperResponse.h
//  AppSales
//
//  Created by Nicolas Gomollon on 6/14/17.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Review;

@interface DeveloperResponse : NSManagedObject

@property (nonatomic, strong) NSNumber *identifier;
@property (nonatomic, strong) NSDate *lastModified;
@property (nonatomic, strong) NSString *pendingState;
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) Review *review;

@end
