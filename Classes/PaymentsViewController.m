//
//  PaymentsViewController.m
//  AppSales
//
//  Created by Ole Zorn on 31.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "PaymentsViewController.h"
#import "YearView.h"
#import "ASAccount.h"
#import "CurrencyManager.h"

@implementation PaymentsViewController

@synthesize scrollView, pageControl;

- (instancetype)initWithAccount:(ASAccount *)paymentAccount {
	self = [super init];
	if (self) {
		account = paymentAccount;
		self.title = NSLocalizedString(@"Payments", nil);
		self.tabBarItem.image = [UIImage imageNamed:@"Payments"];
		self.hidesBottomBarWhenPushed = [UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad;
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(deletePayments:)];
		if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
			[account addObserver:self forKeyPath:@"payments" options:NSKeyValueObservingOptionNew context:nil];
		}
	}
	return self;
}

- (void)loadView {
	[super loadView];
	self.edgesForExtendedLayout = UIRectEdgeNone;
	
	self.view.backgroundColor = [UIColor colorWithRed:111.0f/255.0f green:113.0f/255.0f blue:121.0f/255.0f alpha:1.0f];
	
	self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
	scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	scrollView.alwaysBounceHorizontal = YES;
	scrollView.showsHorizontalScrollIndicator = NO;
	scrollView.pagingEnabled = YES;
	scrollView.delegate = self;
	
	[self.view addSubview:scrollView];
	
	self.pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 15, self.view.bounds.size.width, 10)];
	pageControl.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
	pageControl.userInteractionEnabled = NO;
	[self.view addSubview:pageControl];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	[self reloadData];
}

- (void)reloadData {
	for (UIView *v in [NSArray arrayWithArray:self.scrollView.subviews]) [v removeFromSuperview];
	
	NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
	numberFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
	
	NSMutableDictionary *paymentsByYear = [NSMutableDictionary dictionary];
	NSMutableDictionary *sumsByYear = [NSMutableDictionary dictionary];
	NSSet *allPayments = account.payments;
	for (NSManagedObject *payment in allPayments) {
		NSNumber *year = [payment valueForKey:@"year"];
		NSMutableDictionary *paymentsForYear = paymentsByYear[year];
		if (!paymentsForYear) {
			paymentsForYear = [NSMutableDictionary dictionary];
			paymentsByYear[year] = paymentsForYear;
		}
		NSNumber *month = [payment valueForKey:@"month"];
		NSMutableArray *paymentsForMonth = paymentsForYear[month];
		if (!paymentsForMonth) {
			paymentsForMonth = [NSMutableArray array];
			paymentsForYear[month] = paymentsForMonth;
		}
		[paymentsForMonth addObject:payment];
		
		CGFloat currentSum = [sumsByYear[year] floatValue];
		sumsByYear[year] = @(currentSum + [[payment valueForKey:@"amount"] floatValue]);
	}
	
	NSMutableDictionary *labelsByYear = [NSMutableDictionary dictionary];
	for (NSNumber *year in paymentsByYear) {
		NSDictionary *paymentsForYear = paymentsByYear[year];
		for (NSNumber *month in paymentsForYear) {
			NSArray *payments = paymentsForYear[month];
			if ([payments count] > 0) {
				NSNumber *sum = [payments valueForKeyPath:@"@sum.amount"];
				NSString *currencyCode = [payments[0] valueForKey:@"currency"];
				numberFormatter.currencyCode = currencyCode;
				NSString *label = [numberFormatter stringFromNumber:sum];
				NSMutableDictionary *labelsForYear = labelsByYear[year];
				if (!labelsForYear) {
					labelsForYear = [NSMutableDictionary dictionary];
					labelsByYear[year] = labelsForYear;
				}
				labelsForYear[month] = label;
			}
		}
	}
	
	
	NSArray *sortedYears = [[paymentsByYear allKeys] sortedArrayUsingSelector:@selector(compare:)];
	if ([sortedYears count] == 0) {
		NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
		NSDateComponents *currentYearComponents = [calendar components:NSCalendarUnitYear fromDate:[NSDate date]];
		NSInteger currentYear = [currentYearComponents year];
		sortedYears = @[@(currentYear)];
	}
	
	CGFloat x = 0.0;
	for (NSNumber *year in sortedYears) {
		YearView *yearView = [[YearView alloc] initWithFrame:CGRectMake(x, 0, scrollView.bounds.size.width, scrollView.bounds.size.height - 10)];
		yearView.year = [year integerValue];
		yearView.labelsByMonth = labelsByYear[year];
		if ([allPayments count] > 0) {
			// We assume that all payments have the same currency.
			numberFormatter.currencyCode = [[allPayments anyObject] valueForKey:@"currency"];
			yearView.footerText = [NSString stringWithFormat:@"\u2211 %@", [numberFormatter stringFromNumber:sumsByYear[year]]];
		}
		yearView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
		[scrollView addSubview:yearView];
		x += scrollView.bounds.size.width;
	}
	
	scrollView.contentSize = CGSizeMake(scrollView.bounds.size.width * [sortedYears count], 0);
	[scrollView setContentOffset:CGPointMake(scrollView.contentSize.width - scrollView.bounds.size.width, 0)];
	
	self.pageControl.numberOfPages = [sortedYears count];
	self.pageControl.currentPage = pageControl.numberOfPages - 1;
}

- (void)viewWillAppear:(BOOL)animated {
	[self reloadData];
}

- (void)deletePayments:(id)sender {
	UIActionSheet *deletePaymentsSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Do you want to delete all payments for this account? Payments will be reloaded from iTunes Connect when sales reports are downloaded.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Delete Payments", nil) otherButtonTitles:nil];
	[deletePaymentsSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
	if (buttonIndex != actionSheet.cancelButtonIndex) {
		account.payments = [NSSet set];
		[[account managedObjectContext] save:nil];
		if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
			[self.navigationController popViewControllerAnimated:YES];
		}
	}
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	account.paymentsBadge = @(0);
	if ([account.managedObjectContext hasChanges]) {
		[account.managedObjectContext save:nil];
	}
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)aScrollView {
	self.pageControl.currentPage = (scrollView.contentOffset.x + scrollView.bounds.size.width * 0.5) / scrollView.bounds.size.width;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
		return YES;
	}
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
		[account removeObserver:self forKeyPath:@"payments"];
	}
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
	return UIInterfaceOrientationMaskPortrait;
}

@end
