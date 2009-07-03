/*
 CountriesController.m
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

#import "CountriesController.h"
#import "CountryCell.h"
#import "ProductCell.h"
#import "EntriesController.h"
#import "Entry.h"
#import "Country.h"
#import "AppIconManager.h"

@implementation CountriesController

@synthesize countries;
@synthesize products;
@synthesize totalRevenue;
@synthesize displayMode;

- (void)dealloc 
{
	self.products = nil;
	self.countries = nil;
    [super dealloc];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.tableView.rowHeight = 45.0;
	
	self.displayMode = [[NSUserDefaults standardUserDefaults] integerForKey:@"CountriesControllerDisplayMode"];
	UISegmentedControl *modeControl = [[[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:NSLocalizedString(@"Countries",nil), NSLocalizedString(@"Products",nil), nil]] autorelease];
	modeControl.selectedSegmentIndex = displayMode;
	modeControl.segmentedControlStyle = UISegmentedControlStyleBar;
	[modeControl addTarget:self action:@selector(changeDisplayMode:) forControlEvents:UIControlEventValueChanged];
	
	self.navigationItem.titleView = modeControl;
}

- (void)changeDisplayMode:(id)sender
{
	self.displayMode = [sender selectedSegmentIndex];
	[[NSUserDefaults standardUserDefaults] setInteger:displayMode forKey:@"CountriesControllerDisplayMode"];
	
	[self.tableView reloadData];
}

- (void)setCountries:(NSArray *)newCountries
{
	[newCountries retain];
	[countries release];
	countries = newCountries;
	if (countries == nil)
		return;
	
	//compile product stats:
	NSMutableDictionary *productInfos = [NSMutableDictionary dictionary];
	for (Country *c in countries) {
		for (Entry *e in c.entries) {
			if ([e transactionType] == 1) {
				NSMutableDictionary *productInfo = [productInfos objectForKey:[e productName]];
				if (!productInfo) {
					productInfo = [NSMutableDictionary dictionary];
					[productInfo setObject:[NSNumber numberWithFloat:0.0] forKey:@"revenue"];
					[productInfo setObject:[NSNumber numberWithInt:0] forKey:@"units"];
					[productInfo setObject:[e productName] forKey:@"name"];
					[productInfos setObject:productInfo forKey:[e productName]];
				}
				NSNumber *revenueOfProduct = [productInfo objectForKey:@"revenue"];
				NSNumber *unitsOfProduct = [productInfo objectForKey:@"units"];
						
				float revenue = [revenueOfProduct floatValue];
				int units = [unitsOfProduct intValue];
				
				revenue += [e totalRevenueInBaseCurrency];
				units += [e units];
				
				[productInfo setObject:[NSNumber numberWithFloat:revenue] forKey:@"revenue"];
				[productInfo setObject:[NSNumber numberWithInt:units] forKey:@"units"];
			}
		}
	}
	NSSortDescriptor *revenueSorter = [[[NSSortDescriptor alloc] initWithKey:@"revenue" ascending:NO] autorelease];
	self.products = [[productInfos allValues] sortedArrayUsingDescriptors:[NSArray arrayWithObject:revenueSorter]];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	if (self.displayMode == 0) {
		if (!self.countries)
			return 0;
		return [self.countries count];
	}
	else {
		return [self.products count];
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{    
	if (self.displayMode == 0) {
		static NSString *CountryCellIdentifier = @"CountryCell";
		CountryCell *cell = (CountryCell *)[tableView dequeueReusableCellWithIdentifier:CountryCellIdentifier];
		if (cell == nil) {
			cell = [[[CountryCell alloc] initWithFrame:CGRectZero reuseIdentifier:CountryCellIdentifier] autorelease];
		}
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.totalRevenue = self.totalRevenue;
		cell.country = [self.countries objectAtIndex:[indexPath row]];
		return cell;
	}
	else {
		static NSString *ProductCellIdentifier = @"ProductCell";
		ProductCell *cell = (ProductCell *)[tableView dequeueReusableCellWithIdentifier:ProductCellIdentifier];
		if (cell == nil) {
			cell = [[[ProductCell alloc] initWithFrame:CGRectZero reuseIdentifier:ProductCellIdentifier] autorelease];
		}
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.totalRevenue = self.totalRevenue;
		NSDictionary *productInfo = [products objectAtIndex:[indexPath row]];
		NSString *appName = [productInfo objectForKey:@"name"];
		cell.productInfo = productInfo;
		UIImage *appIcon = [[AppIconManager sharedManager] iconForAppNamed:appName];
		if (appIcon != nil) [cell setAppIcon:appIcon];
		return cell;
	}
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	if (self.displayMode == 0) {
		Country *selectedCountry = [self.countries objectAtIndex:[indexPath row]];
		EntriesController *entriesController = [[[EntriesController alloc] init] autorelease];
		entriesController.title = selectedCountry.name;
		entriesController.entries = [selectedCountry children];
		[entriesController.tableView reloadData];
		[self.navigationController pushViewController:entriesController animated:YES];
		[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
	}
}


@end

