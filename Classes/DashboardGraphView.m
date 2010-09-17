//
//  DashboardGraphView.m
//  AppSalesMobile
//
//  Created by Ole Zorn on 06.04.10.
//  Copyright 2010 omz:software. All rights reserved.
//

#import "DashboardGraphView.h"
#import "CurrencyManager.h"
#import "Day.h"
#import "Country.h"
#import "NSDateFormatter+SharedInstances.h"
#import "AppManager.h"

@implementation DashboardGraphView

@synthesize reports, showsWeeklyReports, showsUnits, showsRegions, appFilter;

- (id)initWithFrame:(CGRect)frame 
{
	if ((self = [super initWithFrame:frame])) {
		self.backgroundColor = [UIColor clearColor];
		self.contentMode = UIViewContentModeRedraw;
		
		markedReportIndex = -1;
		
		markerLineView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, self.bounds.size.height)] autorelease];
		markerLineView.backgroundColor = [UIColor blackColor];
		markerLineView.alpha = 0.0;
		[self addSubview:markerLineView];
		
		detailTopView = [[[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"GraphDetailTop.png"] stretchableImageWithLeftCapWidth:10 topCapHeight:0]] autorelease];
		detailTopView.alpha = 0.0;
		detailLabel = [[[UILabel alloc] initWithFrame:CGRectInset(detailTopView.bounds, 5, 0)] autorelease];
		detailLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		detailLabel.backgroundColor = [UIColor clearColor];
		detailLabel.font = [UIFont boldSystemFontOfSize:14.0];
		detailLabel.textColor = [UIColor darkGrayColor];
		detailLabel.textAlignment = UITextAlignmentCenter;
		[detailTopView addSubview:detailLabel];
		
		[self addSubview:detailTopView];
		
		detailBottomView = [[[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"GraphDetailBottom.png"] stretchableImageWithLeftCapWidth:10 topCapHeight:0]] autorelease];
		detailBottomView.alpha = 0.0;
		dateLabel = [[[UILabel alloc] initWithFrame:detailBottomView.bounds] autorelease];
		dateLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		dateLabel.backgroundColor = [UIColor clearColor];
		dateLabel.font = [UIFont boldSystemFontOfSize:14.0];
		dateLabel.textColor = [UIColor darkGrayColor];
		dateLabel.textAlignment = UITextAlignmentCenter;
		[detailBottomView addSubview:dateLabel];
		[self addSubview:detailBottomView];
		
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
		[regionsByCountryCode setObject:@"US" forKey:@"CR"];
		[regionsByCountryCode setObject:@"US" forKey:@"JM"];
		[regionsByCountryCode setObject:@"US" forKey:@"PA"];
		[regionsByCountryCode setObject:@"US" forKey:@"PE"];
		
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
	markedReportIndex = -1;
	if (!reports || [reports count] == 0) return;
	if (showsRegions) {
		[self drawRegionsGraph];
	} else {
		[self drawTrendGraph];
	}
}

