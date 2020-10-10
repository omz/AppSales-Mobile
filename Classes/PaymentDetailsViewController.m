//
//  PaymentDetailsViewController.m
//  AppSales
//
//  Created by Duncan Cunningham on 10/10/20.
//  Copyright © 2020 omz:software. All rights reserved.
//

#import "PaymentDetailsViewController.h"

typedef NS_ENUM(NSInteger, PaymentDetailsRow) {
	PaymentDetailsRowAmount = 0,
	PaymentDetailsRowBankName,
	PaymentDetailsRowMaskedBankAccount,
	PaymentDetailsRowIsExpected,
	PaymentDetailsRowPaidOrExpectedDate,
	PaymentDetailsRowStatus,
	PaymentDetailsRowDelete,
	
	PaymentDetailsRowCount
};

@interface PaymentDetailsViewController ()

@end

@implementation PaymentDetailsViewController

@synthesize delegate;

- (instancetype)initWithPaymentDetails:(NSArray *)details {
	self = [super initWithStyle:UITableViewStyleGrouped];
	if (self) {
		paymentDetails = details;
		
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
		
		numberFormatter = [[NSNumberFormatter alloc] init];
		numberFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
	}
	return self;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	if (paymentDetails) {
		return paymentDetails.count;
	} else {
		return 0;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return PaymentDetailsRowCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *normalCellIdentifier = @"Cell";
	static NSString *deleteCellIdentifier = @"DeleteCell";
	
	NSInteger row = indexPath.row;
	UITableViewCell *cell;
	
	if (row == PaymentDetailsRowDelete) {
		cell = [tableView dequeueReusableCellWithIdentifier:deleteCellIdentifier];
		if (!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:deleteCellIdentifier];
		}
		 cell.selectionStyle = UITableViewCellSelectionStyleDefault;
	} else {
		cell = [tableView dequeueReusableCellWithIdentifier:normalCellIdentifier];
		if (!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:normalCellIdentifier];
		}
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	}
	
	NSManagedObject *details = paymentDetails[indexPath.section][0];
	
	if (row == PaymentDetailsRowAmount) {
		[numberFormatter setCurrencyCode:[details valueForKey:@"currency"]];
		cell.textLabel.text = NSLocalizedString(@"Amount", comment: nil);
		cell.detailTextLabel.text = [numberFormatter stringFromNumber:[details valueForKey:@"amount"]];
	} else if (row == PaymentDetailsRowBankName) {
		cell.textLabel.text = NSLocalizedString(@"Bank", comment: nil);
		cell.detailTextLabel.text = [details valueForKey:@"bankName"];
	} else if (row == PaymentDetailsRowMaskedBankAccount) {
		cell.textLabel.text = NSLocalizedString(@"Bank Account", comment: nil);
		cell.detailTextLabel.text = [details valueForKey:@"maskedBankAccount"];
	} else if (row == PaymentDetailsRowIsExpected) {
		cell.textLabel.text = NSLocalizedString(@"Is Expected", comment: nil);
		cell.detailTextLabel.text = [[details valueForKey:@"isExpected"] boolValue] ? NSLocalizedString(@"Yes", comment: nil) : NSLocalizedString(@"No", comment: nil);
	} else if (row == PaymentDetailsRowPaidOrExpectedDate) {
		NSDate *date = [details valueForKey:@"paidOrExpectingPaymentDate"];
		cell.textLabel.text = NSLocalizedString(@"Paid/Expected Date", comment: nil);
		cell.detailTextLabel.text = [dateFormatter stringFromDate:date];
	} else if (row == PaymentDetailsRowStatus) {
		cell.textLabel.text = NSLocalizedString(@"Status", comment: nil);
		cell.detailTextLabel.text = [details valueForKey:@"status"];
	} else if (row == PaymentDetailsRowDelete) {
		cell.textLabel.text = NSLocalizedString(@"Delete", comment: nil);
		cell.textLabel.textColor = [UIColor systemRedColor];
		cell.textLabel.textAlignment = NSTextAlignmentCenter;
	}
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
	
	if (indexPath.row == PaymentDetailsRowDelete) {
		UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Delete Payment", comment: nil)
																	   message:NSLocalizedString(@"Do you want to delete this payment?", comment: nil)
																preferredStyle:UIAlertControllerStyleActionSheet];
		alert.popoverPresentationController.sourceView = [tableView cellForRowAtIndexPath:indexPath];
		 
		NSArray *details = paymentDetails[indexPath.section];
		
		UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Delete", comment: nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
			NSMutableArray *mutablePaymentDetails = [[NSMutableArray alloc] initWithArray:paymentDetails];
			[mutablePaymentDetails removeObject:details];
			paymentDetails = [mutablePaymentDetails copy];
			[delegate paymentDetailsViewController:self didDeletePaymentDetails:details[0]];
			if (paymentDetails.count == 0) {
				[self.navigationController popViewControllerAnimated:YES];
			} else {
				[tableView reloadData];
			}
		}];
		UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", comment: nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {}];
		 
		[alert addAction:deleteAction];
		[alert addAction:cancelAction];
		[self presentViewController:alert animated:YES completion:nil];
	}
}

@end
