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

NSString* getPrefetchedPath() {
	static NSString *prefetchedPath = nil;
	if (!prefetchedPath) {
		NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
		prefetchedPath = [[NSString stringWithFormat:@"%@/Prefetched/", bundlePath] retain];
	}
	return prefetchedPath;
}


@implementation App

@synthesize appID, appName, reviewsByUser, newReviewsCount;

- (void) updateAverageStars {
	if (reviewsByUser.count == 0) {
		averageStars = 0;
		return;
	}
	
	float sum = 0;
	for (Review *r in [reviewsByUser allValues]) {
		sum += r.stars;
	}
	averageStars = sum / reviewsByUser.count;
}

- (float) averageStars {
	return averageStars;
}

- (id)initWithCoder:(NSCoder *)coder {
	self = [super init];
	if (self) {
		appID = [[coder decodeObjectForKey:@"appID"] retain];
		appName = [[coder decodeObjectForKey:@"appName"] retain];
		reviewsByUser = [[coder decodeObjectForKey:@"reviewsByUser"] retain];
		averageStars = [coder decodeFloatForKey:@"averageStars"];
		if (reviewsByUser.count && averageStars == 0) {
			[self updateAverageStars]; // reading in older data
		}
	}
	return self;
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

- (NSString *) description {
	return [NSString stringWithFormat:@"App %@ (%@)", self.appName, self.appID];
}

- (void) addOrReplaceReview:(Review*)review {
	[reviewsByUser setObject:review forKey:review.user];
	[self updateAverageStars];
	newReviewsCount++;
}

- (void) encodeWithCoder:(NSCoder *)coder {
	// FIXME: synchronization is needed here since ReviewManager might be modifying
	// this instance while the app is shutting down and serializing out it's data.  
	// This synchronization could be removed, but then the serialization caller would need to 
	// synchronize on each instance it writes out (instead of just writing out a root object containing all apps)
	// yes, this is kind of gross
	@synchronized (self) {
		[coder encodeObject:self.appID forKey:@"appID"];
		[coder encodeObject:self.appName forKey:@"appName"];
		[coder encodeObject:self.reviewsByUser forKey:@"reviewsByUser"];
		[coder encodeFloat:self.averageStars forKey:@"averageStars"];
	}
}

- (void) dealloc {
	[appID release];
	[appName release];
	[reviewsByUser release];
	[super dealloc];
}

@end
