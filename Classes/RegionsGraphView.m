//
//  RegionsGraphView.m
//  AppSalesMobile
//
//  Created by Ole Zorn on 16.02.09.
//  Copyright 2009 omz:software. All rights reserved.
//

#import "RegionsGraphView.h"
#import "Country.h"
#import "Day.h"
#import "CurrencyManager.h"

@implementation RegionsGraphView


- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
		regionsByCountryCode = [NSMutableDictionary new];
		//AU:
		[regionsByCountryCode setObject:@"AU" forKey:@"AU"];
		[regionsByCountryCode setObject:@"AU" forKey:@"NZ"];
		
		//GB:
		[regionsByCountryCode setObject:@"GB" forKey:@"GB"];
		
		//CA:
		[regionsByCountryCode setObject:@"CA" forKey:@"CA"];
		
		//US:
		[regionsByCountryCode setObject:@"US" forKey:@"US"];
		[regionsByCountryCode setObject:@"US" forKey:@"MX"];
		[regionsByCountryCode setObject:@"US" forKey:@"CO"];
		[regionsByCountryCode setObject:@"US" forKey:@"BR"];
		[regionsByCountryCode setObject:@"US" forKey:@"GT"];
		[regionsByCountryCode setObject:@"US" forKey:@"AR"];
		[regionsByCountryCode setObject:@"US" forKey:@"CL"];
		[regionsByCountryCode setObject:@"US" forKey:@"SV"];
		[regionsByCountryCode setObject:@"US" forKey:@"VE"];
		
		[regionsByCountryCode setObject:@"US" forKey:@"CR"]; //costa rica
		[regionsByCountryCode setObject:@"US" forKey:@"JM"]; //jamaica
		[regionsByCountryCode setObject:@"US" forKey:@"PA"]; //panama
		[regionsByCountryCode setObject:@"US" forKey:@"PE"]; //peru
		
		//EU:
		[regionsByCountryCode setObject:@"EU" forKey:@"CZ"];
		[regionsByCountryCode setObject:@"EU" forKey:@"DK"];
		[regionsByCountryCode setObject:@"EU" forKey:@"FI"];
		[regionsByCountryCode setObject:@"EU" forKey:@"FR"];
		[regionsByCountryCode setObject:@"EU" forKey:@"DE"];
		[regionsByCountryCode setObject:@"EU" forKey:@"GR"];
		[regionsByCountryCode setObject:@"EU" forKey:@"AT"];
		[regionsByCountryCode setObject:@"EU" forKey:@"BE"];
		[regionsByCountryCode setObject:@"EU" forKey:@"HU"];
		[regionsByCountryCode setObject:@"EU" forKey:@"IE"];
		[regionsByCountryCode setObject:@"EU" forKey:@"IT"];
		[regionsByCountryCode setObject:@"EU" forKey:@"LU"];
		[regionsByCountryCode setObject:@"EU" forKey:@"NL"];
		[regionsByCountryCode setObject:@"EU" forKey:@"NO"];
		[regionsByCountryCode setObject:@"EU" forKey:@"PL"];
		[regionsByCountryCode setObject:@"EU" forKey:@"PT"];
		[regionsByCountryCode setObject:@"EU" forKey:@"RO"];
		[regionsByCountryCode setObject:@"EU" forKey:@"SK"];
		[regionsByCountryCode setObject:@"EU" forKey:@"SI"];
		[regionsByCountryCode setObject:@"EU" forKey:@"ES"];
		[regionsByCountryCode setObject:@"EU" forKey:@"SE"];
		[regionsByCountryCode setObject:@"EU" forKey:@"CH"];
		
		//JP:
		[regionsByCountryCode setObject:@"JP" forKey:@"JP"];
		
		//WW:
		[regionsByCountryCode setObject:@"WW" forKey:@"HR"];
		[regionsByCountryCode setObject:@"WW" forKey:@"CN"];
		[regionsByCountryCode setObject:@"WW" forKey:@"HK"];
		[regionsByCountryCode setObject:@"WW" forKey:@"IN"];
		[regionsByCountryCode setObject:@"WW" forKey:@"ID"];
		[regionsByCountryCode setObject:@"WW" forKey:@"IL"];
		[regionsByCountryCode setObject:@"WW" forKey:@"KR"];
		[regionsByCountryCode setObject:@"WW" forKey:@"KW"];
		[regionsByCountryCode setObject:@"WW" forKey:@"LK"];
		[regionsByCountryCode setObject:@"WW" forKey:@"LB"];
		[regionsByCountryCode setObject:@"WW" forKey:@"MY"];
		[regionsByCountryCode setObject:@"WW" forKey:@"PH"];
		[regionsByCountryCode setObject:@"WW" forKey:@"PK"];
		[regionsByCountryCode setObject:@"WW" forKey:@"QA"];
		[regionsByCountryCode setObject:@"WW" forKey:@"RU"];
		[regionsByCountryCode setObject:@"WW" forKey:@"SG"];
		[regionsByCountryCode setObject:@"WW" forKey:@"SA"];
		[regionsByCountryCode setObject:@"WW" forKey:@"ZA"];
		[regionsByCountryCode setObject:@"WW" forKey:@"SY"];
		[regionsByCountryCode setObject:@"WW" forKey:@"TH"];
		[regionsByCountryCode setObject:@"WW" forKey:@"TR"];
		[regionsByCountryCode setObject:@"WW" forKey:@"AE"];
		[regionsByCountryCode setObject:@"WW" forKey:@"VN"];
		
    }
    return self;
}


