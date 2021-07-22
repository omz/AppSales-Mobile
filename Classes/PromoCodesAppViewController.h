//
//  PromoCodesAppViewController.h
//  AppSales
//
//  Created by Ole Zorn on 13.08.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "FieldEditorViewController.h"

@class Product, PromoCode;

@interface PromoCodesAppViewController : UITableViewController <FieldEditorViewControllerDelegate, MFMailComposeViewControllerDelegate> {
	Product *product;
	NSOperationQueue *queue;
	NSArray *promoCodes;
	NSDateFormatter *dateFormatter;
	
	NSArray *idleToolbarItems;
	NSArray *busyToolbarItems;
	
	PromoCode *selectedPromoCode;
}

@property (nonatomic, strong) NSArray *promoCodes;
@property (nonatomic, strong) PromoCode *selectedPromoCode;

- (instancetype)initWithProduct:(Product *)aProduct;
- (void)reloadPromoCodes;
- (void)requestNewCodes:(id)sender;

@end
