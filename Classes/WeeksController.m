/*
 WeeksController.m
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


#import "WeeksController.h"
#import "Day.h"
#import "WeekCell.h"
#import "CountriesController.h"
#import "RootViewController.h"
#import "CurrencyManager.h"
#import "ReportManager.h"
#import "Country.h"
#import "NSDateFormatter+SharedInstances.h"

#define BACK_GROUND_COLOR [UIColor colorWithRed:0.92 green:1.0 blue:0.92 alpha:1.0]

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


@implementation PrevisionReport
@synthesize dayString, weekEndDateString, revenue, newMonth;
- (void) dealloc
{
	self.dayString = nil;
	self.weekEndDateString = nil;
	[super dealloc];
}
@end


@interface PrevisionWeekCell : UITableViewCell {
@private
	UILabel *dayLabel;
	UILabel *weekdayLabel;
	UILabel *revenueLabel;
	UIView *graphView;
	float maxRevenue;
}
@property (assign) float maxRevenue;
- (void)setPrevisonReport:(PrevisionReport *)report;
@end


@implementation PrevisionWeekCell

@synthesize maxRevenue;

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier {
	if (self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier]) {
		UIColor *calendarBackgroundColor = [UIColor colorWithRed:0.84 green:1.0 blue:0.84 alpha:1.0];
		UIView *calendarBackgroundView = [[[UIView alloc] initWithFrame:CGRectMake(0,0,45,44)] autorelease];
		calendarBackgroundView.backgroundColor = calendarBackgroundColor;
		
		dayLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 45, 30)] autorelease];
		dayLabel.textAlignment = UITextAlignmentCenter;
		dayLabel.font = [UIFont boldSystemFontOfSize:22.0];
		dayLabel.backgroundColor = calendarBackgroundColor;
		
		weekdayLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, 27, 45, 14)] autorelease];
		weekdayLabel.textAlignment = UITextAlignmentCenter;
		weekdayLabel.font = [UIFont systemFontOfSize:10.0];
		weekdayLabel.backgroundColor = calendarBackgroundColor;
		
        UIColor *backgroundColor = BACK_GROUND_COLOR;
		revenueLabel = [[[UILabel alloc] initWithFrame:CGRectMake(50, 8/*0*/, 100, 30)] autorelease];
		revenueLabel.font = [UIFont boldSystemFontOfSize:20.0];
		revenueLabel.textAlignment = UITextAlignmentRight;
		revenueLabel.adjustsFontSizeToFitWidth = YES;
		revenueLabel.backgroundColor = backgroundColor;
		
		graphView = [[[UIView alloc] initWithFrame:CGRectMake(160, 10, 130, 25)] autorelease];
		graphView.backgroundColor = [UIColor colorWithRed:0.22 green:1.0 blue:0.49 alpha:1.0];
		
		[self.contentView addSubview:calendarBackgroundView];
		[self.contentView addSubview:dayLabel];
		[self.contentView addSubview:weekdayLabel];
		[self.contentView addSubview:revenueLabel];
		[self.contentView addSubview:graphView];
		
		self.maxRevenue = 0;
		
		self.contentView.backgroundColor = backgroundColor;
    }
    return self;
}

- (void)setPrevisonReport:(PrevisionReport *)report {
	dayLabel.text = report.dayString;
	weekdayLabel.text = report.weekEndDateString;
	revenueLabel.text = [[CurrencyManager sharedManager] baseCurrencyDescriptionForAmount:[NSNumber numberWithFloat:report.revenue] withFraction:YES];
	graphView.frame = CGRectMake(160, 12, 130.0 * (self.maxRevenue ? (report.revenue / self.maxRevenue) : 0), 21);
}

@end


@implementation WeeksController

@synthesize previsionReport;

- (id)init
{
	self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"Weekly Reports",nil);
        
        UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Only sum", nil) 
                                                                   style:UIBarButtonItemStyleBordered 
                                                                  target:self 
                                                                  action:@selector(onlySum:)];
        self.navigationItem.rightBarButtonItem = button;
        [button release];
    }	
	return self;
}

- (void)onlySum:(id)sender {
	onlySum = !onlySum;
	[self.navigationItem.rightBarButtonItem setStyle:onlySum ? UIBarButtonItemStyleDone : UIBarButtonItemStyleBordered];
	[self.tableView reloadData];
}

- (NSIndexPath*) adjustPathForCurrentView:(NSIndexPath*)path {
    if(!onlySum && previsionReport){
        if(previsionReport.newMonth)
            return [NSIndexPath indexPathForRow:path.row inSection:path.section-1];
        if(path.section == 0)
            return [NSIndexPath indexPathForRow:path.row-1 inSection:path.section];
    }
    return path;
}

