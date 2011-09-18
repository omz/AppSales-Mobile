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

@implementation MapView

@synthesize report, selectedProduct, selectedCountry;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		self.backgroundColor = [UIColor colorWithRed:0.698 green:0.804 blue:0.871 alpha:1.0];
		pinView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Pin.png"]]; 
		pinView.alpha = 0.0;
		[self addSubview:pinView];
    }
    return self;
}

- (NSDictionary *)polygonsByCountryCode
{
	if (!polygonsByCountryCode) {
		polygonsByCountryCode = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"countries_simple" ofType:@"plist"]];
	}
	return polygonsByCountryCode;
}

- (void)setReport:(Report *)newReport
{
	if (report == newReport) return;
	[newReport retain];
	[report release];
	report = newReport;
	[self setNeedsDisplay];
}

- (void)setSelectedProduct:(Product *)product
{
	if (product == selectedProduct) return;
	[product retain];
	[selectedProduct release];
	selectedProduct = product;
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
	if (!self.report) return;
	
	CGContextRef c = UIGraphicsGetCurrentContext();
	CGContextSaveGState(c);
	CGContextSetShadowWithColor(c, CGSizeMake(0, 1), 0.0, [[UIColor colorWithWhite:0.0 alpha:0.5] CGColor]);
	[[UIImage imageNamed:@"countries.png"] drawInRect:self.bounds];
	CGContextRestoreGState(c);
	
	float width = self.bounds.size.width;
	float height = self.bounds.size.height;
	float totalRevenue = [self.report totalRevenueInBaseCurrencyForProductWithID:self.selectedProduct.productID];
	NSDictionary *revenueByCountry = [self.report revenueInBaseCurrencyByCountryForProductWithID:self.selectedProduct.productID];
	if (totalRevenue > 0) {
		for (NSString *country in revenueByCountry) {
			float revenueForCountry = [[revenueByCountry objectForKey:country] floatValue];
			if (revenueForCountry <= 0.0) continue;
			float percentage = revenueForCountry / totalRevenue;
			[[UIColor colorWithRed:0.0 green:0.5 blue:0.0 alpha:MIN(percentage * 2.0 + 0.15, 1.0)] set];
			NSArray *polygons = [[self polygonsByCountryCode] objectForKey:[country uppercaseString]];
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

- (void)setSelectedCountry:(NSString *)country
{
	if ([country isEqualToString:selectedCountry]) return;
	[country retain];
	[selectedCountry release];
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

- (CGPoint)centerPointForCountry:(NSString *)country
{
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

- (NSArray *)polygonPathsForCountry:(NSString *)country
{
	CGFloat width = self.bounds.size.width;
	CGFloat height = self.bounds.size.height;
	NSMutableArray *paths = [NSMutableArray array];
	NSArray *polygons = [[self polygonsByCountryCode] objectForKey:[country uppercaseString]];
	for (NSArray *polygon in polygons) {
		int i = 0;
		UIBezierPath *currentPath = [[[UIBezierPath alloc] init] autorelease];
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

- (void)dealloc
{
	[report release];
	[selectedProduct release];
	[polygonsByCountryCode release];
	[pinView release];
	[super dealloc];
}


@end
