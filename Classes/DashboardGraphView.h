//
//  DashboardGraphView.h
//  AppSalesMobile
//
//  Created by Ole Zorn on 06.04.10.
//  Copyright 2010 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class App;

@interface DashboardGraphView : UIView {

	NSArray *reports;
	BOOL showsWeeklyReports;
	BOOL showsUnits;
	BOOL showsRegions;
	
	UIView *markerLineView;
	UIImageView *detailTopView;
	UIImageView *detailBottomView;
	UILabel *dateLabel;
	UILabel *detailLabel;
	int markedReportIndex;
	
	NSString *appFilter;
	NSMutableDictionary *regionsByCountryCode;
}

@property (nonatomic, retain) NSArray *reports;
@property (nonatomic, assign) BOOL showsWeeklyReports;
@property (nonatomic, assign) BOOL showsUnits;
@property (nonatomic, assign) BOOL showsRegions;
@property (nonatomic, retain) NSString *appFilter;

- (void)drawTrendGraph;
- (void)drawRegionsGraph;
- (int)reportIndexForTouch:(UITouch *)touch;
- (void)moveMarkerForTouch:(UITouch *)touch;

@end
