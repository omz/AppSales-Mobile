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

@implementation DashboardAppCell

@synthesize product, colorButton;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
		CGSize contentSize = self.contentView.bounds.size;
		
		nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(44, 10, contentSize.width - 49, 20)];
		nameLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		nameLabel.lineBreakMode = UILineBreakModeMiddleTruncation;
		nameLabel.font = [UIFont boldSystemFontOfSize:16.0];
		nameLabel.backgroundColor = [UIColor clearColor];
		nameLabel.shadowColor = [UIColor whiteColor];
		nameLabel.highlightedTextColor = [UIColor whiteColor];
		nameLabel.shadowOffset = CGSizeMake(0, 1);
		
		colorButton = [[ColorButton alloc] initWithFrame:CGRectMake(5, 5, 30, 30)];
		colorButton.showOutline = NO;
		colorButton.color = [UIColor grayColor];
		[self.contentView addSubview:colorButton];
		
		iconView = [[AppIconView alloc] initWithFrame:CGRectInset(colorButton.frame, 3, 3)];
		[self.contentView addSubview:iconView];
		[self.contentView addSubview:nameLabel];
		
		self.backgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"CellBackground.png"]] autorelease];
		self.selectedBackgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"CellBackgroundSelected.png"]] autorelease];
    }
    return self;
}

- (void)setProduct:(Product *)newProduct
{
	[newProduct retain];
	[product release];
	product = newProduct;
	
	if (!product) {
		nameLabel.text = NSLocalizedString(@"All Apps", nil);
		colorButton.hidden = YES;
		iconView.productID = nil;
	} else {
		nameLabel.text = [product displayName];
		colorButton.hidden = NO;
		colorButton.color = product.color;
		if (self.product.parentSKU) {
			iconView.productID = nil;
			iconView.image = [UIImage imageNamed:@"InApp.png"];
		} else {
			iconView.productID = self.product.productID;
		}
	}
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated 
{
	[super setHighlighted:highlighted animated:animated];
	colorButton.selected = NO;
	colorButton.highlighted = NO;
	nameLabel.shadowColor = (self.highlighted || self.selected) ? [UIColor blackColor] : [UIColor whiteColor];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated 
{
	[super setSelected:selected animated:animated];
	colorButton.selected = NO;
	colorButton.highlighted = NO;
	nameLabel.shadowColor = (self.highlighted || self.selected) ? [UIColor blackColor] : [UIColor whiteColor];
}

- (void)dealloc
{
	[product release];
	[iconView release];
	[colorButton release];
	[nameLabel release];
	[super dealloc];
}

@end
