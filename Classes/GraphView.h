//
//  GraphView.h
//  AppSales
//
//  Created by Ole Zorn on 11.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GraphView, ScaleView;

@protocol GraphViewDelegate <NSObject>

- (void)graphView:(GraphView *)view didSelectBarAtIndex:(NSUInteger)index withFrame:(CGRect)barFrame;
@optional
- (BOOL)graphView:(GraphView *)view canDeleteBarAtIndex:(NSUInteger)index;
- (void)graphView:(GraphView *)view deleteBarAtIndex:(NSUInteger)index;

@end


@protocol GraphViewDataSource <NSObject>

- (NSArray *)colorsForGraphView:(GraphView *)graphView;
- (NSUInteger)numberOfBarsInGraphView:(GraphView *)graphView;
- (NSArray *)graphView:(GraphView *)graphView valuesForBarAtIndex:(NSUInteger)index;
- (NSString *)graphView:(GraphView *)graphView labelForXAxisAtIndex:(NSUInteger)index;
- (UIColor *)graphView:(GraphView *)graphView labelColorForXAxisAtIndex:(NSUInteger)index;
- (NSString *)graphView:(GraphView *)graphView labelForBarAtIndex:(NSUInteger)index;
- (NSString *)graphView:(GraphView *)graphView labelForSectionAtIndex:(NSUInteger)index;

@end


@interface GraphView : UIView <UIScrollViewDelegate> {

	id<GraphViewDataSource> dataSource;
	id<GraphViewDelegate> delegate;
	
	NSMutableDictionary *cachedValues;
	int barsPerPage;
	CGFloat barWidth;
	
	NSRange visibleRange;
	float max;
	BOOL maxLocked;
	UIImageView *lockIndicatorView;
	UILabel *titleLabel;
	NSUInteger selectedBarIndexForMenu;
	
	NSMutableDictionary *visibleBarViews;
	UIScrollView *scrollView;
	ScaleView *scaleView;
	UIButton *sectionLabelButton;
}

@property (nonatomic, assign) id<GraphViewDelegate> delegate;
@property (nonatomic, assign) id<GraphViewDataSource> dataSource;

@property (nonatomic, retain) UIButton *sectionLabelButton;
@property (nonatomic, retain) NSString *unit;
@property (nonatomic, retain) NSString *title;

- (NSRange)visibleBarRange;
- (CGRect)frameForBarAtIndex:(int)index;
- (NSString *)labelTextForIndex:(NSUInteger)index;
- (NSArray *)stackedValuesForBarAtIndex:(NSUInteger)index;
- (void)setNumberOfBarsPerPage:(int)newBarsPerPage;
- (void)reloadColors;
- (void)reloadData;
- (void)reloadValuesAnimated:(BOOL)animated;
- (float)maxVisibleValue;


@end


@interface StackedBarView : UIControl {
    
	NSMutableArray *segmentViews;
	UILabel *label;
	UIView *selectedBackgroundView;
}

- (id)initWithColors:(NSArray *)colorArray;
- (void)setSegmentValues:(NSArray *)values;
- (void)setSegmentValues:(NSArray *)values label:(NSString *)labelText;
- (UIView *)selectedBackgroundView;

@end


#define kScaleViewLineLabelTag	1

@interface ScaleView : UIView {
	
	NSString *unit;
	float max;
	NSArray *possibleUnits;
	NSMutableDictionary *lineViews;
}

@property (nonatomic, retain) NSString *unit;

- (void)setMax:(float)newMax animated:(BOOL)animated;

@end


@interface LineView : UIView {
	
	UILabel *label;
}

- (void)setLabelText:(NSString *)labelText;

@end


@interface TouchCancellingScrollView : UIScrollView

@end