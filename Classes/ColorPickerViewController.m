//
//  ColorPickerViewController.m
//  AppSales
//
//  Created by Ole Zorn on 17.04.10.
//  Copyright 2010 omz:software. All rights reserved.
//

#import "ColorPickerViewController.h"
#import "ColorButton.h"
#import "UIColor+Extensions.h"

@implementation ColorPickerViewController

@synthesize delegate, name, selectedColor, context;

- (id)initWithColors:(NSArray *)colorArray {
	if (!(self = [super initWithNibName:nil bundle:nil])) return nil;
	colors = colorArray;
	return self;
}

- (void)loadView {
	[super loadView];
	self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
	CGFloat height = self.view.bounds.size.height;
	CGFloat rowHeight = 35.0;
	int row = 0;
	int col = 0;
	for (UIColor *color in colors) {
		CGRect buttonFrame = CGRectMake(col * 40, height - (row+1) * rowHeight, 40, rowHeight);
		ColorButton *button = [ColorButton buttonWithType:UIButtonTypeCustom];
		button.showOutline = YES;
		button.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
		button.frame = buttonFrame;
		button.color = color;
		[button addTarget:self action:@selector(selectColor:) forControlEvents:UIControlEventTouchUpInside];
		[self.view addSubview:button];
		col++;
		if (col >= 8) {
			col = 0;
			row++;
		}
	}
	
}

- (void)selectColor:(id)sender {
	ColorButton *button = (ColorButton *)sender;
	UIColor *pickedColor = button.color;
	if (delegate && [delegate respondsToSelector:@selector(colorPicker:didPickColor:atIndex:)]) {
		[delegate colorPicker:self didPickColor:pickedColor atIndex:[colors indexOfObject:pickedColor]];
	}
	self.selectedColor = pickedColor;
}



@end
