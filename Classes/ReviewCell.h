//
//  ReviewCell.h
//  AppSales
//
//  Created by Nicolas Gomollon on 12/17/15.
//
//

#import <UIKit/UIKit.h>

@class Review;

@interface ReviewCell : UITableViewCell {
	NSDateFormatter *dateFormatter;
}

@property (nonatomic, strong) Review *review;

@end
