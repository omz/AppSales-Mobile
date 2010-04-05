//
//  DayOrWeekCell.h
//  AppSalesMobile
//
//  Created by Evan Schoenberg on 4/5/10.
//  Copyright 2010 Evan Schoenberg. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Day;

@interface DayOrWeekCell : UITableViewCell {
	
	UILabel *dayLabel;
	UILabel *weekdayLabel;
	UILabel *revenueLabel;
	UILabel *detailsLabel;
	UIImageView *graphView;
	Day *day;
	float maxRevenue;
	UIColor *graphColor;
	
	NSInteger availableGraphWidth;
}

@property (retain) Day *day;
@property (assign) float maxRevenue;
@property (retain) UIColor *graphColor;

@end