- (void)reload
{
	self.daysByMonth = [NSMutableArray array];
	
	NSSortDescriptor *dateSorter = [[[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO] autorelease];
	NSArray *sortedWeeks = [[[ReportManager sharedManager].weeks allValues] sortedArrayUsingDescriptors:[NSArray arrayWithObject:dateSorter]];
	int lastMonth = -1;
	int firstMonth = -1;
	int numeberOfMonths = 0;
	float max = 0;
    NSCalendar *calendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	for (Day *d in sortedWeeks) {
		float revenue = [d totalRevenueInBaseCurrency];
		if (revenue > max)
			max = revenue;
		NSDate *date = d.date;
		NSDateComponents *components = [calendar components:NSMonthCalendarUnit fromDate:date];
		int month = [components month];
		if (month != lastMonth) {
			if (lastMonth == -1)
				firstMonth = month;
			[daysByMonth addObject:[NSMutableArray array]];
			lastMonth = month;
		}
		[[daysByMonth lastObject] addObject:d];
		numeberOfMonths++;
	}
	
	//Prevision
	self.previsionReport = nil; 
	if(numeberOfMonths > 0){
		NSDate *firstDayLastWeek = ((Day *)[[daysByMonth objectAtIndex:0] objectAtIndex:0]).date;
		NSArray *sortedDays = [[[ReportManager sharedManager].days allValues] sortedArrayUsingDescriptors:[NSArray arrayWithObject:dateSorter]];
		if(sortedDays.count > 0 && [((Day *)[sortedDays objectAtIndex:0]).date timeIntervalSinceDate:firstDayLastWeek] >= 691200){ //8 days
			//days of the current week
			NSMutableArray *newWeekDays = [NSMutableArray array];
			//days of the last ended week
			NSMutableArray *lastWeekDays = [NSMutableArray array];
			
			NSString *dayString = nil;
			NSString *weekEndDateString;
			BOOL newMonth = NO;
            
            NSDateFormatter *dateFormatter = [NSDateFormatter sharedShortDateFormatter];
			
			for(Day *d in sortedDays){
				NSTimeInterval diff = [d.date timeIntervalSinceDate:firstDayLastWeek];
				if(diff >= 604800){//7 days: 1 week
					[newWeekDays insertObject:d atIndex:0];
					if(diff == 604800){
						NSDateComponents *components = [calendar components:NSDayCalendarUnit | NSMonthCalendarUnit fromDate:d.date];
						dayString = [NSString stringWithFormat:@"%i", [components day]];
                        
						int month = [components month];
						if (month != firstMonth) // FIXME
							newMonth = YES;
						
						NSDateComponents *comp = [[[NSDateComponents alloc] init] autorelease];
						[comp setHour:167];
						NSDate *dateWeekLater = [calendar dateByAddingComponents:comp toDate:d.date options:0];
						weekEndDateString = [dateFormatter stringFromDate:dateWeekLater];
					}
				}else if(diff >= 0){
					[lastWeekDays insertObject:d atIndex:0];
				}else
					break;
			}
			if([newWeekDays count] > 0 && [newWeekDays count] <= 7 
			   && [lastWeekDays count] == 7){
				//prevision
				float revenueNewWeek = 0;
				float revenueLastWeek = 0;
				for(NSUInteger i = 0; i < [newWeekDays count]; i++){
					revenueNewWeek += [[newWeekDays objectAtIndex:i] totalRevenueInBaseCurrency];
					revenueLastWeek += [[lastWeekDays objectAtIndex:i] totalRevenueInBaseCurrency];					
				}
				float revenue = [[[daysByMonth objectAtIndex:0] objectAtIndex:0] totalRevenueInBaseCurrency] * revenueNewWeek / revenueLastWeek;
				if(revenue > max)
					max = revenue;
				self.previsionReport = [[PrevisionReport new] autorelease];
				self.previsionReport.revenue = revenue;
				self.previsionReport.dayString = dayString;
				self.previsionReport.weekEndDateString = weekEndDateString;
				self.previsionReport.newMonth = newMonth;
			}
		}
	}
	
	self.maxRevenue = max;
	[self.tableView reloadData];
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self reload];	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) 
												 name:ReportManagerDownloadedWeeklyReportsNotification object:nil];
}

- (void) viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath 
{ 
	if (editingStyle == UITableViewCellEditingStyleDelete) {
        indexPath = [self adjustPathForCurrentView:indexPath];
        
		NSArray *selectedMonth = [self.daysByMonth objectAtIndex:indexPath.section];
		Day *selectedDay = [selectedMonth objectAtIndex:indexPath.row];
		[[ReportManager sharedManager] deleteDay:selectedDay];
		[self reload];
	}
}


- (void)dealloc 
{
	self.daysByMonth = nil;
	self.previsionReport = nil;
    [super dealloc];
}

