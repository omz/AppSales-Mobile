//
//  BadgedCell.m
//  AppSales
//
//  Created by Ole Zorn on 01.08.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "BadgedCell.h"
#import "DashboardAppCell.h"
#import "AppIconView.h"
#import "Product.h"
#import "UIImage+Tinting.h"
#import "DarkModeCheck.h"

CGFloat const kBadgePadding = 6.0f;

@implementation BadgedCell

@synthesize product, imageName, badgeCount;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	if (self) {
		if (@available(iOS 13.0, *)) {
			self.backgroundColor = [UIColor secondarySystemGroupedBackgroundColor];
		}
		
		self.textLabel.backgroundColor = [UIColor clearColor];
		self.textLabel.translatesAutoresizingMaskIntoConstraints = NO;
		
		[self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[textLabel]|"
																				 options:0
																				 metrics:nil
																				   views:@{@"textLabel": self.textLabel}]];
		
		textLabelLeftConstraint = [NSLayoutConstraint constraintWithItem:self.textLabel
																	 attribute:NSLayoutAttributeLeft
																	 relatedBy:NSLayoutRelationEqual
																		toItem:self.imageView
																	 attribute:NSLayoutAttributeRight
																	multiplier:1.0f
																	  constant:(self.layoutMargins.left * 2.0f)];
		
		textLabelLeftMarginConstraint = [NSLayoutConstraint constraintWithItem:self.textLabel
															   attribute:NSLayoutAttributeLeft
															   relatedBy:NSLayoutRelationEqual
																  toItem:self.contentView
															   attribute:NSLayoutAttributeLeftMargin
															  multiplier:1.0f
																constant:0.0f];
		
		[self.contentView addConstraint:textLabelLeftMarginConstraint];
		
		badgeView = [[UIImageView alloc] init];
		[self updateBadgeImage];
		badgeView.highlightedImage = [[UIImage as_tintedImageNamed:@"Badge" color:[UIColor whiteColor]] resizableImageWithCapInsets:UIEdgeInsetsMake(9.0f, 9.0f, 9.0f, 9.0f) resizingMode:UIImageResizingModeTile];
		badgeView.translatesAutoresizingMaskIntoConstraints = NO;
		badgeView.hidden = YES;
		[self.contentView addSubview:badgeView];
		
		[self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:badgeView
																	 attribute:NSLayoutAttributeCenterY
																	 relatedBy:NSLayoutRelationEqual
																		toItem:self.contentView
																	 attribute:NSLayoutAttributeCenterY
																	multiplier:1.0f
																	  constant:0.0f]];
		
		[self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:badgeView
																	 attribute:NSLayoutAttributeHeight
																	 relatedBy:NSLayoutRelationEqual
																		toItem:nil
																	 attribute:NSLayoutAttributeNotAnAttribute
																	multiplier:1.0f
																	  constant:20.0f]];
		
		[self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:badgeView
																	 attribute:NSLayoutAttributeLeft
																	 relatedBy:NSLayoutRelationEqual
																		toItem:self.textLabel
																	 attribute:NSLayoutAttributeRight
																	multiplier:1.0f
																	  constant:kLabelPadding]];
		
		badgeViewRightConstraint = [NSLayoutConstraint constraintWithItem:badgeView
																attribute:NSLayoutAttributeRight
																relatedBy:NSLayoutRelationEqual
																   toItem:self.contentView
																attribute:NSLayoutAttributeRight
															   multiplier:1.0f
																 constant:-8.0f];
		
		badgeViewRightMarginConstraint = [NSLayoutConstraint constraintWithItem:badgeView
																	  attribute:NSLayoutAttributeRight
																	  relatedBy:NSLayoutRelationEqual
																		 toItem:self.contentView
																	  attribute:NSLayoutAttributeRightMargin
																	 multiplier:1.0f
																	   constant:0.0f];
		
		[self.contentView addConstraint:(self.accessoryType == UITableViewCellAccessoryNone) ? badgeViewRightMarginConstraint : badgeViewRightConstraint];
		
		badgeViewWidthConstraint = [NSLayoutConstraint constraintWithItem:badgeView
																attribute:NSLayoutAttributeWidth
																relatedBy:NSLayoutRelationEqual
																   toItem:nil
																attribute:NSLayoutAttributeNotAnAttribute
															   multiplier:1.0f
																 constant:0.0f];
		[self.contentView addConstraint:badgeViewWidthConstraint];
		
		badgeLabel = [[UILabel alloc] init];
		badgeLabel.backgroundColor = [UIColor clearColor];
		badgeLabel.textColor = [UIColor whiteColor];
		badgeLabel.highlightedTextColor = [UIColor colorWithRed:2.0f/255.0f green:111.0f/255.0f blue:237.0f/255.0f alpha:1.0f];
		badgeLabel.textAlignment = NSTextAlignmentCenter;
		badgeLabel.font = [UIFont boldSystemFontOfSize:14.0f];
		badgeLabel.translatesAutoresizingMaskIntoConstraints = NO;
		[badgeView addSubview:badgeLabel];
		
		[badgeView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[badgeLabel]|"
																		  options:0
																		  metrics:nil
																			views:@{@"badgeLabel": badgeLabel}]];
		
		[badgeView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[badgeLabel]|"
																		  options:0
																		  metrics:nil
																			views:@{@"badgeLabel": badgeLabel}]];
		
		numberFormatter = [[NSNumberFormatter alloc] init];
		numberFormatter.locale = [NSLocale currentLocale];
		numberFormatter.formatterBehavior = NSNumberFormatterBehavior10_4;
		numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
		numberFormatter.maximumFractionDigits = 0;
		numberFormatter.minimumFractionDigits = 0;
	}
	return self;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
	[super traitCollectionDidChange:previousTraitCollection];
	self.imageName = imageName;
	[self updateBadgeImage];
}

