//
//  CountryDictionary.h
//  AppSales
//
//  Created by Ole Zorn on 25.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CountryDictionary : NSObject {

	NSDictionary *countryNamesByISOCode;
}

+ (id)sharedDictionary;
- (NSString *)nameForCountryCode:(NSString *)countryCode;

@end
