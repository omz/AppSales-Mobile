//
//  YearView.h
//  AppSales
//
//  Created by Ole Zorn on 31.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YearView : UIView {

	NSInteger year;
	NSDictionary *labelsByMonth;
	NSString *footerText;
}

@property (nonatomic, assign) NSInteger year;
@property (nonatomic, retain) NSDictionary *labelsByMonth;
@property (nonatomic, retain) NSString *footerText;

@end
