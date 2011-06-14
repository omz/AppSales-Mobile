/*
 DaysController.m
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

#import "DaysController.h"
#import "Day.h"
#import "DayCell.h"
#import "CountriesController.h"
#import "RootViewController.h"
#import "CurrencyManager.h"
#import "ReportManager.h"
#import "NSDateFormatter+SharedInstances.h"
#import "AppleFiscalCalendar.h"
#import "Country.h"
#import "Entry.h"

static Country *newCountry(NSString *countryName, NSMutableDictionary *countries)
{
	Country *country = [countries objectForKey:countryName];
	if (!country) {
		country = [[Country alloc] initWithName:countryName day:nil];
		[countries setObject:country forKey:countryName];
        [country release];
	}
	return country;
}

@interface DaysController ()
@property (nonatomic, retain) UIBarButtonItem *fiscalButton;
@property (nonatomic, retain) UIBarButtonItem *calendarButton;
@property (nonatomic, assign) DayCalendarType calendarType;
@end

@implementation DaysController

@synthesize fiscalButton, calendarButton, calendarType;

- (id)init
{
	self = [super init];
	if (self) {	
		self.title = NSLocalizedString(@"Daily Reports",nil);

        self.fiscalButton = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Fiscal", nil) 
                                                                   style:UIBarButtonItemStyleBordered 
                                                                  target:self 
                                                                  action:@selector(showFiscal:)] autorelease];

        self.calendarButton = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Calendar", nil) 
                                                              style:UIBarButtonItemStyleBordered 
                                                             target:self 
                                                             action:@selector(showCalendar:)] autorelease];
	}
	return self;
}

- (void)showFiscal:(id)sender
{
    self.calendarType = DayCalendarTypeAppleFiscal;
    self.navigationItem.rightBarButtonItem = self.calendarButton;
    [[NSUserDefaults standardUserDefaults] setInteger:self.calendarType forKey:@"DayCalendarType"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self reload];
}

- (void)showCalendar:(id)sender
{
    self.calendarType = DayCalendarTypeCalendar;
    self.navigationItem.rightBarButtonItem = self.fiscalButton;
    [[NSUserDefaults standardUserDefaults] setInteger:self.calendarType forKey:@"DayCalendarType"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self reload];
}

- (void)reload
{
	self.daysByMonth = [NSMutableArray array];

    self.calendarType = [[NSUserDefaults standardUserDefaults] integerForKey:@"DayCalendarType"];
    if (self.calendarType == DayCalendarTypeCalendar) {
        self.navigationItem.rightBarButtonItem = self.fiscalButton;
    } else {
        self.navigationItem.rightBarButtonItem = self.calendarButton;
    }

	NSSortDescriptor *dateSorter = [[[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO] autorelease];
	NSArray *sortedDays = [[[ReportManager sharedManager].days allValues] sortedArrayUsingDescriptors:[NSArray arrayWithObject:dateSorter]];
    
    if (self.calendarType == DayCalendarTypeCalendar) {
        NSCalendar *calendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
        NSInteger lastMonth = -1;

        for (Day *d in sortedDays) {
            NSDate *date = d.date;
            NSDateComponents *components = [calendar components:NSMonthCalendarUnit fromDate:date];
            int month = [components month];
            if (month != lastMonth) {
                [self.daysByMonth addObject:[NSMutableArray array]];
                lastMonth = month;
            }
            [[self.daysByMonth lastObject] addObject:d];
        }
    } else {
        AppleFiscalCalendar *calendar = [AppleFiscalCalendar sharedFiscalCalendar];
        NSString *lastMonth = nil;
        
        for (Day *d in sortedDays) {
            NSDate *date = d.date;
            NSString *month = [calendar fiscalMonthForDate:date];
            if (month && [month compare:lastMonth] != NSOrderedSame) {
                [self.daysByMonth addObject:[NSMutableArray array]];
                lastMonth = month;
            }
            [[self.daysByMonth lastObject] addObject:d];
        }
    }
    
	[self.tableView reloadData];
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self reload];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload)
												 name:ReportManagerDownloadedDailyReportsNotification object:nil];
}

- (void) viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath 
{ 
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		int section = [indexPath section];
		int row = [indexPath row];
		NSArray *selectedMonth = [self.daysByMonth objectAtIndex:section];
		Day *selectedDay = [selectedMonth objectAtIndex:row];
		[[ReportManager sharedManager] deleteDay:selectedDay];
		[self reload];
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	NSInteger count = [self.daysByMonth count];
	if(count > 1 && indexPath.section == count){
		static NSString *CellIdentifier = @"CellTotale";
		
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if(cell == nil){
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil] autorelease];
		}
		
		float total = 0.0;
		for(NSArray *array in self.daysByMonth){
			for(Day *d in array){
				total += [d totalRevenueInBaseCurrency];
			}
		}
		
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.textLabel.text = [NSLocalizedString(@"Total:  ", nil) stringByAppendingString:[[CurrencyManager sharedManager] baseCurrencyDescriptionForAmount:[NSNumber numberWithFloat:total] withFraction:YES]]; 
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		
		return cell;
	}
	
	NSArray *selectedMonth = [self.daysByMonth objectAtIndex:indexPath.section];
	
    BOOL onlySum = NO;
	if(onlySum || indexPath.row == [selectedMonth count]){
		static NSString *CellIdentifier = @"CellSubtotale";
		
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if(cell == nil){
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil] autorelease];
		}
		
		//cell.selectionStyle = UITableViewCellSelectionStyleNone;
		float monthTotal = 0.0;
		for(Day *d in [self.daysByMonth objectAtIndex:indexPath.section]){
			monthTotal += [d totalRevenueInBaseCurrency];
		}
		
		if(!onlySum){
			Day *firstDayInSection = [[self.daysByMonth objectAtIndex:indexPath.section] objectAtIndex:0];
            if (self.calendarType == DayCalendarTypeCalendar) {
                cell.textLabel.text = [NSString stringWithFormat:@"%@:", [self.sectionTitleFormatter stringFromDate:firstDayInSection.date]];
            } else {
                AppleFiscalCalendar *calendar = [AppleFiscalCalendar sharedFiscalCalendar];
                cell.textLabel.text = [calendar fiscalMonthForDate:firstDayInSection.date];
            }
		}else
			cell.textLabel.text = NSLocalizedString(@"Subtotal:", nil);
		
		cell.textLabel.font = [UIFont boldSystemFontOfSize:18];
		cell.detailTextLabel.text = [[CurrencyManager sharedManager] baseCurrencyDescriptionForAmount:[NSNumber numberWithFloat:monthTotal] withFraction:YES];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		
		return cell;
	}
    
    static NSString *CellIdentifier = @"Cell";
    
    DayCell *cell = (DayCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[DayCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
    }

	Day *day = [[self.daysByMonth objectAtIndex:[indexPath section]] objectAtIndex:[indexPath row]];
	float revenue = [day totalRevenueInBaseCurrency];
	if (revenue > self.maxRevenue) {
		/* Got a new max revenue; we need to reload to update all already-displayed cells */
		self.maxRevenue = revenue;
		[[tableView class] cancelPreviousPerformRequestsWithTarget:tableView
														  selector:@selector(reloadData)
															object:nil];
		[tableView performSelector:@selector(reloadData)
						withObject:nil
						afterDelay:0];
	}
	cell.maxRevenue = self.maxRevenue;
	cell.day = day;
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	NSInteger count = self.daysByMonth.count;
	count = (count > 1 ? count + 1 : 1);//total
	return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSInteger count = self.daysByMonth.count;
    BOOL onlySum = NO;
	if(count > 1 && section == count){
		return 1;//total
	}
	
	if (count > 0) {
		if(onlySum)
			return 1;
		if(section == count)
			return 1;//total
		count = [[self.daysByMonth objectAtIndex:section] count];
		if(count > 1)
			count++;//subtotal
		return count;
	}
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{    
	NSInteger count = self.daysByMonth.count;
	if(count > 1 && section == count){
		return NSLocalizedString(@"Total:", nil); 
	}
	
	if (self.daysByMonth.count == 0)
		return @"";
	
	NSArray *sectionArray = [self.daysByMonth objectAtIndex:section];
	if (sectionArray.count == 0)
		return @"";
	
	Day *firstDayInSection = [sectionArray objectAtIndex:0];
    if (self.calendarType == DayCalendarTypeCalendar) {
        return [self.sectionTitleFormatter stringFromDate:firstDayInSection.date];
    } else {
        AppleFiscalCalendar *calendar = [AppleFiscalCalendar sharedFiscalCalendar];
        return [calendar fiscalMonthForDate:firstDayInSection.date];
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	int section = [indexPath section];
	int row = [indexPath row];

    NSString *totalRevenueKey = @"totalRevenueInBaseCurrency";
    NSString *sumTotalRevenueKey = @"@sum.totalRevenueInBaseCurrency";
    
	NSInteger count = [self.daysByMonth count];
	if(count > 1 && section == count){
		NSMutableDictionary *countries = [NSMutableDictionary dictionary];
		
		for(NSArray *array in self.daysByMonth){
			for(Day *d in array){
				for(Country *c in [d children]){
					Country *country = newCountry(c.name, countries);
					for (Entry *e in c.entries) {
						[country addEntry:e];
					}
				}
			}
		}
		
		NSSortDescriptor *sorter = [[[NSSortDescriptor alloc] initWithKey:totalRevenueKey ascending:NO] autorelease];
		NSArray *children = [[countries allValues] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sorter]];
		
		float total = [[children valueForKeyPath:sumTotalRevenueKey] floatValue];
		
		CountriesController *countriesController = [[[CountriesController alloc] initWithStyle:UITableViewStylePlain] autorelease];
		countriesController.totalRevenue = total;
		
		countriesController.title = NSLocalizedString(@"All time", nil);
		countriesController.countries = children;
		[countriesController.tableView reloadData];
		
		[[self navigationController] pushViewController:countriesController animated:YES];
		
		return;
	}
	
	NSArray *selectedMonth = [self.daysByMonth objectAtIndex:section];
    
    BOOL onlySum = NO;
	if(onlySum || row == [selectedMonth count]){
		NSMutableDictionary *countries = [NSMutableDictionary dictionary];
		
		for(Day *d in selectedMonth){
			for(Country *c in [d children]){
				Country *country = newCountry(c.name, countries);
				for (Entry *e in c.entries) {
					[country addEntry:e];
				}
			}
		}
		
		NSSortDescriptor *sorter = [[[NSSortDescriptor alloc] initWithKey:totalRevenueKey ascending:NO] autorelease];
		NSArray *children = [[countries allValues] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sorter]];
		
		float total = [[children valueForKeyPath:sumTotalRevenueKey] floatValue];
		
		CountriesController *countriesController = [[[CountriesController alloc] initWithStyle:UITableViewStylePlain] autorelease];
		countriesController.totalRevenue = total;
		
		Day *firstDayInSection = [[self.daysByMonth objectAtIndex:section] objectAtIndex:0];
		countriesController.title = [self.sectionTitleFormatter stringFromDate:firstDayInSection.date];
		countriesController.countries = children;
		[countriesController.tableView reloadData];
		
		[[self navigationController] pushViewController:countriesController animated:YES];
		
		return;
	}
	

//    NSArray *selectedMonth = [self.daysByMonth objectAtIndex:section];
	Day *selectedDay = [selectedMonth objectAtIndex:row];
	NSArray *children = [selectedDay children];
	
	float total = [[children valueForKeyPath:@"@sum.totalRevenueInBaseCurrency"] floatValue];
		
	CountriesController *countriesController = [[[CountriesController alloc] initWithStyle:UITableViewStylePlain] autorelease];
	countriesController.totalRevenue = total;
	
	NSDateFormatter *dateFormatter = [NSDateFormatter sharedMediumDateFormatter];
	NSString *formattedDate = [dateFormatter stringFromDate:selectedDay.date];
	countriesController.title = formattedDate;
	
	countriesController.countries = children;
	
	[[self navigationController] pushViewController:countriesController animated:YES];
}

@end

