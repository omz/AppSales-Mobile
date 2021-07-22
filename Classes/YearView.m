//
//  YearView.m
//  AppSales
//
//  Created by Ole Zorn on 31.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "YearView.h"
#import "DarkModeCheck.h"

@implementation YearView

@synthesize labelsByMonth, footerText, year, delegate;

- (instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		self.backgroundColor = [UIColor clearColor];
		monthRects = [[NSMutableArray alloc] init];
		
		UILongPressGestureRecognizer *recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleInteraction:)];
		recognizer.delegate = self;
		recognizer.minimumPressDuration = 0.07;
		[self addGestureRecognizer:recognizer];
	}
	return self;
}

- (void)handleInteraction:(UILongPressGestureRecognizer *)sender {
	int interactedMonth = -1;
	
	CGPoint location = [sender locationInView:self];
	
	for (int i=0; i<monthRects.count; i++) {
		NSValue* rectObject = [monthRects objectAtIndex:i];
		if ([rectObject isEqual:[NSNull null]]) {
			continue;
		}
		CGRect rect = rectObject.CGRectValue;
		if (CGRectContainsPoint(rect, location)) {
			interactedMonth = i;
			break;
		}
	}
	
	if (sender.state == UIGestureRecognizerStateBegan && interactedMonth != -1) {
		selectedMonth = @(interactedMonth);
		[self setNeedsDisplay];
	} else if (sender.state == UIGestureRecognizerStateEnded) {
		if (interactedMonth != -1 && selectedMonth.intValue == interactedMonth && self.delegate) {
			// Switch month to start at 1
			[self.delegate yearView:self didSelectMonth:interactedMonth + 1];
		}
		selectedMonth = nil;
		[self setNeedsDisplay];
	}
}

