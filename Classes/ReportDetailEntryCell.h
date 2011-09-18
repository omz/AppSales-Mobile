//
//  ReportDetailEntryCell.h
//  AppSales
//
//  Created by Ole Zorn on 25.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AppIconView, ReportDetailEntry;

@interface ReportDetailEntryCell : UITableViewCell {

	ReportDetailEntry *entry;
	
	NSNumberFormatter *revenueFormatter;
	NSNumberFormatter *percentageFormatter;
	
	AppIconView *iconView;
	UILabel *revenueLabel;
	UIView *barBackgroundView;
	UIView *barView;
	UILabel *percentageLabel;
	UILabel *subtitleLabel;
}

@property (nonatomic, retain) ReportDetailEntry *entry;

@end