- (void)drawRegionsGraph
{
	BOOL showUnits = showsUnits;
	
	float radius = self.bounds.size.height / 2 - 25;
	CGPoint center = CGPointMake(radius + 10, self.bounds.size.height / 2 + 15);
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	[[UIColor grayColor] set];
	CGContextFillEllipseInRect(context, CGRectMake(center.x - radius - 1, center.y - radius - 1, radius * 2 + 4, radius * 2 + 4));
	[[UIColor whiteColor] set];
	CGContextFillEllipseInRect(context, CGRectMake(center.x - radius - 2, center.y - radius - 2, radius * 2 + 4, radius * 2 + 4));
	
	if (!self.reports || [self.reports count] == 0)
		return;
	
	NSMutableDictionary *revenueByRegion = [NSMutableDictionary dictionary];
	[revenueByRegion setObject:[NSNumber numberWithFloat:0.0] forKey:@"AU"];
	[revenueByRegion setObject:[NSNumber numberWithFloat:0.0] forKey:@"CA"];
	[revenueByRegion setObject:[NSNumber numberWithFloat:0.0] forKey:@"EU"];
	[revenueByRegion setObject:[NSNumber numberWithFloat:0.0] forKey:@"GB"];
	[revenueByRegion setObject:[NSNumber numberWithFloat:0.0] forKey:@"JP"];
	[revenueByRegion setObject:[NSNumber numberWithFloat:0.0] forKey:@"US"];
	[revenueByRegion setObject:[NSNumber numberWithFloat:0.0] forKey:@"WW"];
	NSMutableDictionary *unitsByRegion = [[revenueByRegion mutableCopyWithZone: NULL] autorelease];
	
	int totalUnits = 0;
	for (Day *d in self.reports) {
		for (Country *c in [d.countries allValues]) {
			NSString *region = [regionsByCountryCode objectForKey:c.name];
			if (!region)
				region = @"WW"; //just to be safe...
			float revenueOfCurrentRegion = [[revenueByRegion objectForKey:region] floatValue];
			revenueOfCurrentRegion += [c totalRevenueInBaseCurrency];
			[revenueByRegion setObject:[NSNumber numberWithFloat:revenueOfCurrentRegion] forKey:region];
			int unitsOfCurrentRegion = [[unitsByRegion objectForKey:region] intValue];
			int units = [c totalUnits];
			unitsOfCurrentRegion += units;
			totalUnits += units;
			[unitsByRegion setObject:[NSNumber numberWithInt:unitsOfCurrentRegion] forKey:region];
		}
	}
	
	NSArray *sortedRegions = [revenueByRegion keysSortedByValueUsingSelector:@selector(compare:)];
	float totalRevenue = 0.0;
	for (NSString *region in sortedRegions) {
		totalRevenue += [[revenueByRegion objectForKey:region] floatValue];
	}
	sortedRegions = [unitsByRegion keysSortedByValueUsingSelector:@selector(compare:)];
	
	//draw title:
	[[UIColor darkGrayColor] set];
	NSString *caption;
	if (showUnits) {
		caption = [NSString stringWithFormat:(showsWeeklyReports) ? NSLocalizedString(@"Regions (%i weeks, ∑ = %i sales)",nil) : NSLocalizedString(@"Regions (%i days, ∑ = %i sales)",nil), [self.reports count], totalUnits];
	}
	else {
		caption = [NSString stringWithFormat:(showsWeeklyReports) ? NSLocalizedString(@"Regions (%i weeks, ∑ = %@)",nil) : NSLocalizedString(@"Regions (%i days, ∑ = %@)",nil), [self.reports count], [[CurrencyManager sharedManager] baseCurrencyDescriptionForAmount:[NSNumber numberWithFloat:totalRevenue] withFraction:YES]];
	}
	float maxX = self.bounds.size.width;
	float minX = 15.0;
	float minY = 30.0;
	float maxY = self.bounds.size.height;
	
	[caption drawInRect:CGRectMake(minX, 5, maxX - minX, 20) withFont:[UIFont boldSystemFontOfSize:12.0] lineBreakMode:UILineBreakModeCharacterWrap alignment:UITextAlignmentCenter];
	CGContextBeginPath(context);
	CGContextSetLineWidth(context, 1.0);
	CGContextSetAllowsAntialiasing(context, NO);
	CGContextMoveToPoint(context, minX, minY - 2);
	CGContextAddLineToPoint(context, maxX, minY - 2);
	CGContextDrawPath(context, kCGPathStroke);
	CGContextSetAllowsAntialiasing(context, YES);
	
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
		[[colors objectAtIndex:colorIndex] set];
		colorIndex--;
		if (colorIndex < 0) colorIndex = [colors count] - 1;
		
		float units = [[unitsByRegion objectForKey:region] floatValue];
		float percentage = units / totalUnits;
		CGContextBeginPath(context);
		CGContextMoveToPoint(context, center.x, center.y);
		float angle = lastAngle + (percentage * -M_PI * 2);
		CGContextAddArc(context, center.x, center.y, radius, lastAngle, angle, 1);
		CGContextAddLineToPoint(context, center.x, center.y);
		CGContextClosePath(context);
		CGContextDrawPath(context, kCGPathFill);
		
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
		float units = [[unitsByRegion objectForKey:region] floatValue];
		float percentage = units / totalUnits;
		UIColor *color = [colors objectAtIndex:colorIndex];
		colorIndex--;
		if (colorIndex < 0) colorIndex = [colors count] - 1;
		float y = (minY + 5) + i * ((maxY - minY + 10) / [sortedRegions count]);
		CGRect shadowFrame = CGRectMake(center.x + radius + 20 + 1, y + 1, 20, 20);
		[[UIColor grayColor] set];
		CGContextFillEllipseInRect(context, shadowFrame);
		CGRect legendFrame = CGRectMake(center.x + radius + 20, y, 20, 20);
		[color set];
		CGContextFillEllipseInRect(context, legendFrame);
		NSString *percentString = [numberFormatter stringFromNumber:[NSNumber numberWithFloat:percentage * 100]];
		[[UIColor whiteColor] set];
		[region drawInRect:CGRectMake(legendFrame.origin.x, legendFrame.origin.y + 4, legendFrame.size.width, legendFrame.size.height) withFont:[UIFont boldSystemFontOfSize:10.0] lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentCenter];
		[[UIColor darkGrayColor] set];
		NSString *legendString;
		if (showUnits)
			legendString = [NSString stringWithFormat:@"%@%% (%i)", percentString, (int)units];
		else
			legendString = [NSString stringWithFormat:@"%@%%  (%@)", percentString, [[CurrencyManager sharedManager] baseCurrencyDescriptionForAmount:[NSNumber numberWithFloat:revenue] withFraction:NO]];
		[legendString drawInRect:CGRectMake(legendFrame.origin.x + legendFrame.size.width + 10, y + 3, 110, 10) withFont:[UIFont boldSystemFontOfSize:11.0] lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentLeft];
		i++;
	}
}

