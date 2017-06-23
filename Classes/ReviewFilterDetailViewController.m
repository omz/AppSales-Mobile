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
#import "ReviewFilterComparator.h"
#import "FilterDetailTableViewCell.h"

@implementation ReviewFilterDetailViewController

- (instancetype)initWithFilter:(ReviewFilter *)_filter {
	self = [super initWithStyle:UITableViewStyleGrouped];
	if (self) {
		// Initialization code
		filter = _filter;
		self.title = filter.title;
		hasInlineDatePicker = NO;
	}
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	// Do any additional setup after loading the view.
	switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
	switchView.on = filter.isEnabled;
	[switchView addTarget:self action:@selector(toggledSwitch) forControlEvents:UIControlEventValueChanged];
	
	pickerView = [[UIPickerView alloc] initWithFrame:CGRectZero];
	pickerView.dataSource = self;
	pickerView.delegate = self;
	
	[self.tableView registerClass:[FilterDetailTableViewCell class] forCellReuseIdentifier:@"Cell"];
	[self toggledSwitch];
}

- (void)toggledSwitch {
	filter.enabled = switchView.isOn;
	NSRange sections = NSMakeRange(1, (filter.comparators.count > 0) + 1);
	if (switchView.isOn) {
		[self.tableView insertSections:[NSIndexSet indexSetWithIndexesInRange:sections] withRowAnimation:UITableViewRowAnimationFade];
	} else {
		hasInlineDatePicker = NO;
		[self.tableView deleteSections:[NSIndexSet indexSetWithIndexesInRange:sections] withRowAnimation:UITableViewRowAnimationFade];
	}
}

#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
	return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
	return filter.comparators.count;
}

#pragma mark - UIPickerViewDelegate

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
	ReviewFilterComparator *comparator = filter.comparators[row];
	return comparator.comparator;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
	filter.cIndex = row;
	[self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	if (!switchView.isOn) { return 1; }
	return 1 + (filter.comparators.count > 0) + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSInteger numberOfRows = 0;
	if (section == 0) {
		numberOfRows = 1;
	} else if (section == (filter.comparators.count > 0)) {
		numberOfRows = 1 + hasInlineDatePicker;
	} else if (section == (1 + (filter.comparators.count > 0))) {
		numberOfRows = filter.options.count;
	}
	return numberOfRows;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	CGFloat heightForRow = 44.0f;
	if ((filter.comparators.count > 0) && (indexPath.section == 1) && (indexPath.row == 1)) {
		heightForRow = 216.0f;
	}
	return heightForRow;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *CellIdentifier = @"Cell";
	if ((filter.comparators.count > 0) && (indexPath.section == 1)) {
		if (indexPath.row == 0) {
			CellIdentifier = @"PickerDetailCell";
		} else if (indexPath.row == 1) {
			CellIdentifier = @"PickerViewCell";
		}
	}
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		if ((filter.comparators.count > 0) && (indexPath.section == 1)) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
		} else {
			cell = [[FilterDetailTableViewCell alloc] initWithReuseIdentifier:CellIdentifier];
		}
	}
	
	if (indexPath.section == 0) {
		cell.textLabel.text = NSLocalizedString(@"Enable Filter", nil);
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.accessoryType = UITableViewCellAccessoryNone;
		cell.accessoryView = switchView;
	} else if (indexPath.section == (filter.comparators.count > 0)) {
		if (indexPath.row == 0) {
			ReviewFilterComparator *comparator = filter.selectedComparator;
			cell.textLabel.text = comparator.comparator;
			cell.detailTextLabel.text = comparator.title;
			cell.selectionStyle = UITableViewCellSelectionStyleDefault;
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.accessoryView = nil;
		} else if (indexPath.row == 1) {
			cell.textLabel.text = nil;
			cell.detailTextLabel.text = nil;
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.accessoryView = nil;
			[cell.contentView addSubview:pickerView];
		}
	} else if (indexPath.section == (1 + (filter.comparators.count > 0))) {
		ReviewFilterOption *option = filter.options[indexPath.row];
		cell.textLabel.text = option.title;
		cell.detailTextLabel.text = option.subtitle;
		cell.selectionStyle = UITableViewCellSelectionStyleDefault;
		cell.accessoryType = (indexPath.row == filter.index) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
		cell.accessoryView = nil;
	}
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if (indexPath.section == (filter.comparators.count > 0)) {
		if (indexPath.row == 0) {
			hasInlineDatePicker = !hasInlineDatePicker;
			if (hasInlineDatePicker) {
				[pickerView selectRow:filter.cIndex inComponent:0 animated:NO];
				[tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:1]] withRowAnimation:UITableViewRowAnimationFade];
			} else {
				[tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:1]] withRowAnimation:UITableViewRowAnimationFade];
			}
		}
	} else if (indexPath.section == (1 + (filter.comparators.count > 0))) {
		filter.index = indexPath.row;
		[tableView reloadData];
		[self.navigationController popViewControllerAnimated:YES];
	}
}

@end