- (void)setAccessoryType:(UITableViewCellAccessoryType)accessoryType {
	[super setAccessoryType:accessoryType];
	[self.contentView removeConstraints:@[badgeViewRightConstraint, badgeViewRightMarginConstraint]];
	[self.contentView addConstraint:(self.accessoryType == UITableViewCellAccessoryNone) ? badgeViewRightMarginConstraint : badgeViewRightConstraint];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
	[super setSelected:selected animated:animated];
	self.textLabel.backgroundColor = [UIColor clearColor];
}

- (void)setProduct:(Product *)_product {
	[super setProduct:_product];
	self.separatorInset = UIEdgeInsetsMake(0.0f, CGRectGetMaxX(iconView.frame) + kIconPadding + 1.0f, 0.0f, 0.0f);
	CGRect nameLabelFrame = nameLabel.frame;
	nameLabelFrame.size.width -= badgeViewWidthConstraint.constant;
	nameLabel.frame = nameLabelFrame;
	colorView.hidden = YES;
}

- (void)setImageName:(NSString *)_imageName {
	imageName = _imageName;
	if (imageName != nil) {
		if ([DarkModeCheck deviceIsInDarkMode]) {
			self.imageView.image = [UIImage as_tintedImageNamed:imageName color:[UIColor colorWithWhite:1.0 alpha:0.4]];
		} else {
			self.imageView.image = [UIImage imageNamed:imageName];
		}
	} else {
		self.imageView.image = nil;
	}
	self.imageView.highlightedImage = (imageName != nil) ? [UIImage as_tintedImageNamed:imageName color:[UIColor whiteColor]] : nil;
	[self.contentView removeConstraints:@[textLabelLeftConstraint, textLabelLeftMarginConstraint]];
	[self.contentView addConstraint:(imageName == nil) ? textLabelLeftMarginConstraint : textLabelLeftConstraint];
}

- (void)updateBadgeImage {
	if ([DarkModeCheck deviceIsInDarkMode]) {
		badgeView.image = [[UIImage as_tintedImageNamed:@"Badge" color:[UIColor colorWithWhite:0.0 alpha:0.5]] resizableImageWithCapInsets:UIEdgeInsetsMake(9.0f, 9.0f, 9.0f, 9.0f) resizingMode:UIImageResizingModeTile];
	} else {
		badgeView.image = [[UIImage imageNamed:@"Badge"] resizableImageWithCapInsets:UIEdgeInsetsMake(9.0f, 9.0f, 9.0f, 9.0f) resizingMode:UIImageResizingModeTile];
	}
}

- (void)setBadgeCount:(NSInteger)_badgeCount {
	badgeCount = _badgeCount;
	if (badgeCount == 0) {
		badgeLabel.text = nil;
		badgeViewWidthConstraint.constant = 0.0f;
	} else {
		badgeLabel.text = [numberFormatter stringFromNumber:@(badgeCount)];
		CGFloat badgeWidth = kBadgePadding + (9.0f * @(badgeCount).description.length) + kBadgePadding;
		badgeViewWidthConstraint.constant = MAX(badgeWidth, 32.0f);
	}
	badgeView.hidden = (badgeCount == 0);
	self.textLabel.backgroundColor = [UIColor clearColor];
}

@end
