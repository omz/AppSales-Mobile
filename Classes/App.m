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

@synthesize appID, appName, reviewsByUser, allAppNames;

- (id)initWithCoder:(NSCoder *)coder
{
	[super init];
	self.appID = [coder decodeObjectForKey:@"appID"];
	self.allAppNames = [coder decodeObjectForKey:@"allAppNames"];
	self.appName = [coder decodeObjectForKey:@"appName"];
	self.reviewsByUser = [coder decodeObjectForKey:@"reviewsByUser"];
	return self;
}

- (NSMutableArray *)allAppNames {
	if(!allAppNames){
		self.allAppNames = [[NSMutableArray alloc] initWithObjects:self.appName, nil];
	}
	return allAppNames;
}

- (void)setAppName:(NSString *)n {
	if(![n isEqualToString:appName]){
		[appName release];
		appName = [n retain];
	}
	for(NSString *name in self.allAppNames){
		if([name isEqualToString:n])
			return;
	}
	[self.allAppNames addObject:n];
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

- (int)newReviewsCount {
	int newReviewsCount = 0;
	for(Review *r in [self.reviewsByUser allValues]){
		if(r.newOrUpdatedReview)
			newReviewsCount++;
	}
	return newReviewsCount;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:self.appID forKey:@"appID"];
	[coder encodeObject:self.appName forKey:@"appName"];
	[coder encodeObject:self.reviewsByUser forKey:@"reviewsByUser"];
	[coder encodeObject:self.allAppNames forKey:@"allAppNames"];
}

- (void)dealloc
{
	[appID release];
	[appName release];
	[reviewsByUser release];
	[allAppNames release];
	[super dealloc];
}

@end
