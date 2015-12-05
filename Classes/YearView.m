//
//  YearView.m
//  AppSales
//
//  Created by Ole Zorn on 31.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "YearView.h"

@implementation YearView

@synthesize labelsByMonth, footerText, year;

- (instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		self.backgroundColor = [UIColor clearColor];
	}
	return self;
}

- (void)drawRect:(CGRect)rect {
	BOOL iPad = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad;
	CGContextRef c = UIGraphicsGetCurrentContext();
	CGContextSaveGState(c);
	
	CGFloat margin = 10.0;
	CGContextSetShadowWithColor(c, CGSizeMake(0, 1.0), 6.0, [[UIColor blackColor] CGColor]);
	CGContextSetRGBFillColor(c, 1.0, 1.0, 1.0, 1.0);
	CGContextFillRect(c, CGRectInset(self.bounds, margin, margin));
	
	CGContextRestoreGState(c);
	
	CGFloat headerHeight = 52.0;
	CGFloat footerHeight = 42.0;
	CGFloat monthsHeight = self.bounds.size.height - 2 * margin - headerHeight - footerHeight;
	CGFloat singleMonthHeight = monthsHeight / 4;
	CGFloat singleMonthWidth = (self.bounds.size.width - 2 * margin) / 3.0;
	CGContextSetRGBFillColor(c, 0.8, 0.8, 0.8, 1.0);
	for (int i=0; i<5; i++) {
		CGFloat y = margin + headerHeight + i * (monthsHeight / 4.0);
		CGContextFillRect(c, CGRectMake(margin, (int)y, self.bounds.size.width - 2 * margin, 1));
	}
	for (int i=1; i<3; i++) {
		CGFloat x = margin + i * ((self.bounds.size.width - 2 * margin) / 3.0);
		CGContextFillRect(c, CGRectMake((int)x, margin + headerHeight, 1, self.bounds.size.height - 2 * margin - headerHeight - footerHeight));
	}
	CGRect yearRect = CGRectMake(margin, margin, self.bounds.size.width - 2 * margin, headerHeight);
	[[UIColor colorWithWhite:0.95 alpha:1.0] set];
	CGContextFillRect(c, yearRect);
	yearRect.origin.y += 10;
	[[UIColor darkGrayColor] set];
	UIFont *yearFont = [UIFont boldSystemFontOfSize:27];
	NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
	[style setAlignment:NSTextAlignmentCenter];
	[[NSString stringWithFormat:@"%li", (long)year] drawInRect:yearRect withAttributes:@{NSFontAttributeName : yearFont,
																				  NSParagraphStyleAttributeName : style}];
	
	NSDateFormatter *monthFormatter = [[NSDateFormatter alloc] init];
	[monthFormatter setDateFormat:@"MMMM"];
	[monthFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
	[calendar setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	NSDateComponents *currentDateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:[NSDate date]];
	NSInteger currentYear = [currentDateComponents year];
	NSInteger currentMonth = [currentDateComponents month];
	
	UIFont *monthFont = [UIFont systemFontOfSize:iPad ? 24 : 12];
	CGFloat maxPaymentFontSize = iPad ? 24 : 16;
	
	for (int i=0; i<12; i++) {
		CGRect monthRect = CGRectInset(CGRectMake((margin + (i % 3) * singleMonthWidth), 
												  (margin + headerHeight + (i / 3) * singleMonthHeight), 
												  singleMonthWidth,
												  singleMonthHeight), 7, 5);
		if (currentYear == year && currentMonth == i + 1) {
			[[UIColor colorWithRed:0.698 green:0.804 blue:0.871 alpha:0.3] set];
			CGContextFillRect(c, CGRectInset(monthRect, -7, -5));
			[[UIColor darkGrayColor] set];
		}
		NSDateComponents *monthComponents = [[NSDateComponents alloc] init];
		[monthComponents setMonth:i + 1];
		NSDate *monthDate = [calendar dateFromComponents:monthComponents];
		NSString *month = [monthFormatter stringFromDate:monthDate];
		NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
		style.alignment = NSTextAlignmentLeft;
		[month drawInRect:monthRect withAttributes:@{NSFontAttributeName: monthFont,
													 NSParagraphStyleAttributeName: style}];
		
		NSString *label = labelsByMonth[@(i + 1)];
		if (label) {
			CGSize size = CGSizeMake(FLT_MAX, FLT_MAX);
			float fontSize = maxPaymentFontSize;
			while (size.width > monthRect.size.width) {
				fontSize -= 1.0;
				size = [label sizeWithAttributes:@{NSFontAttributeName : [UIFont boldSystemFontOfSize:fontSize]}];
			}
			CGRect labelRect = CGRectMake(monthRect.origin.x, monthRect.origin.y + monthRect.size.height/2 - size.height/2, monthRect.size.width, size.height);
			
			NSMutableParagraphStyle *labelStyle = [NSMutableParagraphStyle new];
			labelStyle.alignment = NSTextAlignmentCenter;
			[label drawInRect:labelRect withAttributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:fontSize],
														 NSParagraphStyleAttributeName: labelStyle}];
		}
	}
	
	CGRect footerRect = CGRectMake(margin, self.bounds.size.height - footerHeight + 3, self.bounds.size.width - 2 * margin, 20);
	NSMutableParagraphStyle *style2 = [NSMutableParagraphStyle new];
	style2.alignment = NSTextAlignmentCenter;
	[self.footerText drawInRect:footerRect withAttributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:14.0],
															NSParagraphStyleAttributeName: style2}];
	
}


@end
