//
//  PromoCodesAppViewController.m
//  AppSales
//
//  Created by Ole Zorn on 13.08.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "PromoCodesAppViewController.h"
#import "Product.h"
#import "ASAccount.h"
#import "UIImage+Tinting.h"
#import "PromoCodeOperation.h"
#import "PromoCode.h"
#import "ReportDownloadCoordinator.h"

#define kActionsSheetTag         1
#define kDeleteCodesSheetTag     2
#define kActionsAllCodesSheetTag 3

@implementation PromoCodesAppViewController

@synthesize promoCodes, selectedPromoCode, activeSheet;

- (instancetype)initWithProduct:(Product *)aProduct {
	self = [super initWithStyle:UITableViewStyleGrouped];
	if (self) {
		product = aProduct;
		queue = [[NSOperationQueue alloc] init];
		[queue setMaxConcurrentOperationCount:1];
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		[dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
		[product addObserver:self forKeyPath:@"promoCodes" options:NSKeyValueObservingOptionNew context:nil];
		[product addObserver:self forKeyPath:@"isDownloadingPromoCodes" options:NSKeyValueObservingOptionNew context:nil];
		
		UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
		UIBarButtonItem *deleteItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(deletePromoCodes:)];
		UIBarButtonItem *actionItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareCodes:)];
		idleToolbarItems = @[deleteItem, flexSpace, actionItem];
		
		UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
		[spinner startAnimating];
		UIBarButtonItem *spinnerItem = [[UIBarButtonItem alloc] initWithCustomView:spinner];
		
		UILabel *statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, 200, 20)];
		statusLabel.font = [UIFont boldSystemFontOfSize:14.0];
		statusLabel.backgroundColor = [UIColor clearColor];
		statusLabel.textColor = [UIColor darkGrayColor];
		statusLabel.textAlignment = NSTextAlignmentCenter;
		statusLabel.text = NSLocalizedString(@"Loading Promo Codes...", nil);
		
		UIView *statusView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 40)];
		[statusView addSubview:statusLabel];
		UIBarButtonItem *statusItem = [[UIBarButtonItem alloc] initWithCustomView:statusView];
		
		UIBarButtonItem *stopItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(stopDownload:)];
		busyToolbarItems = @[spinnerItem, flexSpace, statusItem, flexSpace, stopItem];
		
		self.toolbarItems = product.isDownloadingPromoCodes ? busyToolbarItems : idleToolbarItems;
	}
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	self.title = [product displayName];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshHistory:)];
	
	[self reloadPromoCodes];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"promoCodes"]) {
		[self reloadPromoCodes];
	} else if ([keyPath isEqualToString:@"isDownloadingPromoCodes"]) {
		self.toolbarItems = product.isDownloadingPromoCodes ? busyToolbarItems : idleToolbarItems;
	}
}

- (void)reloadPromoCodes {
	self.promoCodes = [[product.promoCodes allObjects] sortedArrayUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"requestDate" ascending:NO]]];
	
	[self.tableView reloadData];
}

- (void)requestNewCodes:(id)sender {
	FieldSpecifier *numberOfCodesField = [FieldSpecifier numericFieldWithKey:@"numberOfCodes" title:NSLocalizedString(@"Number of Codes", nil) defaultValue:@""];
	
	FieldSectionSpecifier *numberOfCodesSection = [FieldSectionSpecifier sectionWithFields:@[numberOfCodesField]
																					 title:@"" 
																			   description:NSLocalizedString(@"AppSales will automatically adjust the number you enter to the number of codes that are available.", nil)];
	FieldEditorViewController *vc = [[FieldEditorViewController alloc] initWithFieldSections:@[numberOfCodesSection] title:NSLocalizedString(@"Promo Codes", nil)];
	vc.delegate = self;
	vc.doneButtonTitle = NSLocalizedString(@"Request", nil);
	vc.cancelButtonTitle = NSLocalizedString(@"Cancel", nil);
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
		navController.modalPresentationStyle = UIModalPresentationFormSheet;
	}
	[self presentViewController:navController animated:YES completion:nil];
}

- (void)stopDownload:(id)sender {
	[[ReportDownloadCoordinator sharedReportDownloadCoordinator] cancelAllDownloads];
}

