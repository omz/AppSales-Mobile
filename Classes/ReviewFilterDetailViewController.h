//
//  ReviewFilterDetailViewController.h
//  AppSales
//
//  Created by Nicolas Gomollon on 6/21/17.
//
//

#import <UIKit/UIKit.h>

@class ReviewFilter;

@interface ReviewFilterDetailViewController : UITableViewController <UIPickerViewDataSource, UIPickerViewDelegate> {
	ReviewFilter *filter;
	UISwitch *switchView;
	UIPickerView *pickerView;
	BOOL hasInlineDatePicker;
}

- (instancetype)initWithFilter:(ReviewFilter *)_filter;

@end
