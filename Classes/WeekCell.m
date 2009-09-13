/*
 WeekCell.m
 AppSalesMobile
 
 * Copyright (c) 2008, omz:software
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the <organization> nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY omz:software ''AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL <copyright holder> BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "WeekCell.h"
#import "Day.h"

@implementation WeekCell

@synthesize day;
@synthesize maxRevenue;
@synthesize graphColor;

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier {
	if (self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier]) {
		UIColor *calendarBackgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
		UIView *calendarBackgroundView = [[[UIView alloc] initWithFrame:CGRectMake(0,0,45,44)] autorelease];
		calendarBackgroundView.backgroundColor = calendarBackgroundColor;
		calendarBackgroundView.opaque = YES;
		
		dayLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 45, 30)] autorelease];
		dayLabel.textAlignment = UITextAlignmentCenter;
		dayLabel.font = [UIFont boldSystemFontOfSize:22.0];
		dayLabel.backgroundColor = calendarBackgroundColor;
		dayLabel.opaque = YES;
		
		weekdayLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, 27, 45, 14)] autorelease];
		weekdayLabel.textAlignment = UITextAlignmentCenter;
		weekdayLabel.font = [UIFont systemFontOfSize:10.0];
		weekdayLabel.backgroundColor = calendarBackgroundColor;
		weekdayLabel.opaque = YES;
		
		detailsLabel = [[[UILabel alloc] initWithFrame:CGRectMake(50, 27, 250, 14)] autorelease];
		detailsLabel.textColor = [UIColor grayColor];
		detailsLabel.font = [UIFont systemFontOfSize:12.0];
		detailsLabel.textAlignment = UITextAlignmentCenter;
		detailsLabel.opaque = YES;
		
		revenueLabel = [[[UILabel alloc] initWithFrame:CGRectMake(50, 0, 100, 30)] autorelease];
		revenueLabel.font = [UIFont boldSystemFontOfSize:20.0];
		revenueLabel.textAlignment = UITextAlignmentRight;
		revenueLabel.adjustsFontSizeToFitWidth = YES;
		revenueLabel.opaque = YES;
		
		//self.graphColor = [UIColor colorWithRed:0.54 green:0.61 blue:0.67 alpha:1.0]
		self.graphColor = [UIColor colorWithRed:0.45 green:0.79 blue:1.0 alpha:1.0]; //sky
		
		graphView = [[[UIView alloc] initWithFrame:CGRectMake(160, 10, 130, 25)] autorelease];
		graphView.backgroundColor = self.graphColor;
		graphView.opaque = YES;
		
		[self.contentView addSubview:calendarBackgroundView];
		[self.contentView addSubview:dayLabel];
		[self.contentView addSubview:weekdayLabel];
		[self.contentView addSubview:revenueLabel];
		[self.contentView addSubview:graphView];
		[self.contentView addSubview:detailsLabel];
		
		self.maxRevenue = 0;
    }
    return self;
}

- (void)setDay:(Day *)newDay
{
	[newDay retain];
	[day release];
	day = newDay;
	if (day == nil)
		return;
	
	dayLabel.text = [day dayString];
	weekdayLabel.text = [day weekEndDateString];
	revenueLabel.text = [day totalRevenueString];
	detailsLabel.text = [day description];
	
	graphView.frame = CGRectMake(160, 4, 130.0 * (self.maxRevenue ?
												  ([self.day totalRevenueInBaseCurrency] / self.maxRevenue) :
												  0), 21);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated 
{
	[super setSelected:selected animated:animated];
	
	if (selected) {
		dayLabel.textColor = [UIColor whiteColor];
		weekdayLabel.textColor = [UIColor whiteColor];
		revenueLabel.textColor = [UIColor whiteColor];
		graphView.backgroundColor = [UIColor whiteColor];
		detailsLabel.textColor = [UIColor whiteColor];
	}
	else {
		dayLabel.textColor = [self.day weekdayColor];
		weekdayLabel.textColor = [self.day weekdayColor];
		revenueLabel.textColor = [UIColor blackColor];
		graphView.backgroundColor = self.graphColor;
		detailsLabel.textColor = [UIColor grayColor];
	}
	
    // Configure the view for the selected state
}


- (void)dealloc 
{
	self.day = nil;
	self.graphColor = nil;
	
    [super dealloc];
}


@end