//
//  App.m
//  AppSalesMobile
//
//  Created by Ole Zorn on 11.09.09.
//  Copyright 2009 omz:software. All rights reserved.
//

#import "App.h"
#import "Review.h"

NSString* getDocPath() {
	static NSString *documentsDirectory = nil;
	if (!documentsDirectory) {
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		documentsDirectory = [[paths objectAtIndex:0] retain];
	}
	return documentsDirectory;
}

@implementation App

@synthesize appID, appName, reviewsByUser, averageStars;

- (id)initWithCoder:(NSCoder *)coder {
	self = [super init];
	if (self) {
		appID = [[coder decodeObjectForKey:@"appID"] retain];
		appName = [[coder decodeObjectForKey:@"appName"] retain];
		reviewsByUser = [[coder decodeObjectForKey:@"reviewsByUser"] retain];
		allAppNames = [[coder decodeObjectForKey:@"allAppNames"] retain];
		averageStars = [coder decodeFloatForKey:@"averageStars"];
	}
	return self;
}

- (void) resetNewReviewCount {
	for (Review *review in reviewsByUser.objectEnumerator) {
		review.newOrUpdatedReview = NO;
	}
}

- (NSArray*) allAppNames {
	if(! allAppNames){
		allAppNames = [[NSMutableArray alloc] initWithObjects:self.appName, nil];
	}
	return allAppNames;
}

- (void) updateApplicationName:(NSString*)n {
	if(![n isEqualToString:appName]){
		[appName release];
		appName = [n retain];
	}
	for(NSString *name in self.allAppNames){
		if([name isEqualToString:n])
			return;
	}
	[allAppNames addObject:n];
}

- (id) initWithID:(NSString*)identifier name:(NSString*)name {
	self = [super init];
	if (self) {
		appID = [identifier retain];
		appName = [name retain];
		reviewsByUser = [[NSMutableDictionary alloc] init];
	}
	return self;
}


- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:self.appID forKey:@"appID"];
	[coder encodeObject:self.appName forKey:@"appName"];
	[coder encodeObject:self.reviewsByUser forKey:@"reviewsByUser"];
	[coder encodeFloat:self.averageStars forKey:@"averageStars"];
	[coder encodeObject:self.allAppNames forKey:@"allAppNames"];
}

- (NSString *) description {
	return [NSString stringWithFormat:@"App %@ (%@)", self.appName, self.appID];
}

- (void) addOrReplaceReview:(Review*)review {
	[reviewsByUser setObject:review forKey:review.user];
	
	double sum = 0;
	for (Review *r in reviewsByUser.allValues) {
		sum += r.stars;
	}
	averageStars = sum / reviewsByUser.count;
}

- (NSUInteger) newReviewsCount {
	NSUInteger newReviewsCount = 0;
	for (Review *r in reviewsByUser.allValues) {
		if (r.newOrUpdatedReview) {
			newReviewsCount++;
		}
	}
	return newReviewsCount;
}

- (void) dealloc
{
	[appID release];
	[appName release];
	[reviewsByUser release];
	[allAppNames release];
	[super dealloc];
}

@end
