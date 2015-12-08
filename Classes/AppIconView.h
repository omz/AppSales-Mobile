//
//  AppIconView.h
//  AppSales
//
//  Created by Ole Zorn on 25.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Product.h"

@interface AppIconView : UIImageView {
	NSString *productID;
}

@property (nonatomic, assign) BOOL maskEnabled;

- (void)setProduct:(Product *)product;

@end
