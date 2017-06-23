//
//  ReviewFilterViewController.m
//  AppSales
//
//  Created by Nicolas Gomollon on 6/19/17.
//
//

#import "ReviewFilterViewController.h"
#import "ReviewFilterDetailViewController.h"
#import "ReviewFilter.h"
#import "ReviewFilterOption.h"
#import "ReviewFilterComparator.h"
#import "FilterTableViewCell.h"

@implementation ReviewFilterViewController

@synthesize filters;

- (instancetype)initWithStyle:(UITableViewStyle)style {
	self = [super initWithStyle:UITableViewStyleGrouped];
	if (self) {
		// Initialization code
		self.title = NSLocalizedString(@"Filter", nil);
	}
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	// Do any additional setup after loading the view.
	[self.tableView registerClass:[FilterTableViewCell class] forCellReuseIdentifier:@"Cell"];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return filters.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 44.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"Cell";
	FilterTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[FilterTableViewCell alloc] initWithReuseIdentifier:CellIdentifier];
	}
	
	ReviewFilter *filter = filters[indexPath.row];
	cell.textLabel.text = filter.title;
	if (!filter.isEnabled) {
		cell.detailTextLabel.text = NSLocalizedString(@"None", nil);
	} else {
		if (filter.cIndex > 0) {
			cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@", filter.selectedComparator.comparator, filter.value];
		} else {
			cell.detailTextLabel.text = filter.value;
		}
	}
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	cell.selectionStyle = UITableViewCellSelectionStyleDefault;
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	ReviewFilter *filter = filters[indexPath.row];
	ReviewFilterDetailViewController *detailVC = [[ReviewFilterDetailViewController alloc] initWithFilter:filter];
	[self.navigationController pushViewController:detailVC animated:YES];
}

@end
