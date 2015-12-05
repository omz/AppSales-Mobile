//
//  UIViewController+Orientation.h
//  AppSales
//
//  Created by Nicolas Gomollon on 12/4/15.
//
//

#import <UIKit/UIKit.h>

@interface UIViewController (Orientation)

- (UIInterfaceOrientation)relativeOrientationFromTransform:(CGAffineTransform)transform;

@end