- (void)drawTrendGraph
{
	CGContextRef c = UIGraphicsGetCurrentContext();
	
	//draw background:
	CGRect bounds = self.bounds;
	float maxX = bounds.origin.x + bounds.size.width - 20;
	float minX = 40.0;
	float minY = 30.0;
	float maxY = bounds.size.height - minY;
	
	NSMutableArray *revenues = [NSMutableArray array];
	float maxRevenue = 0.0;
	float totalRevenue = 0.0;
	for (Day *d in reports) {
		float revenue;
		if (showsUnits) {
			if (appFilter) {
				revenue = (float)[d totalUnitsForAppWithID:[[AppManager sharedManager] appIDForAppName:appFilter]];
			} else {
				revenue = (float)[d totalUnits];
			}
		} else {
			if (appFilter) {
				revenue = [d totalRevenueInBaseCurrencyForAppWithID:[[AppManager sharedManager] appIDForAppName:appFilter]];
			} else {
				revenue = [d totalRevenueInBaseCurrency];
			}
		}
		totalRevenue += revenue;
		if(!showsWeeklyReports && d.isWeek){
			revenue /= 7.0;
			for(int i = 0; i < 7; i++)
				[revenues addObject:[NSNumber numberWithFloat:revenue]];
		}else{
			[revenues addObject:[NSNumber numberWithFloat:revenue]];
		}
		if (revenue > maxRevenue) maxRevenue = revenue;
	}
	if (maxRevenue == 0.0) {
		return;
	}
	
	UIColor *graphColor = (showsWeeklyReports) ? [UIColor colorWithRed:0.12 green:0.35 blue:0.71 alpha:1.0] : [UIColor colorWithRed:0.800 green:0.000 blue:0.000 alpha:1.0];//[UIColor colorWithRed:0.149 green:0.592 blue:0.000 alpha:1.0];
	
	NSString *maxString = [NSString stringWithFormat:@"%i", (int)maxRevenue];

	const int rightMargin = 4;
	float requiredWidth = [maxString sizeWithFont:[UIFont boldSystemFontOfSize:13.0]].width;
	if (requiredWidth + rightMargin > minX)
		minX = requiredWidth + rightMargin;

	//draw grid and captions:
	CGContextBeginPath(c);
	CGContextSetLineWidth(c, 1.0);
	CGContextSetAllowsAntialiasing(c, NO);
	[[UIColor darkGrayColor] set];
	CGContextMoveToPoint(c, minX, minY - 2);
	CGContextAddLineToPoint(c, maxX, minY - 2);
	CGContextMoveToPoint(c, maxX, maxY + 2);
	CGContextAddLineToPoint(c, minX, maxY + 2);
	CGContextDrawPath(c, kCGPathStroke);
	CGContextSetAllowsAntialiasing(c, YES);
	[@"0" drawInRect:CGRectMake(0, maxY - 8, minX - rightMargin, 10) withFont:[UIFont boldSystemFontOfSize:13.0] lineBreakMode:UILineBreakModeCharacterWrap alignment:UITextAlignmentRight];
	[maxString drawInRect:CGRectMake(0, minY - 10, minX - rightMargin, 10) withFont:[UIFont boldSystemFontOfSize:13.0] lineBreakMode:UILineBreakModeCharacterWrap alignment:UITextAlignmentRight];
	float averageRevenue = totalRevenue / [revenues count];
	float averageY = maxY - ((averageRevenue / maxRevenue) * (maxY - minY));
	if ((averageY < (maxY + 10)) && (averageY > (minY + 10))) {
		NSString *averageString = [NSString stringWithFormat:@"%i", (int)averageRevenue];
		[graphColor set];
		[averageString drawInRect:CGRectMake(0, averageY - 8, minX - 4, 10) withFont:[UIFont boldSystemFontOfSize:13.0] lineBreakMode:UILineBreakModeCharacterWrap alignment:UITextAlignmentRight];
	}
	[[UIColor darkGrayColor] set];
	
	NSString *caption = nil;
	if (showsUnits) {
		caption = NSLocalizedString(@"Sales",nil);
	} else {
		caption = [NSString stringWithFormat:NSLocalizedString(@"Revenue (in %@)",nil), [[CurrencyManager sharedManager] baseCurrencyDescription]];
	}
	
	[caption drawInRect:CGRectMake(minX, 5, maxX - minX, 20) withFont:[UIFont boldSystemFontOfSize:13.0] lineBreakMode:UILineBreakModeCharacterWrap alignment:UITextAlignmentCenter];
	NSString *subtitle = nil;
	if (showsUnits) {
		subtitle = [NSString stringWithFormat:(showsWeeklyReports) ? NSLocalizedString(@"%i weeks, ∑ = %@",nil) : NSLocalizedString(@"%i days, ∑ = %@",nil), [revenues count], [NSString stringWithFormat:@"%i", (int)totalRevenue]];
	} else {
		subtitle = [NSString stringWithFormat:(showsWeeklyReports) ? NSLocalizedString(@"%i weeks, ∑ = %@",nil) : NSLocalizedString(@"%i days, ∑ = %@",nil), [revenues count], [[CurrencyManager sharedManager] baseCurrencyDescriptionForAmount:[NSNumber numberWithFloat:totalRevenue] withFraction:YES]];
	}
	
	[subtitle drawInRect:CGRectMake(minX, maxY + 5, maxX - minX, 20) withFont:[UIFont boldSystemFontOfSize:13.0] lineBreakMode:UILineBreakModeCharacterWrap alignment:UITextAlignmentCenter];
	
	NSString *appName = (appFilter) ? appFilter : NSLocalizedString(@"All Apps",nil);
	NSString *bigTitle = nil;
	if (showsWeeklyReports) {
		bigTitle = [NSString stringWithFormat:NSLocalizedString(@"Weekly – %@",nil), appName];
	} else {
		bigTitle = [NSString stringWithFormat:NSLocalizedString(@"Daily – %@",nil), appName];
	}
	float actualFontSize = 10.0;
	[bigTitle sizeWithFont:[UIFont boldSystemFontOfSize:100.0] minFontSize:10.0 actualFontSize:&actualFontSize forWidth:(maxX - minX) lineBreakMode:UILineBreakModeClip];
	CGSize actualSize = [bigTitle sizeWithFont:[UIFont boldSystemFontOfSize:actualFontSize]];
	[[UIColor colorWithWhite:0.85 alpha:1.0] set];
	CGRect bigTitleRect = CGRectMake(minX, maxY - actualSize.height, maxX - minX, actualSize.height);
	if (averageY > (maxY-minY)/2) {
		bigTitleRect = CGRectMake(minX, minY, maxX - minX, actualSize.height);
	}
	[bigTitle drawInRect:bigTitleRect withFont:[UIFont boldSystemFontOfSize:actualFontSize] lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentLeft];
	
	//draw weekend background:
	if (!showsWeeklyReports && [reports count] <= 31) {
		CGContextSetAllowsAntialiasing(c, NO);
		float weekendWidth = (maxX - minX) / ([reports count] - 1);
		NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
		[[UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.1] set];
		
		int i = 0;
		for (Day *d in reports) {
			NSDateComponents *comps = [gregorian components:NSWeekdayCalendarUnit fromDate:d.date];
			if ([comps weekday] == 7) {
				float x = minX + ((maxX - minX) / ([reports count] - 1)) * i;
				float x2 = x + weekendWidth;
				if (x2 > maxX) x2 = maxX;
				CGRect weekendRect = CGRectMake(x, minY - 2, (x2 - x), (maxY - minY) + 3);
				CGContextFillRect(c, weekendRect);
			}
			i++;
		}
		CGContextSetAllowsAntialiasing(c, YES);
	}
	
	//draw trend line:
	[graphColor set];
	int i = 0;
	float prevX = 0.0;
	//float prevY = 0.0;
	CGContextBeginPath(c);
	CGContextSetLineWidth(c, 2.0);
	CGContextSetLineJoin(c, kCGLineJoinRound);
	for (NSNumber *revenue in revenues) {
		float r = [revenue floatValue];
		float y = maxY - ((r / maxRevenue) * (maxY - minY));
		float x = minX + ((maxX - minX) / ([revenues count] - 1)) * i;
		if (prevX == 0.0) {
			CGContextMoveToPoint(c, x, y);
		}
		else {
			CGContextAddLineToPoint(c, x, y);
		}
		prevX = x;
		//	prevY = y;
		i++;
	}
	CGContextDrawPath(c, kCGPathStroke);
	
	//draw average line:
	[graphColor set];
	CGContextSetLineWidth(c, 1.0);
	CGContextSetAllowsAntialiasing(c, NO);
	CGContextBeginPath(c);
	float lengths[] = {2.0, 2.0};
	CGContextSetLineDash(c, 0.0, lengths, 2);
	CGContextMoveToPoint(c, minX, averageY);
	CGContextAddLineToPoint(c, maxX, averageY);
	CGContextDrawPath(c, kCGPathStroke);
	CGContextSetLineDash(c, 0.0, NULL, 0);
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (showsRegions || !self.reports || [self.reports count] == 0) return;
		
	UITouch *touch = [touches anyObject];
	[self moveMarkerForTouch:touch];
	markerLineView.alpha = 1.0;
	detailTopView.alpha = 1.0;
	detailBottomView.alpha = 1.0;
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (showsRegions || !self.reports || [self.reports count] == 0) return;
	
	UITouch *touch = [touches anyObject];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[self moveMarkerForTouch:touch];
}

