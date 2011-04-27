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

@synthesize appID, appName, reviewsByUser, averageStars, recentStars, recentVersion;

- (void) updateAverages {
    double overallSum = 0;
    double mostRecentVersionSum = 0;
    int mostRecentVersionCount = 0;
	for (Review *r in reviewsByUser.allValues) {
		overallSum += r.stars;
        if (recentVersion == nil || [recentVersion compare:r.version] == NSOrderedAscending) {
            [recentVersion release];
            recentVersion = [r.version retain];
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

- (id)initWithCoder:(NSCoder *)coder {
	self = [super init];
	if (self) {
		appID = [[coder decodeObjectForKey:@"appID"] retain];
		appName = [[coder decodeObjectForKey:@"appName"] retain];
		reviewsByUser = [[coder decodeObjectForKey:@"reviewsByUser"] retain];
		allAppNames = [[coder decodeObjectForKey:@"allAppNames"] retain];
        lastTimeRegionDownloaded = [[coder decodeObjectForKey:@"lastTimeRegionDownloaded"] retain];
		averageStars = [coder decodeFloatForKey:@"averageStars"];
        if (lastTimeRegionDownloaded == nil) { // backwards compatibility with older serialized objects
            lastTimeRegionDownloaded = [NSMutableDictionary new];
        }
        if ([coder containsValueForKey:@"recentVersion"] && [coder containsValueForKey:@"recentStars"]) {
            recentVersion = [[coder decodeObjectForKey:@"recentVersion"] retain];
            recentStars = [coder decodeFloatForKey:@"recentStars"];
        } else {
            [self updateAverages]; // older serialized object
        }
	}
	return self;
}

- (NSDate*) lastTimeReviewsForStoreWasDownloaded:(NSString*)storeCountryCode {
    return [lastTimeRegionDownloaded objectForKey:storeCountryCode];
}

- (void) setLastTimeReviewsDownloaded:(NSString*)storeCountryCode time:(NSDate*)timeLastDownloaded {
    [lastTimeRegionDownloaded setValue:timeLastDownloaded forKey:storeCountryCode];
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
		reviewsByUser = [NSMutableDictionary new];
        lastTimeRegionDownloaded = [NSMutableDictionary new];
	}
	return self;
}


- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:appID forKey:@"appID"];
	[coder encodeObject:appName forKey:@"appName"];
	[coder encodeObject:allAppNames forKey:@"allAppNames"];
    [coder encodeObject:lastTimeRegionDownloaded forKey:@"lastTimeRegionDownloaded"];
	[coder encodeFloat:averageStars forKey:@"averageStars"];
	[coder encodeObject:reviewsByUser forKey:@"reviewsByUser"];
	[coder encodeObject:recentVersion forKey:@"recentVersion"];
	[coder encodeFloat:recentStars forKey:@"recentStars"];
}

- (NSString *) description {
	return [NSString stringWithFormat:NSLocalizedString(@"App %@ (%@)", nil), self.appName, self.appID];
}

- (void) addOrReplaceReview:(Review*)review {
	[reviewsByUser setObject:review forKey:review.user];
    [self updateAverages];
}

- (NSUInteger) totalReviewsCount {
	return reviewsByUser.count;
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
    [lastTimeRegionDownloaded release];
    [recentVersion release];
	[super dealloc];
}

@end
