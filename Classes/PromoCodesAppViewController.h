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

@interface PromoCodesAppViewController : UITableViewController <UIActionSheetDelegate, FieldEditorViewControllerDelegate, MFMailComposeViewControllerDelegate> {

	Product *product;
	NSOperationQueue *queue;
	NSArray *promoCodes;
	NSDateFormatter *dateFormatter;
	
	NSArray *idleToolbarItems;
	NSArray *busyToolbarItems;
	
	PromoCode *selectedPromoCode;
	UIActionSheet *activeSheet;
}

@property (nonatomic, retain) NSArray *promoCodes;
@property (nonatomic, retain) PromoCode *selectedPromoCode;
@property (nonatomic, retain) UIActionSheet *activeSheet;

- (id)initWithProduct:(Product *)aProduct;
- (void)reloadPromoCodes;
- (void)requestNewCodes:(id)sender;

@end
