//
//  App.m
//  AppSalesMobile
//
//  Created by Ole Zorn on 11.09.09.
//  Copyright 2009 omz:software. All rights reserved.
//

#import "App.h"
#import "Review.h"

@implementation App

@synthesize appID, appName, reviewsByUser, newReviewsCount;

- (id)initWithCoder:(NSCoder *)coder
{
	[super init];
	self.appID = [coder decodeObjectForKey:@"appID"];
	self.appName = [coder decodeObjectForKey:@"appName"];
	self.reviewsByUser = [coder decodeObjectForKey:@"reviewsByUser"];
	return self;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"App %@ (%@)", self.appName, self.appID];
}

- (float)averageStars
{
	if ([reviewsByUser count] == 0)
		return 0.0;
	
	float sum = 0.0;
	for (Review *r in [reviewsByUser allValues]) {
		sum += r.stars;
	}
	return sum / (float)[reviewsByUser count];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:self.appID forKey:@"appID"];
	[coder encodeObject:self.appName forKey:@"appName"];
	[coder encodeObject:self.reviewsByUser forKey:@"reviewsByUser"];
}

- (void)dealloc
{
	[appID release];
	[appName release];
	[reviewsByUser release];
	[super dealloc];
}

@end
