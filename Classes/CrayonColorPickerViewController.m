//
//  CrayonColorPickerViewController.m
//  AppSales
//
//  Created by Ole Zorn on 17.04.10.
//  Copyright 2010 omz:software. All rights reserved.
//

#import "CrayonColorPickerViewController.h"
#import "ColorButton.h"
#import "UIColor+Extensions.h"

@implementation CrayonColorPickerViewController

- (instancetype)initWithSelectedColor:(UIColor *)color {
	selectedColor = color;
	self = [super init];
	if (self) {
		self.modalPresentationStyle = UIModalPresentationPopover;
		self.popoverPresentationController.delegate = self;
		self.preferredContentSize = CGSizeMake(252.0f, 216.0f);
		self.view.backgroundColor = [UIColor clearColor];
	}
	return self;
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
	return UIModalPresentationNone;
}

- (void)loadView {
	[super loadView];
	CGFloat buttonSize = 36.0f;
	NSInteger row = 0;
	NSInteger col = 0;
	for (UIColor *color in [UIColor crayonColorPalette]) {
		ColorButton *button = [ColorButton buttonWithType:UIButtonTypeCustom];
		button.frame = CGRectMake(col * buttonSize, row * buttonSize, buttonSize, buttonSize);
		button.backgroundColor = color;
		[button addTarget:self action:@selector(selectColor:) forControlEvents:UIControlEventTouchUpInside];
		[self.view addSubview:button];
		button.showCheckmark = ((selectedColor != nil) && ([color distanceTo:selectedColor] < 0.1f));
		if (++col >= 7) {
			col = 0;
			row++;
		}
	}
}

- (void)selectColor:(UIButton *)button {
	if (self.delegate && [self.delegate respondsToSelector:@selector(colorPicker:didPickColor:)]) {
		[self.delegate colorPicker:self didPickColor:button.backgroundColor];
	}
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
