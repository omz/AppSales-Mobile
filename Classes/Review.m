//
//  Review.m
//  AppSales
//
//  Created by Nicolas Gomollon on 12/7/15.
//
//

#import "Review.h"
#import "Product.h"
#import "Version.h"
#import "DeveloperResponse.h"

@implementation Review

@dynamic identifier;
@dynamic lastModified;
@dynamic version;
@dynamic product;
@dynamic countryCode;
@dynamic nickname;
@dynamic rating;
@dynamic title;
@dynamic text;
@dynamic edited;
@dynamic helpfulViews;
@dynamic totalViews;
@dynamic unread;
@dynamic sectionName;
@dynamic developerResponse;

- (NSString *)sectionName {
	[self willAccessValueForKey:@"sectionName"];
	NSString *sectionName = self.version.number;
	[self didAccessValueForKey:@"sectionName"];
	return sectionName;
}

@end
