//
//  Review.m
//  AppSalesMobile
//
//  Created by Ole Zorn on 11.09.09.
//  Copyright 2009 omz:software. All rights reserved.
//

#import "Review.h"


@implementation Review

@synthesize user, title, stars, reviewDate, downloadDate, text, version, countryCode;

- (id)initWithCoder:(NSCoder *)coder
{
	[super init];
	self.user = [coder decodeObjectForKey:@"user"];
	self.title = [coder decodeObjectForKey:@"title"];
	self.stars = [coder decodeIntForKey:@"stars"];
	self.reviewDate = [coder decodeObjectForKey:@"reviewDate"];
	self.downloadDate = [coder decodeObjectForKey:@"downloadDate"];
	self.text = [coder decodeObjectForKey:@"text"];
	self.version = [coder decodeObjectForKey:@"version"];
	self.countryCode = [coder decodeObjectForKey:@"countryCode"];
	return self;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ (%@ %@): %@ (%i stars)", self.user, self.countryCode, self.reviewDate, self.title, self.stars];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:self.user forKey:@"user"];
	[coder encodeObject:self.title forKey:@"title"];
	[coder encodeInt:self.stars forKey:@"stars"];
	[coder encodeObject:self.reviewDate forKey:@"reviewDate"];
	[coder encodeObject:self.downloadDate forKey:@"downloadDate"];
	[coder encodeObject:self.text forKey:@"text"];
	[coder encodeObject:self.version forKey:@"version"];
	[coder encodeObject:self.countryCode forKey:@"countryCode"];
}

- (void)dealloc
{
	[user release];
	[title release];
	[reviewDate release];
	[downloadDate release];
	[text release];
	[version release];
	[countryCode release];
	[super dealloc];
}

@end
