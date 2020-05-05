//
//  MapView.m
//  AppSales
//
//  Created by Ole Zorn on 21.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "MapView.h"
#import "Report.h"
#import "Product.h"
#import "UIColor+Extensions.h"
#import "DarkModeCheck.h"

@implementation MapView

@synthesize report, selectedProduct, selectedCountry;

- (instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		if (@available(iOS 13.0, *)) {
			self.backgroundColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
				switch (traitCollection.userInterfaceStyle) {
					case UIUserInterfaceStyleDark:
						return [UIColor colorWithRed:55.0f/255.0f green:67.0f/255.0f blue:100.0f/255.0f alpha:1.0f];
					default:
						return [UIColor colorWithRed:184.0f/255.0f green:223.0f/255.0f blue:242.0f/255.0f alpha:1.0f];
				}
			}];
		} else {
			self.backgroundColor = [UIColor colorWithRed:0.698 green:0.804 blue:0.871 alpha:1.0];
		}
		pinView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Pin"]];
		pinView.alpha = 0.0;
		[self addSubview:pinView];
	}
	return self;
}

- (NSDictionary *)polygonsByCountryCode {
	if (!polygonsByCountryCode) {
		polygonsByCountryCode = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"countries_simple" ofType:@"plist"]];
	}
	return polygonsByCountryCode;
}

- (void)setReport:(Report *)newReport {
	if (report == newReport) return;
	report = newReport;
	[self setNeedsDisplay];
}

- (void)setSelectedProduct:(Product *)product {
	if (product == selectedProduct) return;
	selectedProduct = product;
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
	if (!self.report) return;
	
	CGContextRef c = UIGraphicsGetCurrentContext();
	CGContextSaveGState(c);
	CGContextSetShadowWithColor(c, CGSizeMake(0, 1), 2.0, [[UIColor colorWithWhite:0.0 alpha:0.25] CGColor]);
	[[DarkModeCheck checkForDarkModeImage:@"countries"] drawInRect:self.bounds];
	CGContextRestoreGState(c);
	
	float width = self.bounds.size.width;
	float height = self.bounds.size.height;
	float totalRevenue = [self.report totalRevenueInBaseCurrencyForProductWithID:self.selectedProduct.productID];
	NSDictionary *revenueByCountry = [self.report revenueInBaseCurrencyByCountryForProductWithID:self.selectedProduct.productID];
	if (totalRevenue > 0) {
		for (NSString *country in revenueByCountry) {
			float revenueForCountry = [revenueByCountry[country] floatValue];
			if (revenueForCountry <= 0.0) continue;
			float percentage = revenueForCountry / totalRevenue;
			[[UIColor colorWithRed:0.0 green:0.5 blue:0.0 alpha:MIN(percentage * 2.0 + 0.15, 1.0)] set];
			NSArray *polygons = self.polygonsByCountryCode[[country uppercaseString]];
			for (NSArray *polygon in polygons) {
				CGContextBeginPath(c);
				int i = 0;
				for (NSString *coordinates in polygon) {
					CGPoint coordinatesPoint = CGPointFromString(coordinates);
					CGPoint viewCoordinates = CGPointMake(((coordinatesPoint.x + 180) / 360.0) * width, height - ((coordinatesPoint.y + 90) / 180.0) * height);
					if (i == 0) {
						CGContextMoveToPoint(c, viewCoordinates.x, viewCoordinates.y);
					} else {
						CGContextAddLineToPoint(c, viewCoordinates.x, viewCoordinates.y);
					}
					i++;
				}
				CGContextFillPath(c);
			}
		}
	}
	[[UIColor colorWithWhite:0.8 alpha:1.0] set];
	CGContextFillRect(c, CGRectMake(0, height-1, width, 1));	
}

- (void)setSelectedCountry:(NSString *)country {
	if ([country isEqualToString:selectedCountry]) return;
	selectedCountry = country;
	
	if (selectedCountry) {
		CGPoint countryCenter = [self centerPointForCountry:country];
		CGPoint pinLocation = CGPointMake(countryCenter.x + 9, countryCenter.y - 15);
		if (pinView.alpha < 1.0 && !CGPointEqualToPoint(countryCenter, CGPointZero)) {
			pinView.center = pinLocation;
		}
		[UIView beginAnimations:nil context:nil];
		if (!CGPointEqualToPoint(countryCenter, CGPointZero)) {
			pinView.alpha = 1.0;
			pinView.center = pinLocation;
		} else {
			pinView.alpha = 0.0;
		}
		[UIView commitAnimations];
	} else {
		[UIView beginAnimations:nil context:nil];
		pinView.alpha = 0.0;
		[UIView commitAnimations];
	}
}

- (CGPoint)centerPointForCountry:(NSString *)country {
	NSArray *paths = [self polygonPathsForCountry:country];
	CGRect largestBoundingBox = CGRectZero;
	for (UIBezierPath *path in paths) {
		CGRect boundingBox = [path bounds];
		if ((CGRectGetWidth(boundingBox) * CGRectGetHeight(boundingBox)) > (CGRectGetWidth(largestBoundingBox) * CGRectGetHeight(largestBoundingBox))) {
			largestBoundingBox = boundingBox;
		}
	}
	return CGPointMake(CGRectGetMidX(largestBoundingBox), CGRectGetMidY(largestBoundingBox));
}

- (NSArray *)polygonPathsForCountry:(NSString *)country {
	CGFloat width = self.bounds.size.width;
	CGFloat height = self.bounds.size.height;
	NSMutableArray *paths = [NSMutableArray array];
	NSArray *polygons = self.polygonsByCountryCode[[country uppercaseString]];
	for (NSArray *polygon in polygons) {
		int i = 0;
		UIBezierPath *currentPath = [[UIBezierPath alloc] init];
		for (NSString *coordinates in polygon) {
			CGPoint coordinatesPoint = CGPointFromString(coordinates);
			CGPoint viewCoordinates = CGPointMake(((coordinatesPoint.x + 180) / 360.0) * width, height - ((coordinatesPoint.y + 90) / 180.0) * height);
			if (i == 0) {
				[currentPath moveToPoint:viewCoordinates];
			} else {
				[currentPath addLineToPoint:viewCoordinates];
			}
			i++;
		}
		[paths addObject:currentPath];
	}
	return paths;
}

@end
