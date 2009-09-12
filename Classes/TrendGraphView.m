//
//  TrendGraphView.m
//  AppSalesMobile
//
//  Created by Ole Zorn on 16.02.09.
//  Copyright 2009 omz:software. All rights reserved.
//

#import "TrendGraphView.h"
#import "Day.h"
#import "CurrencyManager.h"

@implementation TrendGraphView

@synthesize app;

- (id)initWithFrame:(CGRect)rect
{
	[super initWithFrame:rect];
	
	return self;
}

- (void)drawRect:(CGRect)rect 
{
	[super drawRect:rect];
	
	CGContextRef c = UIGraphicsGetCurrentContext();
	
	BOOL showUnits = [[NSUserDefaults standardUserDefaults] boolForKey:@"ShowUnitsInGraphs"];
		
	//draw background:
	float maxX = 305.0;
	float minX = 40.0;
	float minY = 30.0;
	float maxY = 170;
	
	if (!self.days || [self.days count] == 0)
		return;
	
	NSMutableArray *revenues = [NSMutableArray array];
	float maxRevenue = 0.0;
	float totalRevenue = 0.0;
	for (Day *d in self.days) {
		float revenue = (showUnits) ? (float)[d totalUnitsForApp:self.app] : [d totalRevenueInBaseCurrencyForApp:self.app];
		[revenues addObject:[NSNumber numberWithFloat:revenue]];
		totalRevenue += revenue;
		if (revenue > maxRevenue) maxRevenue = revenue;
	}
	if (maxRevenue == 0.0) {
		return;
	}
	
	UIColor *graphColor = (self.app) ? [UIColor colorWithRed:0.12 green:0.35 blue:0.71 alpha:1.0] : [UIColor colorWithRed:0.84 green:0.11 blue:0.06 alpha:1.0];
	
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
	[@"0" drawInRect:CGRectMake(0, maxY - 4, minX - 4, 10) withFont:[UIFont boldSystemFontOfSize:10.0] lineBreakMode:UILineBreakModeCharacterWrap alignment:UITextAlignmentRight];
	NSString *maxString = [NSString stringWithFormat:@"%i", (int)maxRevenue];
	[maxString drawInRect:CGRectMake(0, minY - 8, minX - 4, 10) withFont:[UIFont boldSystemFontOfSize:10.0] lineBreakMode:UILineBreakModeCharacterWrap alignment:UITextAlignmentRight];
	float averageRevenue = totalRevenue / [revenues count];
	float averageY = maxY - ((averageRevenue / maxRevenue) * (maxY - minY));
	if ((averageY < (maxY + 10)) && (averageY > (minY + 10))) {
		NSString *averageString = [NSString stringWithFormat:@"%i", (int)averageRevenue];
		[graphColor set];
		[averageString drawInRect:CGRectMake(0, averageY - 6, minX - 4, 10) withFont:[UIFont boldSystemFontOfSize:10.0] lineBreakMode:UILineBreakModeCharacterWrap alignment:UITextAlignmentRight];
	}
	[[UIColor darkGrayColor] set];
	
	NSString *caption;
	if (showUnits)
		caption = NSLocalizedString(@"Sales",nil);
	else
		caption = [NSString stringWithFormat:NSLocalizedString(@"Revenue (in %@)",nil), [[CurrencyManager sharedManager] baseCurrencyDescription]];
	
	[caption drawInRect:CGRectMake(10, 10, 300, 20) withFont:[UIFont boldSystemFontOfSize:12.0] lineBreakMode:UILineBreakModeCharacterWrap alignment:UITextAlignmentCenter];
	NSString *subtitle;
	if (showUnits)
		subtitle = [NSString stringWithFormat:NSLocalizedString(@"%i days, ∑ = %i sales",nil), [revenues count], (int)totalRevenue];
	else
		subtitle = [NSString stringWithFormat:NSLocalizedString(@"%i days, ∑ = %@",nil), [revenues count], [[CurrencyManager sharedManager] baseCurrencyDescriptionForAmount:[NSNumber numberWithFloat:totalRevenue] withFraction:YES]];
	
	[subtitle drawInRect:CGRectMake(10, maxY + 5, 300, 20) withFont:[UIFont boldSystemFontOfSize:12.0] lineBreakMode:UILineBreakModeCharacterWrap alignment:UITextAlignmentCenter];
	
	NSString *appName = (self.app != nil) ? (self.app) : NSLocalizedString(@"All Apps",nil);
	float actualFontSize = 10.0;
	[appName sizeWithFont:[UIFont boldSystemFontOfSize:100.0] minFontSize:10.0 actualFontSize:&actualFontSize forWidth:(maxX - minX) lineBreakMode:UILineBreakModeClip];
	CGSize actualSize = [appName sizeWithFont:[UIFont boldSystemFontOfSize:actualFontSize]];
	[[UIColor colorWithWhite:0.8 alpha:1.0] set];
	CGRect appNameRect = CGRectMake(minX, maxY - actualSize.height, maxX - minX, actualSize.height);
	if (averageY > 100)
		appNameRect = CGRectMake(minX, minY, maxX - minX, actualSize.height);
	[appName drawInRect:appNameRect withFont:[UIFont boldSystemFontOfSize:actualFontSize] lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentLeft];
		
	//draw weekend background:
	if ([days count] <= 31) {
		CGContextSetAllowsAntialiasing(c, NO);
		float weekendWidth = (maxX - minX) / ([days count] - 1);
		NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
		UIColor *shade;
		if (self.app == nil)
			shade = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.1];
		else
			shade = [UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:0.1];
		[shade set];
		int i = 0;
		for (Day *d in self.days) {
			//NSLog(@"%@", d.date);
			NSDateComponents *comps = [gregorian components:NSWeekdayCalendarUnit fromDate:d.date];
			if ([comps weekday] == 7) {
				float x = minX + ((maxX - minX) / ([days count] - 1)) * i;
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


- (void)dealloc 
{
	self.app = nil;
	
    [super dealloc];
}


@end