- (void)deletePromoCodes:(id)sender {
	if (self.activeSheet.visible) {
		[self.activeSheet dismissWithClickedButtonIndex:activeSheet.cancelButtonIndex animated:NO];
	}
	UIActionSheet *deleteSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Do you want to delete all promo codes for this app? You can reload them later from your history.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Delete Promo Codes", nil) otherButtonTitles:nil];
	deleteSheet.tag = kDeleteCodesSheetTag;
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
		self.activeSheet = deleteSheet;
		[deleteSheet showFromBarButtonItem:sender animated:YES];
	} else {
		[deleteSheet showFromToolbar:self.navigationController.toolbar];
	}
}

- (void)shareCodes:(id)sender {
	if (self.activeSheet.visible) {
		[self.activeSheet dismissWithClickedButtonIndex:self.activeSheet.cancelButtonIndex animated:NO];
	}
	UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil
														delegate:self 
											   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
										  destructiveButtonTitle:nil
											   otherButtonTitles:
							 NSLocalizedString(@"Email All Codes", nil), 
							 NSLocalizedString(@"Copy All Codes", nil), nil];
	sheet.tag = kActionsAllCodesSheetTag;
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
		[sheet showFromBarButtonItem:sender animated:YES];
		self.activeSheet = sheet;
	} else {
		[sheet showFromToolbar:self.navigationController.toolbar];
	}
}