- (void)drawRect:(CGRect)rect {
	BOOL iPad = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad;
	CGContextRef c = UIGraphicsGetCurrentContext();
	CGContextSaveGState(c);

	CGFloat margin = 10.0;
	CGContextSetShadowWithColor(c, CGSizeMake(0, 1.0), 6.0, [[UIColor blackColor] CGColor]);
	
	if ([DarkModeCheck deviceIsInDarkMode]) {
		[[UIColor colorWithRed:44.0f/255.0f green:44.0f/255.0f blue:46.0f/255.0f alpha:1.0f] set];
	} else {
		[[UIColor colorWithRed:255.0f/255.0f green:255.0f/255.0f blue:255.0f/255.0f alpha:1.0f] set];
	}
	
	CGContextFillRect(c, CGRectInset(self.bounds, margin, margin));

	CGContextRestoreGState(c);

	CGFloat headerHeight = 52.0;
	CGFloat footerHeight = 42.0;
	CGFloat monthsHeight = self.bounds.size.height - 2 * margin - headerHeight - footerHeight;
	CGFloat singleMonthHeight = monthsHeight / 4;
	CGFloat singleMonthWidth = (self.bounds.size.width - 2 * margin) / 3.0;
	
	if ([DarkModeCheck deviceIsInDarkMode]) {
		CGContextSetRGBFillColor(c, 0.75, 0.75, 0.75, 0.2);
	} else {
		CGContextSetRGBFillColor(c, 0.8, 0.8, 0.8, 1.0);
	}
	
	for (int i=0; i<5; i++) {
		CGFloat y = margin + headerHeight + i * (monthsHeight / 4.0);
		CGContextFillRect(c, CGRectMake(margin, (int)y, self.bounds.size.width - 2 * margin, 1));
	}
	for (int i=1; i<3; i++) {
		CGFloat x = margin + i * ((self.bounds.size.width - 2 * margin) / 3.0);
		CGContextFillRect(c, CGRectMake((int)x, margin + headerHeight, 1, self.bounds.size.height - 2 * margin - headerHeight - footerHeight));
	}
	CGRect yearRect = CGRectMake(margin, margin, self.bounds.size.width - 2 * margin, headerHeight);
	
	if (@available(iOS 13.0, *)) {
		[[UIColor secondarySystemBackgroundColor] set];
	} else {
		[[UIColor colorWithWhite:0.95 alpha:1.0] set];
	}
	
	CGContextFillRect(c, yearRect);
	yearRect.origin.y += 10;
	[[UIColor darkGrayColor] set];
	UIFont *yearFont = [UIFont boldSystemFontOfSize:27];
	NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
	[style setAlignment:NSTextAlignmentCenter];
	
	if (@available(iOS 13.0, *)) {
		[[NSString stringWithFormat:@"%li", (long)year] drawInRect:yearRect withAttributes:@{
			NSFontAttributeName : yearFont,
			NSParagraphStyleAttributeName : style,
			NSForegroundColorAttributeName : [UIColor labelColor]}];
	} else {
		[[NSString stringWithFormat:@"%li", (long)year] drawInRect:yearRect withAttributes:@{
			NSFontAttributeName : yearFont,
			NSParagraphStyleAttributeName : style}];
	}

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

	[monthRects removeAllObjects];
	
	for (int i=0; i<12; i++) {
		CGRect monthRect = CGRectInset(CGRectMake((margin + (i % 3) * singleMonthWidth),
												  (margin + headerHeight + (i / 3) * singleMonthHeight),
												  singleMonthWidth,
												  singleMonthHeight), 7, 5);
		
		if (selectedMonth && selectedMonth.intValue == i) {
			if (@available(iOS 13.0, *)) {
				[[UIColor systemGray2Color] set];
			} else {
				[[UIColor lightGrayColor] set];
			}
			CGContextFillRect(c, CGRectInset(monthRect, -7, -5));
			[[UIColor darkGrayColor] set];
		} else if (currentYear == year && currentMonth == i + 1) {
			if (@available(iOS 13.0, *)) {
				[[UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
					switch (traitCollection.userInterfaceStyle) {
						case UIUserInterfaceStyleDark:
							return [[UIColor systemGray2Color] colorWithAlphaComponent:0.3];
						default:
							return [UIColor colorWithRed:0.698 green:0.804 blue:0.871 alpha:0.3];
					}
				}] set];
			} else {
				[[UIColor colorWithRed:0.698 green:0.804 blue:0.871 alpha:0.3] set];
			}
			CGContextFillRect(c, CGRectInset(monthRect, -7, -5));
			[[UIColor darkGrayColor] set];
		}
		NSDateComponents *monthComponents = [[NSDateComponents alloc] init];
		[monthComponents setMonth:i + 1];
		NSDate *monthDate = [calendar dateFromComponents:monthComponents];
		NSString *month = [monthFormatter stringFromDate:monthDate];
		NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
		style.alignment = NSTextAlignmentLeft;
		
		if (@available(iOS 13.0, *)) {
			[month drawInRect:monthRect withAttributes:@{
				NSFontAttributeName: monthFont,
				NSParagraphStyleAttributeName: style,
				NSForegroundColorAttributeName: [UIColor secondaryLabelColor]}];
		} else {
			[month drawInRect:monthRect withAttributes:@{
				NSFontAttributeName: monthFont,
				NSParagraphStyleAttributeName: style}];
		}

		NSMutableAttributedString *label = labelsByMonth[@(i + 1)];
		if (label) {
			CGSize size = CGSizeMake(FLT_MAX, FLT_MAX);
			float fontSize = maxPaymentFontSize;
			while (size.width > monthRect.size.width) {
				fontSize -= 1.0;
				[label addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:fontSize] range:NSMakeRange(0, label.length)];
				size = [label size];
			}
			CGRect labelRect = CGRectMake(monthRect.origin.x, monthRect.origin.y + monthRect.size.height/2 - size.height/2, monthRect.size.width, size.height);

			NSMutableParagraphStyle *labelStyle = [NSMutableParagraphStyle new];
			labelStyle.alignment = NSTextAlignmentCenter;
			[label addAttributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:fontSize],
			NSParagraphStyleAttributeName: labelStyle} range:NSMakeRange(0, label.length)];
			
			if (@available(iOS 13.0, *)) {
				NSDictionary *currentAttrs = [label attributesAtIndex:0 effectiveRange:nil];
				if (currentAttrs[NSForegroundColorAttributeName] == [UIColor labelColor]) {
					[label addAttributes:@{NSForegroundColorAttributeName: [UIColor labelColor]} range:NSMakeRange(0, label.length)];
				}
			}
			
			[label drawInRect:labelRect];
			
			[monthRects addObject:[NSValue valueWithCGRect:monthRect]];
		} else {
			[monthRects addObject:[NSNull null]];
		}
	}

	CGRect footerRect = CGRectMake(margin, self.bounds.size.height - footerHeight + 3, self.bounds.size.width - 2 * margin, 20);
	NSMutableParagraphStyle *style2 = [NSMutableParagraphStyle new];
	style2.alignment = NSTextAlignmentCenter;
	
	if (@available(iOS 13.0, *)) {
		[self.footerText drawInRect:footerRect withAttributes:@{
			NSFontAttributeName: [UIFont boldSystemFontOfSize:14.0],
			NSParagraphStyleAttributeName: style2,
			NSForegroundColorAttributeName: [UIColor labelColor]}];
	} else {
		[self.footerText drawInRect:footerRect withAttributes:@{
			NSFontAttributeName: [UIFont boldSystemFontOfSize:14.0],
			NSParagraphStyleAttributeName: style2}];
	}
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
	return YES;
}

@end
