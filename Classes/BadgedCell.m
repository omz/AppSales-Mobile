//
//  BadgedCell.m
//  AppSales
//
//  Created by Ole Zorn on 01.08.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "BadgedCell.h"
#import "UIImage+Tinting.h"

@implementation BadgedCell

@synthesize badgeCount;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
		badgeView = [[UIImageView alloc] initWithFrame:CGRectMake(self.contentView.bounds.size.width - 32 - 10, self.contentView.bounds.size.height * 0.5 - 10, 32, 20)];
		badgeView.image = [UIImage imageNamed:@"Badge.png"];
		badgeView.highlightedImage = [UIImage as_tintedImageNamed:@"Badge.png" color:[UIColor whiteColor]];
		badgeView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
		badgeLabel = [[UILabel alloc] initWithFrame:CGRectInset(badgeView.bounds, 4, 0)];
		badgeLabel.adjustsFontSizeToFitWidth = YES;
		badgeLabel.backgroundColor = [UIColor clearColor];
		badgeLabel.textColor = [UIColor whiteColor];
		badgeLabel.textAlignment = UITextAlignmentCenter;
		badgeLabel.font = [UIFont boldSystemFontOfSize:14.0];
		badgeLabel.highlightedTextColor = [UIColor colorWithRed:0.008 green:0.435 blue:0.929 alpha:1.0];
		[badgeView addSubview:badgeLabel];
		badgeView.hidden = YES;
		[self.contentView addSubview:badgeView];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
	[super setSelected:selected animated:animated];
}

- (void)setBadgeCount:(NSInteger)count
{
	badgeCount = count;
	if (badgeCount == 0) {
		badgeView.hidden = YES;
	} else {
		badgeLabel.text = [NSString stringWithFormat:@"%i", badgeCount];
		badgeView.hidden = NO;
	}
}

- (void)dealloc
{
	[badgeView release];
	[badgeLabel release];
	[super dealloc];
}

@end