- (int)reportIndexForTouch:(UITouch *)touch
{
	CGRect bounds = self.bounds;
	float maxX = bounds.origin.x + bounds.size.width - 20;
	float minX = 40.0;
	float x = [touch locationInView:self].x;
	if (x < minX) x = minX;
	if (x > maxX) x = maxX;
	float relativeX = (x - minX);
	float widthForSegment = (maxX - minX) / ([reports count] - 1);
	float segment = (relativeX / widthForSegment);
	int segmentIndex = (int)(segment + 0.5);
	return segmentIndex;
}

- (void)moveMarkerForTouch:(UITouch *)touch
{
	int index = [self reportIndexForTouch:touch];
	if (index == markedReportIndex) return;
	markedReportIndex = index;
	
	float maxX = self.bounds.origin.x + self.bounds.size.width - 20;
	float minX = 40.0;
	float minY = 30.0;
	float maxY = self.bounds.size.height - minY;
	float x = minX + ((maxX - minX) / ([reports count] - 1)) * index;
	markerLineView.frame = CGRectMake(x, minY, 1, maxY - minY);
	
	detailTopView.frame = CGRectMake(minX, minY - 30, 200, 28);
	
	CGRect bottomFrame = CGRectMake(markerLineView.frame.origin.x - 50, maxY + 1, 100, 28);
	if (bottomFrame.origin.x < minX) bottomFrame.origin.x = minX;
	if (bottomFrame.origin.x + bottomFrame.size.width > maxX) bottomFrame.origin.x = maxX - 100;
	detailBottomView.frame = bottomFrame;
	
	Day *report = [reports objectAtIndex:index];
	NSString *dateString = [[NSDateFormatter sharedShortDateFormatter] stringFromDate:report.date];
	dateLabel.text = dateString;
	
	NSString *detailText = nil;
	if (showsUnits) {
		if (appFilter) {
			detailText = [NSString stringWithFormat:@"%i × %@", [report totalUnitsForAppWithID:[[AppManager sharedManager] appIDForAppName:appFilter]], appFilter];
		} else {
			detailText = [NSString stringWithFormat:@"%i sales %@", [report totalUnits], [report description]];
		}
	} else {
		if (appFilter) {
			detailText = [NSString stringWithFormat:@"%@ (%i × %@)", [report totalRevenueStringForApp:appFilter], [report totalUnitsForAppWithID:[[AppManager sharedManager] appIDForAppName:appFilter]], appFilter];
		} else {
			detailText = [NSString stringWithFormat:@"%@ %@", [report totalRevenueString], [report description]];
		}
	}
	
	CGFloat detailWidth = [detailText sizeWithFont:detailLabel.font].width;
	detailWidth += 10;
	if (detailWidth > (maxX - minX)) detailWidth = (maxX - minX);
	CGRect topFrame = CGRectMake(markerLineView.frame.origin.x - detailWidth/2, minY - 30, detailWidth, 28);
	if (topFrame.origin.x < minX) topFrame.origin.x = minX;
	if (topFrame.origin.x + topFrame.size.width > maxX) topFrame.origin.x = maxX - topFrame.size.width;
	
	detailTopView.frame = topFrame;
	
	detailLabel.text = detailText;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	[UIView beginAnimations:@"fadeout" context:nil];
	markerLineView.alpha = 0.0;
	detailTopView.alpha = 0.0;
	detailBottomView.alpha = 0.0;
	[UIView commitAnimations];
}


- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	[UIView beginAnimations:@"fadeout" context:nil];
	markerLineView.alpha = 0.0;
	[UIView commitAnimations];
}


- (void)dealloc 
{
	[appFilter release];
	[reports release];
    [super dealloc];
}


@end
