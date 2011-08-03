//
//  ReportDetailEntryCell.m
//  AppSales
//
//  Created by Ole Zorn on 25.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "ReportDetailEntryCell.h"
#import "AppIconView.h"
#import "Product.h"
#import "CurrencyManager.h"
#import "ReportDetailEntry.h"

@implementation ReportDetailEntryCell

@synthesize entry;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	if (self) {
		//self.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
		
		iconView = [[AppIconView alloc] initWithFrame:CGRectMake(8, 8, 24, 24)];
		[self.contentView addSubview:iconView];
		
		revenueLabel = [[UILabel alloc] initWithFrame:CGRectMake(40, 4, 82, 30)];
		revenueLabel.font = [UIFont boldSystemFontOfSize:17.0];
		revenueLabel.backgroundColor = [UIColor clearColor];
		revenueLabel.shadowColor = [UIColor whiteColor];
		revenueLabel.shadowOffset = CGSizeMake(0, 1);
		revenueLabel.highlightedTextColor = [UIColor whiteColor];
		revenueLabel.adjustsFontSizeToFitWidth = YES;
		revenueLabel.textAlignment = UITextAlignmentRight;
		[self.contentView addSubview:revenueLabel];
		
		barBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(130, 5, 180, 17)];
		barBackgroundView.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1.0];
		barBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		[self.contentView addSubview:barBackgroundView];
		
		barView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 50, 17)];
		barView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
		barView.backgroundColor = [UIColor colorWithRed:0.541 green:0.612 blue:0.671 alpha:1.0];
		[barBackgroundView addSubview:barView];
		
		percentageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, barBackgroundView.bounds.size.width - 2, 17)];
		percentageLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
		percentageLabel.textAlignment = UITextAlignmentRight;
		percentageLabel.backgroundColor = [UIColor clearColor];
		percentageLabel.font = [UIFont boldSystemFontOfSize:11.0];
		percentageLabel.textColor = [UIColor whiteColor];
		[barBackgroundView addSubview:percentageLabel];
		
		subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(130, 24, 147, 12)];
		subtitleLabel.backgroundColor = [UIColor clearColor];
		subtitleLabel.font = [UIFont systemFontOfSize:11.0];
		subtitleLabel.textColor = [UIColor darkGrayColor];
		subtitleLabel.highlightedTextColor = [UIColor whiteColor];
		[self.contentView addSubview:subtitleLabel];
		
		revenueFormatter = [[NSNumberFormatter alloc] init];
		[revenueFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
		[revenueFormatter setMinimumFractionDigits:2];
		[revenueFormatter setMaximumFractionDigits:2];
		
		percentageFormatter = [[NSNumberFormatter alloc] init];
		[percentageFormatter setMaximumFractionDigits:1];
		[percentageFormatter setNumberStyle:NSNumberFormatterPercentStyle];
		
		self.backgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"CellBackground.png"]] autorelease];
		self.selectedBackgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"CellBackgroundSelected.png"]] autorelease];
	}
	return self;
}

- (void)setEntry:(ReportDetailEntry *)newEntry
{
	[newEntry retain];
	[entry release];
	entry = newEntry;
	
	NSString *revenueString = [revenueFormatter stringFromNumber:[NSNumber numberWithFloat:entry.revenue]];
	revenueLabel.text = [NSString stringWithFormat:@"%@%@", [[CurrencyManager sharedManager] baseCurrencyDescription], revenueString];
	
	float percentage = entry.percentage;
	Product *product = entry.product;
	NSString *country = entry.country;
	BOOL hideBar = (!product && (!country || [country isEqualToString:@"world"]));
	barBackgroundView.hidden = hideBar;
	barView.hidden = hideBar;
	percentageLabel.hidden = hideBar;
	subtitleLabel.hidden = hideBar;
	
	if (!hideBar) {
		percentageLabel.text = [percentageFormatter stringFromNumber:[NSNumber numberWithFloat:percentage]];
		barView.frame = CGRectMake(0, 0, barBackgroundView.bounds.size.width * percentage, 17);
	}
	
	if (product) {
		iconView.productID = product.productID;
	} else {
		iconView.productID = nil;
		if (country) {
			NSString *flagImageName = [NSString stringWithFormat:@"%@.png", [country lowercaseString]];
			UIImage *flagImage = [UIImage imageNamed:flagImageName];
			iconView.image = flagImage;
		} else {
			iconView.image = [UIImage imageNamed:@"AllApps.png"];
		}
	}
	subtitleLabel.text = entry.subtitle;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
	[super setSelected:selected animated:animated];
	barBackgroundView.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1.0];
	barView.backgroundColor = [UIColor colorWithRed:0.541 green:0.612 blue:0.671 alpha:1.0];
	revenueLabel.shadowColor = [UIColor blackColor];
	revenueLabel.shadowColor = (self.highlighted || self.selected) ? [UIColor blackColor] : [UIColor whiteColor];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
	[super setHighlighted:highlighted animated:animated];
	barBackgroundView.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1.0];
	barView.backgroundColor = [UIColor colorWithRed:0.541 green:0.612 blue:0.671 alpha:1.0];
	revenueLabel.shadowColor = (self.highlighted || self.selected) ? [UIColor blackColor] : [UIColor whiteColor];
}

- (void)dealloc
{
	[entry release];
	[iconView release];
	[revenueLabel release];
	[barBackgroundView release];
	[barView release];
	[percentageLabel release];
	[subtitleLabel release];
	[revenueFormatter release];
	[percentageFormatter release];
	[super dealloc];
}

@end
