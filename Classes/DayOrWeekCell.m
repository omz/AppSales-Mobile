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
	if ((self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier])) {
		UIColor *calendarBackgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
		UIView *calendarBackgroundView = [[[UIView alloc] initWithFrame:CGRectMake(0,0,45,44)] autorelease];
		calendarBackgroundView.backgroundColor = calendarBackgroundColor;
        
        UIColor *whiteColor = [UIColor whiteColor];
		
		dayLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 45, 30)];
		dayLabel.textAlignment = UITextAlignmentCenter;
		dayLabel.font = [UIFont boldSystemFontOfSize:22.0];
		dayLabel.backgroundColor = calendarBackgroundColor;
		dayLabel.highlightedTextColor = whiteColor;
		
		weekdayLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 27, 45, 14)];
		weekdayLabel.textAlignment = UITextAlignmentCenter;
		weekdayLabel.font = [UIFont systemFontOfSize:10.0];
		weekdayLabel.highlightedTextColor = whiteColor;
		weekdayLabel.backgroundColor = calendarBackgroundColor;
		
		revenueLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 0, 100, 30)];
		revenueLabel.font = [UIFont boldSystemFontOfSize:20.0];
		revenueLabel.textAlignment = UITextAlignmentRight;
		revenueLabel.backgroundColor = whiteColor;
		revenueLabel.highlightedTextColor = whiteColor;
		revenueLabel.adjustsFontSizeToFitWidth = YES;
		
		detailsLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 27, 250, 14)];
		detailsLabel.textColor = [UIColor grayColor];
		detailsLabel.backgroundColor = whiteColor;
		detailsLabel.font = [UIFont systemFontOfSize:12.0];
		detailsLabel.highlightedTextColor = [UIColor whiteColor];
		detailsLabel.textAlignment = UITextAlignmentCenter;
				
		graphView = [[UIImageView alloc] initWithFrame:CGRectMake(160, 0, 130, 20)];
		
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
	[day release];
	[graphColor release];
    [dayLabel release];
	[weekdayLabel release];
    [revenueLabel release];
	[detailsLabel release];
    [graphView release];

    [super dealloc];
}


@end
