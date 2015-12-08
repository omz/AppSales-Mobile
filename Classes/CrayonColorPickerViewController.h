//
//  CrayonColorPickerViewController.h
//  AppSales
//
//  Created by Ole Zorn on 17.04.10.
//  Copyright 2010 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CrayonColorPickerViewController;

@protocol CrayonColorPickerViewControllerDelegate <NSObject>

- (void)colorPicker:(CrayonColorPickerViewController *)picker didPickColor:(UIColor *)color;

@end

@interface CrayonColorPickerViewController : UIViewController <UIPopoverPresentationControllerDelegate> {
	UIColor *selectedColor;
}

@property (nonatomic, weak) id<CrayonColorPickerViewControllerDelegate> delegate;
@property (nonatomic, strong) id context;

- (instancetype)initWithSelectedColor:(UIColor *)color;

@end
