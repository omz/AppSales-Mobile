//
//  FilterDetailTableViewCell.m
//  AppSales
//
//  Created by Nicolas Gomollon on 6/21/17.
//
//

#import "FilterDetailTableViewCell.h"

@implementation FilterDetailTableViewCell

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
	return [self initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
	if (self) {
		// Initialization code
	}
	return self;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	if (self.detailTextLabel) {
		self.detailTextLabel.textColor = [UIColor grayColor];
	}
}

@end
