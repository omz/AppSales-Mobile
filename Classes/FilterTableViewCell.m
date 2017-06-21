//
//  FilterTableViewCell.m
//  AppSales
//
//  Created by Nicolas Gomollon on 6/20/17.
//
//

#import "FilterTableViewCell.h"

@implementation FilterTableViewCell

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
	return [self initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier];
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier];
	if (self) {
		// Initialization code
	}
	return self;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	if (self.imageView) {
		self.imageView.frame = CGRectMake(10.0f, 9.0f, 26.0f, 26.0f);
	}
	if (self.textLabel) {
		self.textLabel.frame = CGRectMake(self.imageView.image ? 54.0f : 16.0f, 12.0f, 80.0f, 20.5f);
	}
}

@end
