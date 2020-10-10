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
 Displays a standard alert with no actions and an OK dismiss button
 @param title The title for the alert
 @param message The message for the alert
 */
- (void)displayAlertWithTitle:(NSString *)title message:(NSString *)message
{
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
