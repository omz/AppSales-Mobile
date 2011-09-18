//
//  ColorButton.h
//  AppSales
//
//  Created by Ole Zorn on 17.04.10.
//  Copyright 2010 omz:software. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ColorButton : UIButton {

	UIColor *color;
	BOOL displayAsEllipse;
	BOOL showOutline;
}

@property (nonatomic, retain) UIColor *color;
@property (nonatomic, assign) BOOL displayAsEllipse;
@property (nonatomic, assign) BOOL showOutline;

@end
