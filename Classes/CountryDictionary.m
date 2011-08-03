//
//  CountryDictionary.m
//  AppSales
//
//  Created by Ole Zorn on 25.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "CountryDictionary.h"

@implementation CountryDictionary

+ (id)sharedDictionary
{
	static id sharedDictionary = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedDictionary = [[self alloc] init];
	});
	return sharedDictionary;
}

- (id)init
{
	self = [super init];
	if (self) {
		countryNamesByISOCode = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"country_names" ofType:@"plist"]];
    }
	return self;
}

- (NSString *)nameForCountryCode:(NSString *)countryCode
{
	NSString *countryName = [countryNamesByISOCode objectForKey:[countryCode uppercaseString]];
	if (countryName) {
		return countryName;
	}
	return countryCode;
}

- (void)dealloc
{
	[countryNamesByISOCode release];
	[super dealloc];
}

@end
