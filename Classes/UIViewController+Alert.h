//
//  UIViewController+Alert.h
//  AppSales
//
//  Created by Darren Jones on 10/10/2020.
//  Copyright © 2020 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (Alert)

+ (UIViewController *)topViewController;

+ (void)displayAlertWithTitle:(NSString * __nullable)title message:(NSString * __nullable)message;
+ (void)displayAlertWithTitle:(NSString * __nullable)title message:(NSString * __nullable)message cancelText:(NSString * __nullable)cancelText;

- (void)displayAlertWithTitle:(NSString * __nullable)title message:(NSString * __nullable)message;
- (void)displayAlertWithTitle:(NSString * __nullable)title message:(NSString * __nullable)message cancelText:(NSString * __nullable)cancelText;

@end

NS_ASSUME_NONNULL_END
