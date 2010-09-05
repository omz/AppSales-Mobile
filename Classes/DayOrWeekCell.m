//
//  DayOrWeekCell.m
//  AppSalesMobile
//
//  Created by Evan Schoenberg on 4/5/10.
//  Copyright 2010 Evan Schoenberg. All rights reserved.
//

#import "DayOrWeekCell.h"
#import "Day.h"


@implementation DayOrWeekCell

@synthesize maxRevenue;
@synthesize graphColor;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if (self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier]) {
		UIColor *calendarBackgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
		UIView *calendarBackgroundView = [[[UIView alloc] initWithFrame:CGRectMake(0,0,45,44)] autorelease];
		calendarBackgroundView.backgroundColor = calendarBackgroundColor;
		
		dayLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 45, 30)] autorelease];
		dayLabel.textAlignment = UITextAlignmentCenter;
		dayLabel.font = [UIFont boldSystemFontOfSize:22.0];
		dayLabel.backgroundColor = calendarBackgroundColor;
		dayLabel.highlightedTextColor = [UIColor whiteColor];
		dayLabel.opaque = YES;
		
		weekdayLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, 27, 45, 14)] autorelease];
		weekdayLabel.textAlignment = UITextAlignmentCenter;
		weekdayLabel.font = [UIFont systemFontOfSize:10.0];
		weekdayLabel.highlightedTextColor = [UIColor whiteColor];
		weekdayLabel.backgroundColor = calendarBackgroundColor;
		weekdayLabel.opaque = YES;
		
		revenueLabel = [[[UILabel alloc] initWithFrame:CGRectMake(50, 0, 100, 30)] autorelease];
		revenueLabel.font = [UIFont boldSystemFontOfSize:20.0];
		revenueLabel.textAlignment = UITextAlignmentRight;
		revenueLabel.backgroundColor = [UIColor whiteColor];
		revenueLabel.highlightedTextColor = [UIColor whiteColor];
		revenueLabel.adjustsFontSizeToFitWidth = YES;
		revenueLabel.opaque = YES;
		
		detailsLabel = [[[UILabel alloc] initWithFrame:CGRectMake(50, 27, 250, 14)] autorelease];
		detailsLabel.textColor = [UIColor grayColor];
		detailsLabel.backgroundColor = [UIColor whiteColor];
		detailsLabel.opaque = YES;
		detailsLabel.font = [UIFont systemFontOfSize:12.0];
		detailsLabel.highlightedTextColor = [UIColor whiteColor];
		detailsLabel.textAlignment = UITextAlignmentCenter;
				
		graphView = [[[UIImageView alloc] initWithFrame:CGRectMake(160, 0, 130, 20)] autorelease];
		graphView.opaque = YES;
		
		[self.contentView addSubview:calendarBackgroundView];
		[self.contentView addSubview:dayLabel];
		[self.contentView addSubview:weekdayLabel];
		[self.contentView addSubview:revenueLabel];
		[self.contentView addSubview:graphView];
		[self.contentView addSubview:detailsLabel];
		
		self.maxRevenue = 0;
		availableGraphWidth = 130;
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier {
	return [self initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
}

- (void)updateGraphWidth
{
	graphView.frame = CGRectMake(160, 4, availableGraphWidth * (self.maxRevenue ?
																([self.day totalRevenueInBaseCurrency] / self.maxRevenue) :
																0), 21);	
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	const NSInteger rightSideMarginForAccessoryView = 30;
	float width = CGRectGetWidth(self.contentView.frame) - rightSideMarginForAccessoryView;
	
	const NSInteger dayWidth = 45;
	dayLabel.frame = CGRectMake(0, 0, dayWidth, 30);
	weekdayLabel.frame = CGRectMake(0, 27, dayWidth, 14);	
	width -= dayWidth;
	
	const NSInteger dayToRevenueMargin = 5;
	width -= dayToRevenueMargin;
	
	const NSInteger revenueWidth = 100;
	revenueLabel.frame = CGRectMake(50, 0, revenueWidth, 30);
	
	/* Details starts next to the day/weekday, so size before subtracting the width of the revenueLabel */
	detailsLabel.frame = CGRectMake(50, 27, width, 14);
	width -= revenueWidth;
	
	availableGraphWidth = width;
	[self updateGraphWidth];
}

- (Day*) day {
	return day;
}

- (void)setDay:(Day *)newDay
{
	[newDay retain];
	[day release];
	day = newDay;
	if (day == nil)
		return;
	
	dayLabel.text = [day dayString];
	revenueLabel.text = [day totalRevenueString];
	detailsLabel.text = [day description];
	[self updateGraphWidth];
}

- (void)dealloc 
{
	self.day = nil;
	self.graphColor = nil;
    [super dealloc];
}


@end
