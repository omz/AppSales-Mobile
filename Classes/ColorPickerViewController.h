//
//  ColorPickerViewController.h
//  AppSales
//
//  Created by Ole Zorn on 17.04.10.
//  Copyright 2010 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ColorPickerViewController;

@protocol ColorPickerViewControllerDelegate <NSObject>

- (void)colorPicker:(ColorPickerViewController *)picker didPickColor:(UIColor *)color atIndex:(int)colorIndex;

@end


@interface ColorPickerViewController : UIViewController {

	NSArray *colors;
	UIColor *selectedColor;
	id<ColorPickerViewControllerDelegate> __weak delegate;
	NSString *name;
	id context;
}

@property (nonatomic, weak) id<ColorPickerViewControllerDelegate> delegate;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) UIColor *selectedColor;
@property (nonatomic, strong) id context;

- (id)initWithColors:(NSArray *)colorArray;

@end