- (void)drawRect:(CGRect)rect 
{
	[super drawRect:rect];
	
	CGPoint center = CGPointMake(90, 110);
	float radius = 75.0;
	
	CGContextRef c = UIGraphicsGetCurrentContext();
	[[UIColor grayColor] set];
	CGContextFillEllipseInRect(c, CGRectMake(center.x - radius - 1, center.y - radius - 1, radius * 2 + 4, radius * 2 + 4));
	[[UIColor whiteColor] set];
	CGContextFillEllipseInRect(c, CGRectMake(center.x - radius - 2, center.y - radius - 2, radius * 2 + 4, radius * 2 + 4));
	
	
	if (!self.days || [self.days count] == 0)
		return;
	
	NSMutableDictionary *revenueByRegion = [NSMutableDictionary dictionary];
	[revenueByRegion setObject:[NSNumber numberWithFloat:0.0] forKey:@"AU"];
	[revenueByRegion setObject:[NSNumber numberWithFloat:0.0] forKey:@"CA"];
	[revenueByRegion setObject:[NSNumber numberWithFloat:0.0] forKey:@"EU"];
	[revenueByRegion setObject:[NSNumber numberWithFloat:0.0] forKey:@"GB"];
	[revenueByRegion setObject:[NSNumber numberWithFloat:0.0] forKey:@"JP"];
	[revenueByRegion setObject:[NSNumber numberWithFloat:0.0] forKey:@"US"];
	[revenueByRegion setObject:[NSNumber numberWithFloat:0.0] forKey:@"WW"];
	
	for (Day *d in self.days) {
		for (Country *c in [d.countries allValues]) {
			NSString *region = [regionsByCountryCode objectForKey:c.name];
			if (!region)
				region = @"WW"; //just to be safe...
			float revenueOfCurrentRegion = [[revenueByRegion objectForKey:region] floatValue];
			revenueOfCurrentRegion += [c totalRevenueInBaseCurrency];
			[revenueByRegion setObject:[NSNumber numberWithFloat:revenueOfCurrentRegion] forKey:region];
		}
	}
	
	NSArray *sortedRegions = [revenueByRegion keysSortedByValueUsingSelector:@selector(compare:)];
	float totalRevenue = 0.0;
	for (NSString *region in sortedRegions) {
		totalRevenue += [[revenueByRegion objectForKey:region] floatValue];
	}
	
	//draw title:
	[[UIColor darkGrayColor] set];
	NSString *caption = [NSString stringWithFormat:NSLocalizedString(@"Regions (%i days, ∑ = %@)",nil), [self.days count], [[CurrencyManager sharedManager] baseCurrencyDescriptionForAmount:[NSNumber numberWithFloat:totalRevenue] withFraction:YES]];
	[caption drawInRect:CGRectMake(10, 10, 300, 20) withFont:[UIFont boldSystemFontOfSize:12.0] lineBreakMode:UILineBreakModeCharacterWrap alignment:UITextAlignmentCenter];
	float maxX = 305.0;
	float minX = 15.0;
	float minY = 30.0;
	float maxY = 175.0;
	CGContextBeginPath(c);
	CGContextSetLineWidth(c, 1.0);
	CGContextSetAllowsAntialiasing(c, NO);
	CGContextMoveToPoint(c, minX, minY - 2);
	CGContextAddLineToPoint(c, maxX, minY - 2);
	CGContextDrawPath(c, kCGPathStroke);
	CGContextSetAllowsAntialiasing(c, YES);
	
	//draw pie chart:
	NSArray *colors = [NSArray arrayWithObjects:
					   [UIColor colorWithRed:0.58 green:0.31 blue:0.04 alpha:1.0],
					   [UIColor colorWithRed:0.20 green:0.76 blue:0.78 alpha:1.0],
					   [UIColor colorWithRed:0.96 green:0.11 blue:0.51 alpha:1.0],
					   [UIColor colorWithRed:0.91 green:0.49 blue:0.06 alpha:1.0],
					   [UIColor colorWithRed:0.12 green:0.35 blue:0.71 alpha:1.0],
					   [UIColor colorWithRed:0.84 green:0.11 blue:0.06 alpha:1.0],
					   [UIColor colorWithRed:0.34 green:0.65 blue:0.02 alpha:1.0], nil];
	
	int colorIndex = [colors count] - 1;
	float lastAngle = 0.0;
	for (int i = [sortedRegions count] - 1; i >= 0; i--) {
		NSString *region = [sortedRegions objectAtIndex:i];
	//for (NSString *region in sortedRegions) {
		[[colors objectAtIndex:colorIndex] set];
		colorIndex--;
		if (colorIndex < 0) colorIndex = [colors count] - 1;
		
		float revenue = [[revenueByRegion objectForKey:region] floatValue];
		float percentage = revenue / totalRevenue;
		CGContextBeginPath(c);
		CGContextMoveToPoint(c, center.x, center.y);
		float angle = lastAngle + (percentage * -M_PI * 2);
		CGContextAddArc(c, center.x, center.y, radius, lastAngle, angle, 1);
		CGContextAddLineToPoint(c, center.x, center.y);
		CGContextClosePath(c);
		CGContextDrawPath(c, kCGPathFill);
		
		lastAngle = angle;
	}
	
	NSNumberFormatter *numberFormatter = [[NSNumberFormatter new] autorelease];
	[numberFormatter setMaximumFractionDigits:1];
	[numberFormatter setMinimumIntegerDigits:1];
		
	//draw legend:
	colorIndex = [colors count] - 1;
	int i = 0;
	for (int j = [sortedRegions count] - 1; j >= 0; j--) {
		NSString *region = [sortedRegions objectAtIndex:j];
		float revenue = [[revenueByRegion objectForKey:region] floatValue];
		float percentage = revenue / totalRevenue;
		UIColor *color = [colors objectAtIndex:colorIndex];
		colorIndex--;
		if (colorIndex < 0) colorIndex = [colors count] - 1;
		float y = (minY + 5) + i * ((maxY - minY + 10) / [sortedRegions count]);
		CGRect shadowFrame = CGRectMake(center.x + radius + 12 + 1, y + 1, 20, 20);
		[[UIColor grayColor] set];
		CGContextFillEllipseInRect(c, shadowFrame);
		CGRect legendFrame = CGRectMake(center.x + radius + 12, y, 20, 20);
		[color set];
		CGContextFillEllipseInRect(c, legendFrame);
		NSString *percentString = [numberFormatter stringFromNumber:[NSNumber numberWithFloat:percentage * 100]];
		[[UIColor whiteColor] set];
		[region drawInRect:CGRectMake(legendFrame.origin.x, legendFrame.origin.y + 4, legendFrame.size.width, legendFrame.size.height) withFont:[UIFont boldSystemFontOfSize:10.0] lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentCenter];
		[[UIColor darkGrayColor] set];


		NSString *legendString = [NSString stringWithFormat:@"%@%%  (%@)", percentString, [[CurrencyManager sharedManager] baseCurrencyDescriptionForAmount:[NSNumber numberWithFloat:revenue] withFraction:NO]];
		[legendString drawInRect:CGRectMake(205, y + 3, 110, 10) withFont:[UIFont boldSystemFontOfSize:11.0] lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentLeft];
		i++;
	}
	
	NSLog(@"%@", revenueByRegion);
}


- (void)dealloc 
{
	[regionsByCountryCode release];
    [super dealloc];
}


@end
