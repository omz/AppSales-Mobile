//
//  UIViewController+Alert.m
//  AppSales
//
//  Created by Darren Jones on 10/10/2020.
//  Copyright © 2020 omz:software. All rights reserved.
//

#import "UIViewController+Alert.h"

@implementation UIViewController (Alert)

/**
 Returns the top most view controller
 */
+ (UIViewController *)topViewController {
    return [self topViewControllerWithRootViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
}

+ (UIViewController *)topViewControllerWithRootViewController:(UIViewController*)viewController {
    if ([viewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController* tabBarController = (UITabBarController*)viewController;
        return [self topViewControllerWithRootViewController:tabBarController.selectedViewController];
    } else if ([viewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController* navContObj = (UINavigationController*)viewController;
        return [self topViewControllerWithRootViewController:navContObj.visibleViewController];
    } else if (viewController.presentedViewController && !viewController.presentedViewController.isBeingDismissed) {
        UIViewController* presentedViewController = viewController.presentedViewController;
        return [self topViewControllerWithRootViewController:presentedViewController];
    }
    else {
        for (UIView *view in [viewController.view subviews])
        {
            id subViewController = [view nextResponder];
            if ( subViewController && [subViewController isKindOfClass:[UIViewController class]])
            {
                if ([(UIViewController *)subViewController presentedViewController]  && ![subViewController presentedViewController].isBeingDismissed) {
                    return [self topViewControllerWithRootViewController:[(UIViewController *)subViewController presentedViewController]];
                }
            }
        }
        return viewController;
    }
}

/**
 Displays a standard alert with no actions and an OK dismiss button on the top most view controller
 @param title The title for the alert
 @param message The message for the alert
 */
+ (void)displayAlertWithTitle:(NSString *)title message:(NSString *)message {
    [[UIViewController topViewController] displayAlertWithTitle:title message:message cancelText:nil];
}

/**
 Displays a standard alert with no actions on the top most view controller
 @param title The title for the alert
 @param message The message for the alert
 @param cancelText The text to display in the dismiss button. If nil, then OK is used
 */
+ (void)displayAlertWithTitle:(NSString *)title message:(NSString *)message cancelText:(NSString *)cancelText {
    [[UIViewController topViewController] displayAlertWithTitle:title message:message cancelText:cancelText];
}

/**
 Displays a standard alert with no actions and an OK dismiss button
 @param title The title for the alert
 @param message The message for the alert
 */
- (void)displayAlertWithTitle:(NSString *)title message:(NSString *)message {
    [self displayAlertWithTitle:title message:message cancelText:nil];
}

/**
 Displays a standard alert with no actions
 @param title The title for the alert
 @param message The message for the alert
 @param cancelText The text to display in the dismiss button. If nil, then OK is used
 */
- (void)displayAlertWithTitle:(NSString *)title message:(NSString *)message cancelText:(NSString *)cancelText {
    if (cancelText == nil) {
        cancelText = NSLocalizedString(@"OK", nil);
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:cancelText
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
