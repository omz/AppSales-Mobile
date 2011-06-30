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
#import "ReportManager.h"

@implementation TrendGraphView

@synthesize appName, appID;

- (id)initWithFrame:(CGRect)rect
{
	[super initWithFrame:rect];
	
	return self;
}

- (void)drawRect:(CGRect)rect 
{
	[super drawRect:rect];

	BOOL showUnits = [[NSUserDefaults standardUserDefaults] boolForKey:@"ShowUnitsInGraphs"];

	//draw background:
	float maxX = 305.0;
	float minX = 40.0;
	float minY = 30.0;
	float maxY = 170;
	
	NSMutableArray *revenues		= [NSMutableArray array];
	NSMutableArray *customerprices	= [NSMutableArray array];
	float maxRevenue = 0.0;
	float totalRevenue = 0.0;
	Day* lastDay = nil;
    
	BOOL	customerpricehaschangedatleastonce	= NO;
    int		maxcustomerprice					= -1.0;
	int		lastcustomerprice					= -1.0;
	
	for( Day *d in self.days ) 
	{
        int customerprice		= lrint([d customerUSPriceForAppWithID:appID]*100.0);
		float unitsorrevenue	= (showUnits) ? (float)[d totalUnitsForAppWithID:appID] : (float)[d totalRevenueInBaseCurrencyForAppWithID:appID];
	
		if( customerprice < 0 )
		{
			customerprice = lastcustomerprice;
		}
		else 
		{
			if( lastcustomerprice >= 0 && (lastcustomerprice!=customerprice) )
			{
				customerpricehaschangedatleastonce = YES;
			}
			lastcustomerprice = customerprice;
		}

		totalRevenue += unitsorrevenue;

		if( lastDay )
		{			
			for (int j=1; [d.date timeIntervalSinceDate:lastDay.date] > 3600*24*j ; j++) 
			{
				[revenues		addObject:[NSNumber numberWithFloat:0.0f]]; //add zero revenue for days with no reports
				[customerprices	addObject:[NSNumber numberWithInt:lastcustomerprice]];
			}
		}
		
		[revenues		addObject:[NSNumber numberWithFloat:unitsorrevenue]];
		[customerprices	addObject:[NSNumber numberWithInt:customerprice]];
		
		if (unitsorrevenue > maxRevenue)		maxRevenue = unitsorrevenue;
		if (customerprice > maxcustomerprice)	maxcustomerprice = customerprice;
		
		lastDay = d;
	}
	
	UIColor *graphColor = (self.appName) ? [UIColor colorWithRed:0.12 green:0.35 blue:0.71 alpha:1.0] : [UIColor colorWithRed:0.84 green:0.11 blue:0.06 alpha:1.0];
	
	CGContextRef c = UIGraphicsGetCurrentContext();
	CGContextSaveGState(c); // push contet
	
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
	[maxString drawInRect:CGRectMake(0, minY - 12, minX - 4, 10) withFont:[UIFont boldSystemFontOfSize:10.0] lineBreakMode:UILineBreakModeCharacterWrap alignment:UITextAlignmentRight];
	float averageRevenue = totalRevenue / [revenues count];
	float averageY = maxY - ((averageRevenue / maxRevenue) * (maxY - minY));
	if ((averageY < (maxY + 10)) && (averageY > (minY + 10))) {
		NSString *averageString = (averageRevenue < 100 )? [NSString stringWithFormat:@"%.1f", averageRevenue] : [NSString stringWithFormat:@"%i", (int)averageRevenue];
		[graphColor set];
		[averageString drawInRect:CGRectMake(0, averageY - 6, minX - 4, 10) withFont:[UIFont boldSystemFontOfSize:10.0] lineBreakMode:UILineBreakModeCharacterWrap alignment:UITextAlignmentRight];
	}
	
	
	
	[[UIColor darkGrayColor] set];
	
	NSString *caption;
	if (showUnits) {
		caption = NSLocalizedString(@"Sales",nil);
	} else {
		caption = [NSString stringWithFormat:NSLocalizedString(@"Revenue (in %@)",nil), [[CurrencyManager sharedManager] baseCurrencyDescription]];
	}
	[caption drawInRect:CGRectMake(10, 10, 140, 20) withFont:[UIFont boldSystemFontOfSize:12.0] lineBreakMode:UILineBreakModeCharacterWrap alignment:UITextAlignmentRight];

	
	NSString *appNameToShow = (self.appName != nil) ? (self.appName) : NSLocalizedString(@"All Apps",nil);
	float actualFontSize = 10.0;
	[appNameToShow sizeWithFont:[UIFont boldSystemFontOfSize:100.0] minFontSize:10.0 actualFontSize:&actualFontSize forWidth:(maxX - minX) lineBreakMode:UILineBreakModeClip];
	CGSize actualSize = [appNameToShow sizeWithFont:[UIFont boldSystemFontOfSize:actualFontSize]];
	[[UIColor colorWithWhite:0.8 alpha:1.0] set];
	CGRect appNameRect = CGRectMake(minX, maxY - actualSize.height, maxX - minX, actualSize.height);
	if (averageY > 100) {
		appNameRect = CGRectMake(minX, minY, maxX - minX, actualSize.height);
	}
	[appNameToShow drawInRect:appNameRect withFont:[UIFont boldSystemFontOfSize:actualFontSize] lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentLeft];
	
	if (maxRevenue == 0) {
		// nothing of interest to display, stop here
		CGContextRestoreGState(c); // pop context before returning
		return;
	}
	
	NSString *subtitle;
	if (showUnits) {
		subtitle = [NSString stringWithFormat:NSLocalizedString(@"%i days, ∑ = %i sales",nil), [revenues count], (int)totalRevenue];
	} else {
		subtitle = [NSString stringWithFormat:NSLocalizedString(@"%i days, ∑ = %@",nil), [revenues count], [[CurrencyManager sharedManager] baseCurrencyDescriptionForAmount:[NSNumber numberWithFloat:totalRevenue] withFraction:YES]];
	}
	CGRect subtitleRect = CGRectMake(10, maxY + 5, 300, 20);
	[[UIColor darkGrayColor] set];
	[subtitle drawInRect:subtitleRect withFont:[UIFont boldSystemFontOfSize:12.0] lineBreakMode:UILineBreakModeCharacterWrap alignment:UITextAlignmentCenter];
	
	//draw weekend background:
	if ([revenues count] <= 62) {
		CGContextSetAllowsAntialiasing(c, NO);
		float weekendWidth = (maxX - minX) / ([revenues count] - 1);
		NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
		UIColor *shade;
		if (self.appID == nil)
			shade = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.1];
		else
			shade = [UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:0.1];
		[shade set];
		
		int startWeekDay = [[gregorian components:NSWeekdayCalendarUnit fromDate:[[days objectAtIndex:0] date] ] weekday];
		for (int i=0; i < [revenues count]; i++) {
			if ( (startWeekDay + i)%7 == 0 ) { // every Sunday
				float x = minX + ((maxX - minX) / ([revenues count] - 1)) * i;
				float x2 = x + weekendWidth;
				if (x2 > maxX) x2 = maxX;
				CGRect weekendRect = CGRectMake(x, minY - 2, (x2 - x), (maxY - minY) + 3);
				CGContextFillRect(c, weekendRect);
			}
		}
		CGContextSetAllowsAntialiasing(c, YES);
	}
	
    //draw customerprice line
	if( customerpricehaschangedatleastonce )
    {
		[[UIColor colorWithRed:0.0 green:0.4 blue:0.2 alpha:1.0] set];
		[NSLocalizedString(@"/ Customer price (in US$)",nil) drawInRect:CGRectMake(155, 10, 200, 20) withFont:[UIFont boldSystemFontOfSize:12.0] lineBreakMode:UILineBreakModeCharacterWrap alignment:UITextAlignmentLeft];
		[[NSString stringWithFormat:@"%.2f", (float)maxcustomerprice/100.0] drawInRect:CGRectMake(0, minY - 4, minX - 4, 10) withFont:[UIFont boldSystemFontOfSize:10.0] lineBreakMode:UILineBreakModeCharacterWrap alignment:UITextAlignmentRight];
	
		int i = 0;
        float prevX = 0.0;
        CGContextBeginPath(c);
        CGContextSetLineWidth(c, 1.0);
        CGContextSetLineJoin(c, kCGLineJoinRound);
        for (NSNumber *productprice in customerprices) {
            float r = [productprice floatValue];
			
			if( r >= 0.0 )
			{
				float y = maxY - ((r / (float)maxcustomerprice) * (maxY - minY));
				float x = minX + ((maxX - minX) / ([revenues count] - 1)) * i;
				if(prevX == 0.0)
				{
					CGContextMoveToPoint(c, x, y);
				}
				else {
					CGContextAddLineToPoint(c, x, y);
				}
				prevX = x;
            }
            i++;
        }
        CGContextDrawPath(c, kCGPathStroke);
    }
    
    // draw report line
	{
        [graphColor set];
        int i = 0;
        float prevX = 0.0;
        //float prevY = 0.0;
        CGContextBeginPath(c);
        CGContextSetLineWidth(c, 1.0);
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
    }
	
	//draw 7 day average line:
	{
		[[UIColor colorWithRed:0.8 green:0.2 blue:0.2 alpha:1.0] set];
        
#define AVERAGE_LENGTH_IN_DAYS 7
        float   lastsevendays[AVERAGE_LENGTH_IN_DAYS] = {0.0};
        float   lastsevendayssum = 0.0;
        
        int i = 0;
        float prevX = 0.0;
        //float prevY = 0.0;
        CGContextBeginPath(c);
        CGContextSetLineWidth(c, 2.0);
        CGContextSetLineJoin(c, kCGLineJoinRound);
        for (NSNumber *revenue in revenues) 
        {
            float   thisdayrevenue  = [revenue floatValue];
            uint    sevendaysindex  = i%AVERAGE_LENGTH_IN_DAYS;
            
            lastsevendayssum                += (thisdayrevenue - lastsevendays[sevendaysindex]);
            lastsevendays[sevendaysindex]   = thisdayrevenue;
            
            float r = lastsevendayssum / AVERAGE_LENGTH_IN_DAYS;
            float y = maxY - ((r / maxRevenue) * (maxY - minY));
            float x = minX + ((maxX - minX) / ([revenues count] - 1)) * i;
            if (prevX == 0.0) {
                CGContextMoveToPoint(c, x, y);
            }
            else {
                CGContextAddLineToPoint(c, x, y);
            }
            if( i>=AVERAGE_LENGTH_IN_DAYS )
            {
                prevX = x;
            }        //	prevY = y;
            i++;
        }
        CGContextDrawPath(c, kCGPathStroke);
    }
    
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
	
	CGContextRestoreGState(c); // pop context
}


- (void)dealloc 
{
	self.appID = nil;
	self.appName = nil;
    [super dealloc];
}


@end