- (BOOL) isPrevisionReportIndex:(NSIndexPath*)indexPath
{
	return !onlySum && previsionReport && indexPath.section == 0 && indexPath.row == 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{	
	if([self isPrevisionReportIndex:indexPath]){
		static NSString *CellIdentifier = @"CellPrevisione";
		
		PrevisionWeekCell *cell = (PrevisionWeekCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (cell == nil) {
			cell = [[[PrevisionWeekCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
		}
		
		cell.maxRevenue = self.maxRevenue;
		[cell setPrevisonReport:previsionReport];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		
		return cell;
	}
    indexPath = [self adjustPathForCurrentView:indexPath];
    int section = [indexPath section];
	int row = [indexPath row];
	
	NSInteger count = [self.daysByMonth count];
	if(count > 1 && section == count){
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
	
	NSArray *selectedMonth = [self.daysByMonth objectAtIndex:section];
	
	if(onlySum || row == [selectedMonth count]){
		static NSString *CellIdentifier = @"CellSubtotale";
		
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if(cell == nil){
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil] autorelease];
		}
		
		//cell.selectionStyle = UITableViewCellSelectionStyleNone;
		float weekTotal = 0.0;
		for(Day *d in [self.daysByMonth objectAtIndex:section]){
			weekTotal += [d totalRevenueInBaseCurrency];
		}
		
		if(!onlySum){
			Day *firstDayInSection = [[self.daysByMonth objectAtIndex:section] objectAtIndex:0];
			cell.textLabel.text = [NSString stringWithFormat:@"%@:", [self.sectionTitleFormatter stringFromDate:firstDayInSection.date]];
		}else
			cell.textLabel.text = NSLocalizedString(@"Subtotal:", nil);
		
		cell.textLabel.font = [UIFont boldSystemFontOfSize:18];
		cell.detailTextLabel.text = [[CurrencyManager sharedManager] baseCurrencyDescriptionForAmount:[NSNumber numberWithFloat:weekTotal] withFraction:YES];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		
		return cell;
	}
	
	Day *selectedDay = [selectedMonth objectAtIndex:row];
    
    static NSString *CellIdentifier = @"Cell";
    
    WeekCell *cell = (WeekCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[WeekCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
    }
    
	cell.maxRevenue = self.maxRevenue;
    cell.day = selectedDay;
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{	
    if ([self isPrevisionReportIndex:indexPath])
		return;
    
    indexPath = [self adjustPathForCurrentView:indexPath];
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
	
	Day *selectedDay = [selectedMonth objectAtIndex:row];
	NSArray *children = [selectedDay children];
    
	float total = [[children valueForKeyPath:sumTotalRevenueKey] floatValue];
	
	CountriesController *countriesController = [[[CountriesController alloc] initWithStyle:UITableViewStylePlain] autorelease];
	countriesController.totalRevenue = total;
	
	NSDateFormatter *dateFormatter = [NSDateFormatter sharedShortDateFormatter];
	NSString *formattedDate1 = [dateFormatter stringFromDate:selectedDay.date];
    
	NSString *weekDesc;
	if ([self.title isEqualToString:NSLocalizedString(@"Total",nil)]) {
		weekDesc = NSLocalizedString(@"Total",nil);
	}
	else {
		NSDateComponents *comp = [[[NSDateComponents alloc] init] autorelease];
		[comp setHour:167];
        NSCalendar *calendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
		NSDate *dateWeekLater = [calendar dateByAddingComponents:comp toDate:selectedDay.date options:0];
		NSString *formattedDate2 = [dateFormatter stringFromDate:dateWeekLater];
		weekDesc = [NSString stringWithFormat:@"%@ - %@", formattedDate1, formattedDate2];
	}
    
	countriesController.title = weekDesc;
	countriesController.countries = children;
	[countriesController.tableView reloadData];
	
	[[self navigationController] pushViewController:countriesController animated:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	NSInteger count = self.daysByMonth.count;
	count = (count > 1 ? count + 1 : 1);//total
	if(!onlySum && previsionReport && previsionReport.newMonth)
		count++;
	return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSInteger count = self.daysByMonth.count;
	if(!onlySum && previsionReport && previsionReport.newMonth){
		if(section == 0)
			return 1;
		else
			section--;
	}
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
		if(section == 0 && previsionReport && previsionReport.newMonth == NO)
			count++;
		return count;
	}
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{    
	if(!onlySum && previsionReport && previsionReport.newMonth){
		if(section == 0)
			return @"";
		else
			section--;
	}
	
	NSInteger count = self.daysByMonth.count;
	if(count > 1 && section == count){
		return NSLocalizedString(@"Total:", nil); 
	}
	
	if (self.daysByMonth.count == 0)
		return @"";
	
	NSArray *sectionArray = [daysByMonth objectAtIndex:section];
	if (sectionArray.count == 0)
		return @"";
	
	Day *firstDayInSection = [sectionArray objectAtIndex:0];
	return [self.sectionTitleFormatter stringFromDate:firstDayInSection.date];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath 
{
	if(onlySum)
		return NO;
    
    if ([self isPrevisionReportIndex:indexPath])
		return NO;
    
    indexPath = [self adjustPathForCurrentView:indexPath];
    int section = [indexPath section];
	int row = [indexPath row];
    
    // this was originally here before refactoring to use adjustPathForCurrentView,
    // but the code here commented out is slightly different than the refactored version
    // might have been a mistake, might have been intentional....
    //	if(!onlySum && previsionReport){
    //		if(section)
    //			section--;
    //		else
    //			row--;
    //	}
	
	NSInteger count = self.daysByMonth.count;
	if(count > 1 && section == count){
		return NO;
	}
	if(row == [[self.daysByMonth objectAtIndex:section] count]){
		return NO;
	}
	return YES;
}

@end
