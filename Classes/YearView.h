//
//  YearView.h
//  AppSales
//
//  Created by Ole Zorn on 31.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol YearViewDelegate;

@interface YearView : UIView <UIGestureRecognizerDelegate> {

	NSInteger year;
	NSDictionary *labelsByMonth;
	NSString *footerText;
	NSMutableArray* monthRects;
	NSNumber* selectedMonth;
	id<YearViewDelegate> __weak delegate;
}

@property (nonatomic, assign) NSInteger year;
@property (nonatomic, strong) NSDictionary *labelsByMonth;
@property (nonatomic, strong) NSString *footerText;
@property (nonatomic, weak) id<YearViewDelegate> delegate;

@end

@protocol YearViewDelegate <NSObject>

- (void)yearView:(YearView *)yearView didSelectMonth:(int)month;

@end