- (void)fieldEditor:(FieldEditorViewController *)editor didFinishEditingWithValues:(NSDictionary *)returnValues {
	NSInteger numberOfCodes = [returnValues[@"numberOfCodes"] integerValue];
	if (numberOfCodes <= 0) {
		[[[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"Please enter the number of codes you want to request.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
		return;
	} else if (numberOfCodes > 50) {
		[[[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"Please enter a smaller number. You have a maximum of 50 promo codes per version of your app.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
		return;
	}
	[self dismissViewControllerAnimated:YES completion:nil];
	
	[[ReportDownloadCoordinator sharedReportDownloadCoordinator] downloadPromoCodesForProduct:product numberOfCodes:numberOfCodes];
}

- (void)fieldEditorDidCancel:(FieldEditorViewController *)editor {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)refreshHistory:(id)sender {
	[[ReportDownloadCoordinator sharedReportDownloadCoordinator] downloadPromoCodesForProduct:product numberOfCodes:0];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
		return YES;
	}
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == 0) {
		return 1;
	}
	return [self.promoCodes count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == 1) {
		return NSLocalizedString(@"Promo Code History", nil);
	}
	return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	if (section == 1) {
		return NSLocalizedString(@"Tap the refresh button to load promo codes you recently requested without AppSales.", nil);
	}
	return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0) {
		return 44.0;
	}
	return 55.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"Cell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
	}
	
	if (indexPath.section == 0) {
		cell.textLabel.text = NSLocalizedString(@"Request New Codes...", nil);
        
        if (@available(iOS 13.0, *)) {
            cell.imageView.image = [UIImage as_tintedImageNamed:@"RequestPromoCode" color:[[UIColor labelColor] colorWithAlphaComponent:0.4]];
        } else {
            cell.imageView.image = [UIImage imageNamed:@"RequestPromoCode"];
        }
		cell.imageView.highlightedImage = [UIImage as_tintedImageNamed:@"RequestPromoCode" color:[UIColor whiteColor]];
		
        if (@available(iOS 13.0, *)) {
            cell.textLabel.textColor = [UIColor labelColor];
        } else {
            cell.textLabel.textColor = [UIColor blackColor];
        }
        
	} else {
		PromoCode *promoCode = self.promoCodes[indexPath.row];
		BOOL used = [promoCode.used boolValue];
		cell.textLabel.text = promoCode.code;
		NSString *dateString = [dateFormatter stringFromDate:promoCode.requestDate];
		cell.detailTextLabel.text = used ? [NSString stringWithFormat:@"(used)  %@", dateString] : dateString;
        
        if (@available(iOS 13.0, *)) {
            cell.imageView.image = used ? [UIImage as_tintedImageNamed:@"PromoCodes" color:[[UIColor labelColor] colorWithAlphaComponent:0.4]] : [UIImage imageNamed:@"PromoCodes"];
        } else {
            cell.imageView.image = used ? [UIImage as_tintedImageNamed:@"PromoCodes" color:[UIColor grayColor]] : [UIImage imageNamed:@"PromoCodes"];
        }
		cell.imageView.highlightedImage = [UIImage as_tintedImageNamed:@"PromoCodes" color:[UIColor whiteColor]];
        
        if (@available(iOS 13.0, *)) {
            cell.textLabel.textColor = [UIColor labelColor];
        } else {
            cell.textLabel.textColor = [UIColor blackColor];
        }
	}
	
	return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 1) {
		self.selectedPromoCode = self.promoCodes[indexPath.row];
		BOOL used = [selectedPromoCode.used boolValue];
		UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil
														   delegate:self
												  cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
											 destructiveButtonTitle:nil
												  otherButtonTitles:
								NSLocalizedString(@"Email Code", nil),
								NSLocalizedString(@"Copy", nil),
								used ? NSLocalizedString(@"Mark as Unused", nil) : NSLocalizedString(@"Mark as Used", nil) , nil];
		sheet.tag = kActionsSheetTag;
		[sheet showFromToolbar:self.navigationController.toolbar];
	} else {
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
		[self requestNewCodes:self];
	}
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
	
	if (actionSheet.tag == kActionsSheetTag) {
		if (buttonIndex != actionSheet.cancelButtonIndex) {
			if (buttonIndex == 0) {
				//email
				if (![MFMailComposeViewController canSendMail]) {
					[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No Email Account", nil) message:NSLocalizedString(@"You have not configured this device for sending email.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
					return;
				}
				MFMailComposeViewController *mailComposeViewController = [[MFMailComposeViewController alloc] init];
				mailComposeViewController.mailComposeDelegate = self;
				NSString *body = [NSString stringWithFormat:@"<br/><a href=\"https://phobos.apple.com/WebObjects/MZFinance.woa/wa/freeProductCodeWizard?code=%@\">Redeem Promo Code for %@ (%@)</a>", self.selectedPromoCode.code, [self.selectedPromoCode.product displayName], self.selectedPromoCode.code];
				NSString *subject = [NSString stringWithFormat:@"Promo Code for %@", [product displayName]];
				[mailComposeViewController setMessageBody:body isHTML:YES];
				[mailComposeViewController setSubject:subject];
				[self presentViewController:mailComposeViewController animated:YES completion:nil];
			} else if (buttonIndex == 1) {
				//copy
				[[UIPasteboard generalPasteboard] setString:self.selectedPromoCode.code];
			} else if (buttonIndex == 2) {
				//toggle used
				self.selectedPromoCode.used = @(![self.selectedPromoCode.used boolValue]);
				[self.tableView reloadData];
			}
		}
	} else if (actionSheet.tag == kActionsAllCodesSheetTag) {
		if (buttonIndex != actionSheet.cancelButtonIndex) {
			if (buttonIndex == 0) {
				if (![MFMailComposeViewController canSendMail]) {
					[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No Email Account", nil) message:NSLocalizedString(@"You have not configured this device for sending email.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
					return;
				}
				MFMailComposeViewController *mailComposeViewController = [[MFMailComposeViewController alloc] init];
				mailComposeViewController.mailComposeDelegate = self;
				NSMutableString *body = [NSMutableString stringWithString:@"\n"];
				for (PromoCode *promoCode in self.promoCodes) {
					[body appendFormat:@"%@\n", promoCode.code];
				}
				NSString *subject = [NSString stringWithFormat:@"Promo Codes for %@", [product displayName]];
				[mailComposeViewController setMessageBody:body isHTML:NO];
				[mailComposeViewController setSubject:subject];
				[self presentViewController:mailComposeViewController animated:YES completion:nil];
			} else if (buttonIndex == 1) {
				NSMutableString *allCodes = [NSMutableString string];
				for (PromoCode *promoCode in self.promoCodes) {
					[allCodes appendFormat:@"%@\n", promoCode.code];
				}
				[[UIPasteboard generalPasteboard] setString:allCodes];
			}
		}
	} else if (actionSheet.tag == kDeleteCodesSheetTag) {
		if (buttonIndex != actionSheet.cancelButtonIndex) {
			product.promoCodes = [NSSet set];
			[self.navigationController popViewControllerAnimated:YES];
		}
	}
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
	if (self.selectedPromoCode && result == MFMailComposeResultSent) {
		self.selectedPromoCode.used = @(YES);
		[self.tableView reloadData];
	}
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dealloc {
	[product removeObserver:self forKeyPath:@"promoCodes"];
	[product removeObserver:self forKeyPath:@"isDownloadingPromoCodes"];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
	return UIInterfaceOrientationMaskPortrait;
}

@end
