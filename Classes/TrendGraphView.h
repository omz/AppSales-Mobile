//
//  TrendGraphView.h
//  AppSalesMobile
//
//  Created by Ole Zorn on 16.02.09.
//  Copyright 2009 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GraphView.h"

@interface TrendGraphView : GraphView {
	NSString *appName;
	NSString *appID;
}

@property (retain) NSString *appName;
@property (retain) NSString *appID;

@end
