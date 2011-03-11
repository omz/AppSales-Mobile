/*
 CurrencySelectionDialog.m
 AppSalesMobile
 
 * Copyright (c) 2008, omz:software
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the <organization> nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY omz:software ''AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL <copyright holder> BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CurrencySelectionDialog.h"
#import "CurrencyManager.h"

@implementation CurrencySelectionDialog

@synthesize sortedCurrencies;


- (void)dealloc 
{
	self.sortedCurrencies = nil;
	
    [super dealloc];
}

- (void)viewDidLoad 
{
    [super viewDidLoad];
	
	self.title = NSLocalizedString(@"Currencies",nil);
	//Create sorted list of currencies:
	self.sortedCurrencies = [NSMutableArray array];
	NSArray *availableCurrencies = [[CurrencyManager sharedManager] availableCurrencies];
	for (NSString *currencyCode in availableCurrencies) {
		NSDictionary *currencyInfo = [NSDictionary dictionaryWithObjectsAndKeys:currencyCode, @"currencyCode", NSLocalizedString(currencyCode,nil), @"localizedName", nil];
		[self.sortedCurrencies addObject:currencyInfo];
	}
	NSSortDescriptor *sorter = [[[NSSortDescriptor alloc] initWithKey:@"localizedName" ascending:YES] autorelease];
	[self.sortedCurrencies sortUsingDescriptors:[NSArray arrayWithObject:sorter]];
	
	UIBarButtonItem *doneButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismiss)] autorelease];
	[self.navigationItem setRightBarButtonItem:doneButtonItem];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	return [self.sortedCurrencies count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
    }
	
	cell.textLabel.text = [[self.sortedCurrencies objectAtIndex:[indexPath row]] objectForKey:@"localizedName"];
	
    return cell;
}

- (void)dismiss
{
	[self dismissModalViewControllerAnimated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	int row = [indexPath row];
	NSDictionary *selectedCurrency = [sortedCurrencies objectAtIndex:row];
	NSString *selectedCurrencyCode = [selectedCurrency objectForKey:@"currencyCode"];
	[[CurrencyManager sharedManager] setBaseCurrency:selectedCurrencyCode];
	[self dismiss];
}


@end

