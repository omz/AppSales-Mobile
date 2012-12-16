//
//  MapView.h
//  AppSales
//
//  Created by Ole Zorn on 21.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Report, Product;

@interface MapView : UIView {

	NSDictionary *polygonsByCountryCode;
	Report *report;
	Product *selectedProduct;
	NSString *selectedCountry;
	UIImageView *pinView;
}

@property (nonatomic, strong) Report *report;
@property (nonatomic, strong) Product *selectedProduct;
@property (nonatomic, strong) NSString *selectedCountry;

- (CGPoint)centerPointForCountry:(NSString *)country;
- (NSArray *)polygonPathsForCountry:(NSString *)country;
- (NSDictionary *)polygonsByCountryCode;

@end
