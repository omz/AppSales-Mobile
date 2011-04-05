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

@interface App ()
- (void) updateAverages;
@end

@implementation App

@synthesize appID, appName, reviewsByUser, averageStars, recentStars, recentVersion;

- (id)initWithCoder:(NSCoder *)coder {
	self = [super init];
	if (self) {
		appID = [[coder decodeObjectForKey:@"appID"] retain];
		appName = [[coder decodeObjectForKey:@"appName"] retain];
		reviewsByUser = [[coder decodeObjectForKey:@"reviewsByUser"] retain];
		allAppNames = [[coder decodeObjectForKey:@"allAppNames"] retain];
		averageStars = [coder decodeFloatForKey:@"averageStars"];
		recentVersion = [[coder decodeObjectForKey:@"recentVersion"] retain];
        recentStars = [coder decodeFloatForKey:@"recentStars"];
        if (![coder containsValueForKey:@"recentStars"] || ![coder containsValueForKey:@"recentVersion"]) {
            [self updateAverages];
        }
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
	[coder encodeFloat:self.recentStars forKey:@"recentStars"];
	[coder encodeObject:self.recentVersion forKey:@"recentVersion"];
	[coder encodeObject:self.allAppNames forKey:@"allAppNames"];
}

- (NSString *) description {
	return [NSString stringWithFormat:@"App %@ (%@)", self.appName, self.appID];
}

- (void) addOrReplaceReview:(Review*)review {
	[reviewsByUser setObject:review forKey:review.user];
    [self updateAverages];
}

- (void) updateAverages {
    double overallSum = 0;
    double mostRecentVersionSum = 0;
    int mostRecentVersionCount = 0;
	for (Review *r in reviewsByUser.allValues) {
		overallSum += r.stars;
        if (recentVersion == nil || [recentVersion compare:r.version] == NSOrderedAscending) {
            recentVersion = r.version;
            mostRecentVersionCount = 0;
            mostRecentVersionSum = 0;
        }
        if ([r.version isEqualToString:recentVersion]) {
            mostRecentVersionCount++;
            mostRecentVersionSum += r.stars;
        }
	}
	averageStars = overallSum / reviewsByUser.count;
	recentStars = mostRecentVersionSum / mostRecentVersionCount;
}

- (NSUInteger) recentReviewsCount {
	NSUInteger recentReviewsCount = 0;
	for (Review *r in reviewsByUser.allValues) {
		if ([r.version isEqualToString:recentVersion]) {
			recentReviewsCount++;
		}
	}
	return recentReviewsCount;
}

- (NSUInteger) newRecentReviewsCount {
	NSUInteger newReviewsCount = 0;
	for (Review *r in reviewsByUser.allValues) {
		if (r.newOrUpdatedReview && [r.version isEqualToString:recentVersion]) {
			newReviewsCount++;
		}
	}
	return newReviewsCount;
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
