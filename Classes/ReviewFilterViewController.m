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
#import "FilterTableViewCell.h"

@implementation ReviewFilterViewController

@synthesize filters, applied;

- (instancetype)initWithStyle:(UITableViewStyle)style {
	self = [super initWithStyle:UITableViewStyleGrouped];
	if (self) {
		// Initialization code
		self.title = NSLocalizedString(@"Filter", nil);
	}
	return self;
}

- (NSArray *)available {
	return [[filters.allKeys sortedArrayUsingSelector:@selector(compare:)] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
		return ![applied containsObject:evaluatedObject];
	}]];
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
	return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSInteger numberOfRows = 0;
	if (section == 0) {
		numberOfRows = applied.count ?: 1;
	} else if (section == 1) {
		numberOfRows = self.available.count ?: 1;
	}
	return numberOfRows;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NSString *headerTitle = nil;
	if (section == 0) {
		headerTitle = NSLocalizedString(@"Applied Filters", nil);
	} else if (section == 1) {
		headerTitle = NSLocalizedString(@"Available Filters", nil);
	}
	return headerTitle;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 44.0f;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return ((indexPath.section == 0) && applied.count);
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCellEditingStyle editingStyle = UITableViewCellEditingStyleNone;
	if (indexPath.section == 0) {
		editingStyle = UITableViewCellEditingStyleDelete;
	} else if ((indexPath.section == 1) && self.available.count) {
		editingStyle = UITableViewCellEditingStyleInsert;
	}
	return editingStyle;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"Cell";
	FilterTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[FilterTableViewCell alloc] initWithReuseIdentifier:CellIdentifier];
	}
	
	if (indexPath.section == 0) {
		if (applied.count) {
			NSNumber *index = applied[indexPath.row];
			ReviewFilter *filter = filters[index];
			
			cell.imageView.image = nil;
			cell.textLabel.text = filter.title;
			cell.textLabel.textColor = [UIColor blackColor];
			cell.detailTextLabel.text = filter.value;
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.selectionStyle = UITableViewCellSelectionStyleDefault;
		} else {
			cell.imageView.image = nil;
			cell.textLabel.text = NSLocalizedString(@"None", nil);
			cell.textLabel.textColor = [UIColor grayColor];
			cell.detailTextLabel.text = nil;
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
		}
	} else if (indexPath.section == 1) {
		if (self.available.count) {
			NSNumber *index = self.available[indexPath.row];
			ReviewFilter *filter = filters[index];
			
			cell.imageView.image = [UIImage imageNamed:@"AddButton"];
			cell.textLabel.text = filter.title;
			cell.textLabel.textColor = [UIColor blackColor];
			cell.detailTextLabel.text = nil;
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.selectionStyle = UITableViewCellSelectionStyleDefault;
		} else {
			cell.imageView.image = nil;
			cell.textLabel.text = NSLocalizedString(@"None", nil);
			cell.textLabel.textColor = [UIColor grayColor];
			cell.detailTextLabel.text = nil;
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
		}
	}
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if ((indexPath.section == 0) && (applied.count > 0)) {
		NSNumber *index = applied[indexPath.row];
		ReviewFilter *filter = filters[index];
		ReviewFilterDetailViewController *detailVC = [[ReviewFilterDetailViewController alloc] initWithFilter:filter];
		[self.navigationController pushViewController:detailVC animated:YES];
	} else if ((indexPath.section == 1) && (self.available.count > 0)) {
		[tableView beginUpdates];
		if (applied.count > 0) {
			[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
		} else {
			[tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0], indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
		}
		NSNumber *index = self.available[indexPath.row];
		[applied addObject:index];
		applied = [NSMutableArray arrayWithArray:[applied sortedArrayUsingSelector:@selector(compare:)]];
		if (self.available.count > 0) {
			[tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:[applied indexOfObject:index] inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
		} else {
			[tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:[applied indexOfObject:index] inSection:0], indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
		}
		[tableView endUpdates];
	}
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if ((indexPath.section == 0) && (applied.count > 0)) {
		[tableView beginUpdates];
		if (self.available.count > 0) {
			[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
		} else {
			[tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1], indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
		}
		NSNumber *index = applied[indexPath.row];
		ReviewFilter *filter = filters[index];
		filter.index = 0;
		[applied removeObjectAtIndex:indexPath.row];
		if (applied.count > 0) {
			[tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:[self.available indexOfObject:index] inSection:1]] withRowAnimation:UITableViewRowAnimationAutomatic];
		} else {
			[tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:[self.available indexOfObject:index] inSection:1], indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
		}
		[tableView endUpdates];
	}
}

@end
