//
//  ReportDetailEntryCell.m
//  AppSales
//
//  Created by Ole Zorn on 25.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "ReportDetailEntryCell.h"
#import "DashboardAppCell.h"
#import "AppIconView.h"
#import "Product.h"
#import "CurrencyManager.h"
#import "ReportDetailEntry.h"

@implementation ReportDetailEntryCell

@synthesize entry;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	if (self) {
		CGSize contentSize = self.contentView.bounds.size;
		
		CGFloat iconOrigin = (contentSize.height - kIconSize) / 2.0f;
		iconView = [[AppIconView alloc] initWithFrame:CGRectMake(iconOrigin, iconOrigin, kIconSize, kIconSize)];
		[self.contentView addSubview:iconView];
		
		CGFloat labelOriginX = CGRectGetMaxX(iconView.frame) + iconOrigin;
		revenueLabel = [[UILabel alloc] initWithFrame:CGRectMake(labelOriginX, 0.0f, 82.0f, contentSize.height)];
		revenueLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight;
		revenueLabel.backgroundColor = [UIColor clearColor];
		revenueLabel.font = [UIFont systemFontOfSize:17.0f weight:UIFontWeightRegular];
		revenueLabel.textAlignment = NSTextAlignmentRight;
		revenueLabel.textColor = [UIColor blackColor];
		revenueLabel.adjustsFontSizeToFitWidth = YES;
		[self.contentView addSubview:revenueLabel];
		
		self.separatorInset = UIEdgeInsetsMake(0.0f, labelOriginX, 0.0f, 0.0f);
		
		CGFloat barOriginX = CGRectGetMaxX(revenueLabel.frame) + 8.0f;
		barBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(barOriginX, iconOrigin, contentSize.width - barOriginX - iconOrigin, 17.0f)];
		barBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		barBackgroundView.backgroundColor = [UIColor colorWithWhite:0.8f alpha:1.0f];
		[self.contentView addSubview:barBackgroundView];
		
		barView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 0.0f, CGRectGetHeight(barBackgroundView.frame))];
		barView.backgroundColor = [UIColor colorWithRed:0.541f green:0.612f blue:0.671f alpha:1.0f];
		[barBackgroundView addSubview:barView];
		
		percentageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, barBackgroundView.bounds.size.width - 4.0f, CGRectGetHeight(barBackgroundView.frame))];
		percentageLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
		percentageLabel.backgroundColor = [UIColor clearColor];
		percentageLabel.font = [UIFont systemFontOfSize:11.0f weight:UIFontWeightMedium];
		percentageLabel.textAlignment = NSTextAlignmentRight;
		percentageLabel.textColor = [UIColor whiteColor];
		[barBackgroundView addSubview:percentageLabel];
		
		subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(barOriginX, CGRectGetMaxY(barBackgroundView.frame), CGRectGetWidth(barBackgroundView.frame), contentSize.height - CGRectGetMaxY(barBackgroundView.frame))];
		subtitleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		subtitleLabel.backgroundColor = [UIColor clearColor];
		subtitleLabel.font = [UIFont systemFontOfSize:11.0f weight:UIFontWeightRegular];
		subtitleLabel.textAlignment = NSTextAlignmentLeft;
		subtitleLabel.textColor = [UIColor darkGrayColor];
		[self.contentView addSubview:subtitleLabel];
		
		revenueFormatter = [[NSNumberFormatter alloc] init];
		revenueFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
		revenueFormatter.currencyCode = [CurrencyManager sharedManager].baseCurrency;
		
		percentageFormatter = [[NSNumberFormatter alloc] init];
		percentageFormatter.maximumFractionDigits = 1;
		percentageFormatter.numberStyle = NSNumberFormatterPercentStyle;
		
		self.separatorInset = UIEdgeInsetsMake(0.0f, labelOriginX, 0.0f, 0.0f);
	}
	return self;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	CGFloat percentage = entry.percentage;
	Product *product = entry.product;
	NSString *country = entry.countryCode;
	BOOL hideBar = (!product && (!country || [country isEqualToString:@"WW"]));
	if (!hideBar) {
		percentageLabel.text = [percentageFormatter stringFromNumber:@(percentage)];
		barView.frame = CGRectMake(0.0f, 0.0f, CGRectGetWidth(barBackgroundView.frame) * MAX(percentage, 0.0f), CGRectGetHeight(barBackgroundView.frame));
	}
}

- (void)setEntry:(ReportDetailEntry *)newEntry {
	entry = newEntry;
	
	CGFloat percentage = entry.percentage;
	Product *product = entry.product;
	NSString *country = entry.countryCode;
	BOOL hideBar = (!product && (!country || [country isEqualToString:@"WW"]));
	barBackgroundView.hidden = hideBar;
	barView.hidden = hideBar;
	percentageLabel.hidden = hideBar;
	subtitleLabel.hidden = hideBar;
	
	if (!hideBar) {
		percentageLabel.text = [percentageFormatter stringFromNumber:@(percentage)];
		barView.frame = CGRectMake(0.0f, 0.0f, CGRectGetWidth(barBackgroundView.frame) * MAX(percentage, 0.0f), CGRectGetHeight(barBackgroundView.frame));
	}
	
	if (product) {
		iconView.product = product;
	} else {
		iconView.product = nil;
		iconView.maskEnabled = (country == nil);
		iconView.image = [UIImage imageNamed:(country ?: @"AllApps")];
	}
	
	revenueLabel.text = [revenueFormatter stringFromNumber:@(entry.revenue)];
	subtitleLabel.text = entry.subtitle;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
	[super setSelected:selected animated:animated];
	barBackgroundView.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1.0];
	barView.backgroundColor = [UIColor colorWithRed:0.541 green:0.612 blue:0.671 alpha:1.0];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
	[super setHighlighted:highlighted animated:animated];
	barBackgroundView.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1.0];
	barView.backgroundColor = [UIColor colorWithRed:0.541 green:0.612 blue:0.671 alpha:1.0];
}

@end
