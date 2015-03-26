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

- (void)colorPicker:(ColorPickerViewController *)picker didPickColor:(UIColor *)color atIndex:(NSInteger)colorIndex;

@end


@interface ColorPickerViewController : UIViewController {

	NSArray *colors;
	UIColor *selectedColor;
	id<ColorPickerViewControllerDelegate> delegate;
	NSString *name;
	id context;
}

@property (nonatomic, assign) id<ColorPickerViewControllerDelegate> delegate;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) UIColor *selectedColor;
@property (nonatomic, retain) id context;

- (id)initWithColors:(NSArray *)colorArray;

@end

