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
		
		//WW: the rest will be worldwide
    }
    return self;
}


- (void)drawRect:(CGRect)rect 
{
	[super drawRect:rect];
	
	BOOL showUnits = [[NSUserDefaults standardUserDefaults] boolForKey:@"ShowUnitsInGraphs"];
	
	CGPoint center = CGPointMake(90, 110);
	float	radius = 75.0;
	
	CGContextRef c = UIGraphicsGetCurrentContext();
	[[UIColor grayColor] set];
	CGContextFillEllipseInRect(c, CGRectMake(center.x - radius - 1, center.y - radius - 1, radius * 2 + 4, radius * 2 + 4));
	[[UIColor whiteColor] set];
	CGContextFillEllipseInRect(c, CGRectMake(center.x - radius - 2, center.y - radius - 2, radius * 2 + 4, radius * 2 + 4));
		
	if (!self.days || [self.days count] == 0)
		return;
	
	
	NSMutableDictionary *unitsByRegion = [NSMutableDictionary dictionary];
	[unitsByRegion setObject:[NSNumber numberWithFloat:0.0] forKey:@"AU"];
	[unitsByRegion setObject:[NSNumber numberWithFloat:0.0] forKey:@"CA"];
	[unitsByRegion setObject:[NSNumber numberWithFloat:0.0] forKey:@"EU"];
	[unitsByRegion setObject:[NSNumber numberWithFloat:0.0] forKey:@"GB"];
	[unitsByRegion setObject:[NSNumber numberWithFloat:0.0] forKey:@"JP"];
	[unitsByRegion setObject:[NSNumber numberWithFloat:0.0] forKey:@"US"];
	[unitsByRegion setObject:[NSNumber numberWithFloat:0.0] forKey:@"WW"];
	
	float	totalUnits		= 0;
	
	for (Day *day in self.days) {
		for (Country *country in [day.countries allValues]) {
			NSString *region = [regionsByCountryCode objectForKey:country.name];
			if (!region)
				region = @"WW"; // if not known it's WW
			
			int		unitsofregion		=	[[unitsByRegion objectForKey:region] intValue];
			int		unitsofcountry		=	showUnits?[country totalUnits]:[country totalRevenueInBaseCurrency];
					totalUnits			+=	unitsofcountry;

			[unitsByRegion setObject:[NSNumber numberWithInt:(unitsofregion+unitsofcountry)] forKey:region];
		}
	}
	
	NSString	*caption;
	NSArray		*sortedRegions	= [unitsByRegion keysSortedByValueUsingSelector:@selector(compare:)];

	if (showUnits)
	{
		caption			= [NSString stringWithFormat:NSLocalizedString(@"Regions (%i days, ∑ = %i sales)",nil), [self.days count],(int)totalUnits];
	}
	else
	{
		caption			= [NSString stringWithFormat:NSLocalizedString(@"Regions (%i days, ∑ = %@)",nil), [self.days count], [[CurrencyManager sharedManager] baseCurrencyDescriptionForAmount:[NSNumber numberWithFloat:totalUnits] withFraction:YES]];
	}

	[[UIColor darkGrayColor] set];
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
	NSDictionary	*colorCountryDictionary	= [NSDictionary dictionaryWithObjectsAndKeys:	[UIColor colorWithRed:0.58 green:0.31 blue:0.04 alpha:1.0],	@"WW",
																							[UIColor colorWithRed:0.20 green:0.76 blue:0.78 alpha:1.0],	@"AU",
																							[UIColor colorWithRed:0.96 green:0.11 blue:0.51 alpha:1.0],	@"JP",
																							[UIColor colorWithRed:0.91 green:0.49 blue:0.06 alpha:1.0],	@"CA", 
																							[UIColor colorWithRed:0.12 green:0.35 blue:0.71 alpha:1.0],	@"EU",
																							[UIColor colorWithRed:0.84 green:0.11 blue:0.06 alpha:1.0],	@"GB",
																							[UIColor colorWithRed:0.34 green:0.65 blue:0.02 alpha:1.0],	@"US", nil];

	float lastAngle = -M_PI_2;

	NSNumberFormatter *numberFormatter = [[NSNumberFormatter new] autorelease];
	[numberFormatter setMaximumFractionDigits:1];
	[numberFormatter setMinimumIntegerDigits:1];
		
	for (int i = 0; i< [sortedRegions count] ; i++ ) {
		NSString	*region			= [sortedRegions objectAtIndex:i];
		UIColor		*regionColor	= [colorCountryDictionary objectForKey:region];
		float		units			= [[unitsByRegion objectForKey:region] floatValue];
		float		percentage		= units / totalUnits;

		[regionColor set];
		{
			float angle = lastAngle - (percentage * 2*M_PI);
			CGContextBeginPath(c);
			CGContextMoveToPoint(c, center.x, center.y);
			CGContextAddArc(c, center.x, center.y, radius, lastAngle, angle, 1);
			CGContextAddLineToPoint(c, center.x, center.y);
			CGContextClosePath(c);
			CGContextDrawPath(c, kCGPathFill);
			
			lastAngle = angle;
		}
		
		{
			NSString *legendString;
			if (showUnits) {
				NSString *percentString = [numberFormatter stringFromNumber:[NSNumber numberWithFloat:percentage * 100]];
				legendString = [NSString stringWithFormat:@"%@%% (%i)", percentString, (int)units];
			}
			else {
				NSString *percentString = [numberFormatter stringFromNumber:[NSNumber numberWithFloat:percentage * 100]];
				legendString = [NSString stringWithFormat:@"%@%%  (%@)", percentString, [[CurrencyManager sharedManager] baseCurrencyDescriptionForAmount:[NSNumber numberWithFloat:units] withFraction:NO]];
			}
			float y = maxY - 5  - (i * ((maxY - minY + 10) / [sortedRegions count])) ;
			CGRect shadowFrame = CGRectMake(center.x + radius + 12 + 1, y + 1, 20, 20);
			[[UIColor grayColor] set];
			CGContextFillEllipseInRect(c, shadowFrame);
			CGRect legendFrame = CGRectMake(center.x + radius + 12, y, 20, 20);
			[regionColor set];
			CGContextFillEllipseInRect(c, legendFrame);
			[[UIColor whiteColor] set];
			[region drawInRect:CGRectMake(legendFrame.origin.x, legendFrame.origin.y + 4, legendFrame.size.width, legendFrame.size.height) withFont:[UIFont boldSystemFontOfSize:10.0] lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentCenter];
			[[UIColor darkGrayColor] set];
			[legendString drawInRect:CGRectMake(205, y + 3, 110, 10) withFont:[UIFont boldSystemFontOfSize:11.0] lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentLeft];
		}
	}
}


- (void)dealloc 
{
	[regionsByCountryCode release];
    [super dealloc];
}


@end
