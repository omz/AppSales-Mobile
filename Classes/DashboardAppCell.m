//
//  DashboardAppCell.m
//  AppSales
//
//  Created by Ole Zorn on 19.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "DashboardAppCell.h"
#import "ColorButton.h"
#import "Product.h"
#import "IconManager.h"
#import "AppIconView.h"

CGFloat const kColorWidth = 4.0f;
CGFloat const kIconSize = 30.0f;
CGFloat const kIconPadding = 12.0f;
CGFloat const kLabelPadding = 10.0f;

@implementation DashboardAppCell

@synthesize product;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	if (self) {
		CGSize contentSize = self.contentView.bounds.size;
		
		colorView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, kColorWidth, contentSize.height)];
		colorView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
		colorView.backgroundColor = [UIColor grayColor];
		[self.contentView addSubview:colorView];
		
		CGFloat iconOriginY = (contentSize.height - kIconSize) / 2.0f;
		iconView = [[AppIconView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(colorView.frame) + kIconPadding, iconOriginY, kIconSize, kIconSize)];
		[self.contentView addSubview:iconView];
		
		CGFloat labelOriginX = CGRectGetMaxX(iconView.frame) + kIconPadding + 1.0f;
		nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(labelOriginX, 0.0f, contentSize.width - labelOriginX - kLabelPadding, contentSize.height)];
		nameLabel.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
		nameLabel.backgroundColor = [UIColor clearColor];
		nameLabel.font = [UIFont systemFontOfSize:17.0f];
		nameLabel.textAlignment = NSTextAlignmentLeft;
		nameLabel.textColor = [UIColor blackColor];
		[self.contentView addSubview:nameLabel];
	}
	return self;
}

- (void)setProduct:(Product *)_product {
	product = _product;
	
	self.separatorInset = UIEdgeInsetsMake(0.0f, CGRectGetMaxX(iconView.frame) + kIconPadding + 1.0f, 0.0f, 0.0f);
	
	CGSize contentSize = self.contentView.bounds.size;
	CGFloat labelOriginX = (product != nil) ? (CGRectGetMaxX(iconView.frame) + kIconPadding + 1.0f) : 15.0f;
	nameLabel.frame = CGRectMake(labelOriginX, 0.0f, contentSize.width - labelOriginX - kLabelPadding, contentSize.height);
	
	nameLabel.text = product.displayName ?: NSLocalizedString(@"All Apps", nil);
	colorView.hidden = (product == nil);
	colorView.backgroundColor = product.color;
	iconView.product = product;
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated  {
	[super setHighlighted:highlighted animated:animated];
	colorView.backgroundColor = product.color;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated  {
	[super setSelected:selected animated:animated];
	colorView.backgroundColor = product.color;
}

@end
