//
//  MovableView.h
//  AppSales
//
//  Created by Ole Zorn on 09.04.10.
//  Copyright 2010 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface MovableView : UIView {

}

- (void)pan:(UIPanGestureRecognizer *)recognizer;

@end
