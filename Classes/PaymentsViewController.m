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

- (id)initWithAccount:(ASAccount *)paymentAccount
{
	self = [super initWithNibName:nil bundle:nil];
	if (self) {
		account = [paymentAccount retain];
		self.title = NSLocalizedString(@"Payments", nil);
		self.hidesBottomBarWhenPushed = YES;
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(deletePayments:)] autorelease];
	}
	return self;
}

- (void)loadView
{
	[super loadView];
	self.view.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
	
	self.scrollView = [[[UIScrollView alloc] initWithFrame:self.view.bounds] autorelease];
	scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	scrollView.alwaysBounceHorizontal = YES;
	scrollView.showsHorizontalScrollIndicator = NO;
	scrollView.pagingEnabled = YES;
	scrollView.delegate = self;
	[self.view addSubview:scrollView];
	
	NSNumberFormatter *numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
	[numberFormatter setMaximumFractionDigits:2];
	[numberFormatter setGroupingSize:3];
	[numberFormatter setUsesGroupingSeparator:YES];
	
	NSMutableDictionary *paymentsByYear = [NSMutableDictionary dictionary];
	NSMutableDictionary *sumsByYear = [NSMutableDictionary dictionary];
	NSSet *allPayments = account.payments;
	for (NSManagedObject *payment in allPayments) {
        NSNumber *year = [payment valueForKey:@"year"];
		NSMutableDictionary *paymentsForYear = [paymentsByYear objectForKey:year];
		if (!paymentsForYear) {
			paymentsForYear = [NSMutableDictionary dictionary];
			[paymentsByYear setObject:paymentsForYear forKey:year];
		}
        NSNumber *month = [payment valueForKey:@"month"];
        NSMutableArray *paymentsForMonth = [paymentsForYear objectForKey:month];
        if (!paymentsForMonth) {
            paymentsForMonth = [NSMutableArray array];
            [paymentsForYear setObject:paymentsForMonth forKey:month];
        }
        [paymentsForMonth addObject:payment];
        
        float currentSum = [[sumsByYear objectForKey:year] floatValue];
        [sumsByYear setObject:[NSNumber numberWithFloat:currentSum + [[payment valueForKey:@"amount"] floatValue]] forKey:year];
    }
    
    NSMutableDictionary *labelsByYear = [NSMutableDictionary dictionary];
    for (NSNumber *year in paymentsByYear) {
        NSDictionary *paymentsForYear = [paymentsByYear objectForKey:year];
        for (NSNumber *month in paymentsForYear) {
            NSArray *payments = [paymentsForYear objectForKey:month];
            if ([payments count] > 0) {
                NSNumber *sum = [payments valueForKeyPath:@"@sum.amount"];
                NSString *currency = [[payments objectAtIndex:0] valueForKey:@"currency"];
                NSString *label = [NSString stringWithFormat:@"%@%@", [numberFormatter stringFromNumber:sum], [[CurrencyManager sharedManager] currencySymbolForCurrency:currency]];
                NSMutableDictionary *labelsForYear = [labelsByYear objectForKey:year];
                if (!labelsForYear) {
                    labelsForYear = [NSMutableDictionary dictionary];
                    [labelsByYear setObject:labelsForYear forKey:year];
                }
                [labelsForYear setObject:label forKey:month];
            }
        }
    }
    
    
	NSArray *sortedYears = [[paymentsByYear allKeys] sortedArrayUsingSelector:@selector(compare:)];
	if ([sortedYears count] == 0) {
		NSCalendar *calendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
		NSDateComponents *currentYearComponents = [calendar components:NSYearCalendarUnit fromDate:[NSDate date]];
		NSInteger currentYear = [currentYearComponents year];
		sortedYears = [NSArray arrayWithObject:[NSNumber numberWithInteger:currentYear]];
	}
	
	CGFloat x = 0.0;
	for (NSNumber *year in sortedYears) {
		YearView *yearView = [[[YearView alloc] initWithFrame:CGRectMake(x, 0, scrollView.bounds.size.width, scrollView.bounds.size.height - 10)] autorelease];
		yearView.year = [year integerValue];
		yearView.labelsByMonth = [labelsByYear objectForKey:year];
		if ([allPayments count] > 0) {
			//We assume that all payments have the same currency:
			yearView.footerText = [NSString stringWithFormat:@"\u2211 %@%@", 
							   [[CurrencyManager sharedManager] currencySymbolForCurrency:[[allPayments anyObject] valueForKey:@"currency"]], 
							   [numberFormatter stringFromNumber:[sumsByYear objectForKey:year]]];
		}
		yearView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
		[scrollView addSubview:yearView];
		x += scrollView.bounds.size.width;
	}
	scrollView.contentSize = CGSizeMake(scrollView.bounds.size.width * [sortedYears count], 0);
	[scrollView setContentOffset:CGPointMake(scrollView.contentSize.width, 0)];
		
	self.pageControl = [[[UIPageControl alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 15, self.view.bounds.size.width, 10)] autorelease];
	pageControl.numberOfPages = [sortedYears count];
	pageControl.currentPage = pageControl.numberOfPages - 1;
	pageControl.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
	pageControl.userInteractionEnabled = NO;
	[self.view addSubview:pageControl];
}

- (void)deletePayments:(id)sender
{
	UIActionSheet *deletePaymentsSheet = [[[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Do you want to delete all payments for this account? Payments will be reloaded from iTunes Connect when sales reports are downloaded.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Delete Payments", nil) otherButtonTitles:nil] autorelease];
	[deletePaymentsSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (buttonIndex != actionSheet.cancelButtonIndex) {
		account.payments = [NSSet set];
		[[account managedObjectContext] save:NULL];
		[self.navigationController popViewControllerAnimated:YES];
	}
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	account.paymentsBadge = [NSNumber numberWithInteger:0];
	if ([account.managedObjectContext hasChanges]) {
		[account.managedObjectContext save:NULL];
	}
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)aScrollView
{
	self.pageControl.currentPage = (scrollView.contentOffset.x + scrollView.bounds.size.width * 0.5) / scrollView.bounds.size.width;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc
{
	[scrollView release];
	[pageControl release];
	[account release];
	[super dealloc];
}

@end
