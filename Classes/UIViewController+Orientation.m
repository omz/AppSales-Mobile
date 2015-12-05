//
//  UIViewController+Orientation.m
//  AppSales
//
//  Created by Nicolas Gomollon on 12/4/15.
//
//

#import "UIViewController+Orientation.h"

@implementation UIViewController (Orientation)

- (UIInterfaceOrientation)relativeOrientationFromTransform:(CGAffineTransform)transform {
	NSArray *conversionMatrix = @[@(UIInterfaceOrientationPortrait),
								  @(UIInterfaceOrientationLandscapeRight),
								  @(UIInterfaceOrientationPortraitUpsideDown),
								  @(UIInterfaceOrientationLandscapeLeft)];
	
	UIInterfaceOrientation oldOrientation = [UIApplication sharedApplication].statusBarOrientation;
	NSInteger oldIndex = [conversionMatrix indexOfObject:@(oldOrientation)];
	if (oldIndex == NSNotFound) {
		return UIInterfaceOrientationUnknown;
	}
	
	CGFloat angle = atan2f(transform.b, transform.a);
	NSInteger newIndex = (oldIndex - (NSInteger)roundf(angle / M_PI_2)) % 4;
	while (newIndex < 0) {
		newIndex += 4;
	}
	
	return (UIInterfaceOrientation)[conversionMatrix[newIndex] intValue];
}

@end
