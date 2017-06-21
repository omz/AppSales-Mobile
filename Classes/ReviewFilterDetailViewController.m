//
//  ReviewFilterDetailViewController.m
//  AppSales
//
//  Created by Nicolas Gomollon on 6/21/17.
//
//

#import "ReviewFilterDetailViewController.h"
#import "ReviewFilter.h"
#import "ReviewFilterOption.h"
#import "FilterDetailTableViewCell.h"

@implementation ReviewFilterDetailViewController

- (instancetype)initWithFilter:(ReviewFilter *)_filter {
	self = [super initWithStyle:UITableViewStyleGrouped];
	if (self) {
		// Initialization code
		filter = _filter;
		self.title = filter.title;
	}
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	// Do any additional setup after loading the view.
	[self.tableView registerClass:[FilterDetailTableViewCell class] forCellReuseIdentifier:@"Cell"];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSInteger numberOfRows = 0;
	if (section == 0) {
		numberOfRows = 1;
	} else if (section == 1) {
		numberOfRows = filter.options.count - 1;
	}
	return numberOfRows;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 44.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"Cell";
	FilterDetailTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[FilterDetailTableViewCell alloc] initWithReuseIdentifier:CellIdentifier];
	}
	
	NSInteger index = indexPath.section + indexPath.row;
	ReviewFilterOption *option = filter.options[index];
	cell.textLabel.text = option.title;
	cell.detailTextLabel.text = option.subtitle;
	cell.accessoryType = (index == filter.index) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	NSInteger index = indexPath.section + indexPath.row;
	filter.index = index;
	[tableView reloadData];
	[self.navigationController popViewControllerAnimated:YES];
}

@end
