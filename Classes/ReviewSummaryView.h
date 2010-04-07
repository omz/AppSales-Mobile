//
//  ReviewSummaryView.h
//  AppSalesMobile
//
//  Created by Ole Zorn on 06.04.10.
//  Copyright 2010 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class App;

@interface ReviewSummaryView : UIControl {

	App *app;
}

@property (nonatomic, retain) App *app;

- (id)initWithFrame:(CGRect)frame app:(App *)anApp;

@end
