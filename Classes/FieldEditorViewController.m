//
//  FieldEditorViewController.m
//  AppSales
//
//  Created by Ole Zorn on 20.04.09.
//  Copyright 2009 omz:software. All rights reserved.
//

#import "FieldEditorViewController.h"
#import "IconManager.h"

#define TEXTFIELDTAG					1
#define SWITCHTAG						2

#define AttributeKey					@"key"
#define AttributeTitle					@"title"
#define AttributeType					@"type"
#define AttributeDefault				@"default"

#define AttributeSectionTitle			@"title"
#define AttributeSectionDescription		@"description"
#define AttributeSectionAttributes		@"attributes"

#define AttributeTypePassword			@"password"
#define AttributeTypeEmail				@"email"
#define	AttributeTypeURL				@"URL"
#define AttributeTypeSwitch				@"switch"

@implementation FieldEditorViewController

@synthesize fieldSections, values, doneButtonTitle, cancelButtonTitle, delegate, context, editorIdentifier;
@synthesize isSubSection, hasChanges, selectedTextField;

- (instancetype)initWithFieldSections:(NSArray *)sections title:(NSString *)title {
	if (self = [super initWithStyle:UITableViewStyleGrouped]) {
		self.title = title;
		self.values = [NSMutableDictionary dictionary];
		self.fieldSections = sections;
		for (FieldSectionSpecifier *section in fieldSections) {
			NSArray *fields = section.fields;
			for (FieldSpecifier *field in fields) {
				NSString *key = field.key;
				id defaultValue = field.defaultValue;
				if (defaultValue)
					[values setObject:defaultValue forKey:key];
				if (field.type == FieldSpecifierTypeSection) {
					NSArray *subsections = field.subsections;
					for (FieldSectionSpecifier *section in subsections) {
						for (FieldSpecifier *subsectionField in section.fields) {
							NSString *key = subsectionField.key;
							id defaultValue = subsectionField.defaultValue;
							if (defaultValue)
								[values setObject:defaultValue forKey:key];
						}
					}
				}
			}
		}
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChange:) name:UITextFieldTextDidChangeNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldWillBeginEditing:) name:UITextFieldTextDidBeginEditingNotification object:nil];
	}
	return self;
}


- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	if (!self.isSubSection) {
		if (self.doneButtonTitle) {
			UIBarButtonItem *doneButtonItem = [[UIBarButtonItem alloc] initWithTitle:self.doneButtonTitle style:UIBarButtonItemStyleDone target:self action:@selector(done)];
			if (self.showDoneButtonOnLeft) {
				self.navigationItem.leftBarButtonItem = doneButtonItem;
			} else {
				self.navigationItem.rightBarButtonItem = doneButtonItem;
			}
		}
		if (self.cancelButtonTitle) {
			UIBarButtonItem *cancelButtonItem = [[UIBarButtonItem alloc] initWithTitle:self.cancelButtonTitle style:UIBarButtonItemStylePlain target:self action:@selector(cancel)];
			self.navigationItem.leftBarButtonItem = cancelButtonItem;
		}
		if ([self.fieldSections count] == 1 && [[self.fieldSections[0] fields] count] == 1) {
			FieldSpecifierType singleFieldType = [(FieldSpecifier *)[self.fieldSections[0] fields][0] type];
			if (singleFieldType == FieldSpecifierTypeNumeric || singleFieldType == FieldSpecifierTypeEmail || singleFieldType == FieldSpecifierTypePassword || singleFieldType == FieldSpecifierTypeText || singleFieldType == FieldSpecifierTypeURL) {
				UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
				UIView *textField = [cell viewWithTag:TEXTFIELDTAG];
				if (textField) {
					[(UITextField *)textField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0];
					self.selectedTextField = (UITextField *)textField;
				}
			}
		}
	}
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	if (self.isSubSection) {
		if (!isOpeningSubsection) {
			[self done];
		}
	} else {
		if (!self.doneButtonTitle && !isOpeningSubsection) {
			[self done];
		}
	}
}

- (void)done {
	if (self.delegate && [self.delegate respondsToSelector:@selector(fieldEditor:didFinishEditingWithValues:)]) {
		[delegate fieldEditor:self didFinishEditingWithValues:self.values];
	}
}

- (void)cancel {
	if (self.delegate && [self.delegate respondsToSelector:@selector(fieldEditorDidCancel:)]) {
		[delegate fieldEditorDidCancel:self];
	}
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
}

- (void)textFieldDidChange:(NSNotification *)note {
	if ([[note object] isKindOfClass:[NamedTextField class]]) {
		self.hasChanges = YES;
		NamedTextField *textField = [note object];
		NSString *name = textField.name;
		[self.values setObject:textField.text forKey:name];
	}
}

- (void)textFieldWillBeginEditing:(NSNotification *)note {
	NamedTextField *textField = [note object];
	if ([textField isKindOfClass:[NamedTextField class]]) {
		NSString *name = [textField name];
		int s = 0;
		int r = 0;
		BOOL found = NO;
		for (FieldSectionSpecifier *section in fieldSections) {
			for (FieldSpecifier *field in section.fields) {
				if ([field.key isEqual:name]) {
					found = YES;
					break;
				}
				r++;
			}
			if (found) break;
			s++;
			r = 0;
		}
		if (found) {
			[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:r inSection:s] atScrollPosition:UITableViewScrollPositionNone animated:YES];
		}
	}
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	self.selectedTextField = textField;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField performSelector:@selector(resignFirstResponder) withObject:nil afterDelay:0];
	self.selectedTextField = nil;
	return YES;
}

- (void)dismissKeyboard {
	[self.selectedTextField resignFirstResponder];
}

- (void)switchValueDidChange:(NamedSwitch *)switchControl {
	self.hasChanges = YES;
	[self.values setObject:@(switchControl.on) forKey:switchControl.name];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView  {
	return [self.fieldSections count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex {
	FieldSectionSpecifier *section = self.fieldSections[sectionIndex];
	return [section.fields count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)sectionIndex {
	FieldSectionSpecifier *section = self.fieldSections[sectionIndex];
	return section.title;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)sectionIndex {
	FieldSectionSpecifier *section = self.fieldSections[sectionIndex];
	return section.description;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	[[cell.contentView viewWithTag:TEXTFIELDTAG] removeFromSuperview];
	[[cell.contentView viewWithTag:SWITCHTAG] removeFromSuperview];
	
	FieldSectionSpecifier *section = self.fieldSections[indexPath.section];
	NSArray *fields = section.fields;
	FieldSpecifier *field = fields[indexPath.row];
	cell.textLabel.text = field.title;
	cell.textLabel.textAlignment = NSTextAlignmentLeft;
	cell.textLabel.font = [UIFont boldSystemFontOfSize:16.0];
	cell.accessoryType = UITableViewCellAccessoryNone;
	CGSize labelSize = [field.title sizeWithAttributes:@{NSFontAttributeName : cell.textLabel.font}];
	CGRect textLabelFrame = CGRectMake(20, 0, labelSize.width, 10);
	
	cell.detailTextLabel.text = @"";
	
	NSString *key = field.key;
	FieldSpecifierType type = field.type;
	
	if ((type == FieldSpecifierTypeEmail) || (type == FieldSpecifierTypePassword) || (type == FieldSpecifierTypeURL) || (type == FieldSpecifierTypeText) || (type == FieldSpecifierTypeNumeric)) {
		CGRect textFieldFrame = CGRectMake(textLabelFrame.origin.x + textLabelFrame.size.width + 10,
										   11,
										   cell.contentView.frame.size.width - textLabelFrame.size.width - textLabelFrame.origin.x - 20,
										   25);
		NamedTextField *textField = [[NamedTextField alloc] initWithFrame:textFieldFrame];
		if (self.navigationController.navigationBar.barStyle == UIBarStyleBlack) {
			textField.keyboardAppearance = UIKeyboardAppearanceAlert;
		} else {
			textField.keyboardAppearance = UIKeyboardAppearanceDefault;
		}
		textField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		textField.textColor = cell.detailTextLabel.textColor;
		textField.tag = TEXTFIELDTAG;
		textField.name = key;
		textField.text = self.values[key];
		textField.autocorrectionType = UITextAutocorrectionTypeNo;
		textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
		textField.clearButtonMode = UITextFieldViewModeWhileEditing;
		textField.delegate = self;
		if (type == FieldSpecifierTypeEmail) {
			textField.placeholder = NSLocalizedString(@"example@domain.com",nil);
			textField.keyboardType = UIKeyboardTypeEmailAddress;
			textField.secureTextEntry = NO;
		} else if (type == FieldSpecifierTypePassword) {
			textField.placeholder = @"";
			textField.keyboardType = UIKeyboardTypeAlphabet;
			textField.secureTextEntry = YES;
		} else if (type == FieldSpecifierTypeURL) {
			textField.placeholder = NSLocalizedString(@"www.example.com",nil);
			textField.keyboardType = UIKeyboardTypeURL;
			textField.secureTextEntry = NO;
		} else if (type == FieldSpecifierTypeText) {
			textField.keyboardType = UIKeyboardTypeDefault;
			textField.secureTextEntry = NO;
		} else if (type == FieldSpecifierTypeNumeric) {
			textField.keyboardType = UIKeyboardTypeNumberPad;
			textField.secureTextEntry = NO;
		}
		if (field.placeholder) {
			textField.placeholder = field.placeholder;
		}
		[cell.contentView addSubview:textField];
	} else if (type == FieldSpecifierTypeSwitch) {
		NamedSwitch *switchControl = [[NamedSwitch alloc] init];
		CGSize switchSize = switchControl.frame.size;
		CGSize contentSize = cell.contentView.bounds.size;
		CGRect switchFrame = CGRectMake(contentSize.width - switchSize.width - 8, 8, switchSize.width, switchSize.height);
		switchControl.frame = switchFrame;
		switchControl.tag = SWITCHTAG;
		switchControl.name = key;
		switchControl.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
		BOOL value = [self.values[key] boolValue];
		[switchControl setOn:value animated:NO];
		[switchControl addTarget:self action:@selector(switchValueDidChange:) forControlEvents:UIControlEventValueChanged];
		[cell.contentView addSubview:switchControl];
	} else if (type == FieldSpecifierTypeCheck) {
		BOOL value = [self.values[key] boolValue];
		if (value) {
			cell.accessoryType = UITableViewCellAccessoryCheckmark;
		} else {
			cell.accessoryType = UITableViewCellAccessoryNone;
		}
	} else if (type == FieldSpecifierTypeSection) {
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		if ([field.subsections count] == 1) {
			FieldSectionSpecifier *subsection = field.subsections[0];
			if ([subsection exclusiveSelection]) {
				NSArray *subSectionFields = subsection.fields;
				for (FieldSpecifier *f in subSectionFields) {
					if ([values[f.key] boolValue] == YES) {
						cell.detailTextLabel.text = [f title];
						break;
					}
				}
			}
		}
	}
	if (field.type == FieldSpecifierTypeButton) {
		cell.detailTextLabel.text = field.defaultValue;
	}
	if (field.type == FieldSpecifierTypeButton && field.shouldDisplayDisclosureIndicator) {
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath  {	
	UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Cell"];
	
	FieldSectionSpecifier *section = self.fieldSections[indexPath.section];
	NSArray *fields = section.fields;
	
	FieldSpecifier *field = fields[indexPath.row];
	if (field.type != FieldSpecifierTypeButton && field.type != FieldSpecifierTypeSection && field.type != FieldSpecifierTypeCheck) {
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	}
	
	// Add app icons.
	if ([field.key containsString:@"product.section"]) {
		NSString *productID = [field.key substringFromIndex:[@"product.section." length]];
		UIImage *image = [[IconManager sharedManager] iconForAppID:productID];
		
		CGFloat iconSize = 30.0f;
		CGFloat iconOriginY = (cell.imageView.frame.size.height - iconSize) / 2.0f;
		cell.imageView.frame = CGRectMake(CGRectGetMaxX(cell.imageView.frame) + 12.0, iconOriginY, iconSize, iconSize);
		
		cell.imageView.image = image;
		cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
		cell.imageView.clipsToBounds = YES;
		cell.imageView.layer.cornerRadius = roundf(7.0f / (30.0f / cell.imageView.frame.size.width));
		cell.imageView.layer.borderColor = [[UIColor blackColor] colorWithAlphaComponent:0.1f].CGColor;
		cell.imageView.layer.borderWidth = 0.5f;
		
		CGSize itemSize = CGSizeMake(iconSize, iconSize);
		UIGraphicsBeginImageContextWithOptions(itemSize, NO, UIScreen.mainScreen.scale);
		CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
		
		[cell.imageView.image drawInRect:imageRect];
		cell.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
	}
	
	cell.textLabel.text = field.title;
	return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath  {
	FieldSectionSpecifier *section = self.fieldSections[indexPath.section];
	NSArray *fields = section.fields;
	FieldSpecifier *field = fields[indexPath.row];
		
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	UIView *textField = [cell viewWithTag:TEXTFIELDTAG];
	if (textField) {
		[(UITextField *)textField becomeFirstResponder];
		self.selectedTextField = (UITextField *)textField;
	}
	if (field.type == FieldSpecifierTypeCheck) {
		self.hasChanges = YES;
		NSString *key = field.key;
		BOOL value = [self.values[key] boolValue];
		if (section.exclusiveSelection) {
			for (FieldSpecifier *f in section.fields) {
				[self.values setObject:@(NO) forKey:f.key];
			}
			[self.values setObject:@(YES) forKey:key];
		} else {
			[self.values setObject:@(!value) forKey:key];
		}
		BOOL newValue = [self.values[key] boolValue];
		if (newValue) {
			cell.accessoryType = UITableViewCellAccessoryCheckmark;
		} else {
			cell.accessoryType = UITableViewCellAccessoryNone;
		}
		[self.tableView reloadData];
		[self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
		[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
	} else if (field.type == FieldSpecifierTypeButton) {
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
		if ((self.delegate) && ([delegate respondsToSelector:@selector(fieldEditor:pressedButtonWithKey:)])) {
			[delegate fieldEditor:self pressedButtonWithKey:field.key];
		}
	} else if (field.type == FieldSpecifierTypeSection) {
		[self openSubsection:field];
	}
}

- (void)openSubsection:(FieldSpecifier *)subsectionField {
	isOpeningSubsection = YES;
	
	NSArray *sections = subsectionField.subsections;
	for (FieldSectionSpecifier *section in sections) {
		for (FieldSpecifier *field in section.fields) {
			if (values[field.key]) {
				field.defaultValue = values[field.key];
			}
		}
	}
	FieldEditorViewController *subController = [[FieldEditorViewController alloc] initWithFieldSections:sections title:@""];
	subController.preferredContentSize = self.preferredContentSize;
	subController.title = subsectionField.title;
	subController.delegate = self;
	subController.doneButtonTitle = NSLocalizedString(@"Save",nil);
	subController.cancelButtonTitle = NSLocalizedString(@"Cancel",nil);
	subController.isSubSection = YES;
	
	[self.navigationController pushViewController:subController animated:YES];
}

- (void)fieldEditor:(FieldEditorViewController *)editor pressedButtonWithKey:(NSString *)key {
	if ([self.delegate respondsToSelector:@selector(fieldEditor:pressedButtonWithKey:)]) {
		[delegate fieldEditor:self pressedButtonWithKey:key];
	}
}

- (void)fieldEditor:(FieldEditorViewController *)editor didFinishEditingWithValues:(NSDictionary *)returnValues {
	isOpeningSubsection = NO;
	if (editor.hasChanges) {
		self.hasChanges = YES;
	}
	[self.values addEntriesFromDictionary:returnValues];
	[self.tableView reloadData];
}

- (void)fieldEditorDidCancel:(FieldEditorViewController *)editor {
	isOpeningSubsection = NO;
	[self.navigationController popToViewController:self animated:YES];
}

- (void)dealloc  {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        return UIInterfaceOrientationMaskAll;
    }
    return UIInterfaceOrientationMaskPortrait;
}

@end



@implementation NamedTextField

@synthesize name;

@end



@implementation NamedSwitch

@synthesize name;

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end



@implementation FieldSectionSpecifier

@synthesize fields, title, description, exclusiveSelection;

+ (FieldSectionSpecifier *)sectionWithFields:(NSArray *)f title:(NSString *)t description:(NSString *)d {
	FieldSectionSpecifier *section = [FieldSectionSpecifier new];
	section.fields = f;
	section.title = t;
	section.description = d;
	section.exclusiveSelection = NO;
	return section;
}

@end



@implementation FieldSpecifier

@synthesize type, subsections, key, title, defaultValue, placeholder, shouldDisplayDisclosureIndicator;

+ (FieldSpecifier *)fieldWithType:(FieldSpecifierType)t key:(NSString *)k {
	FieldSpecifier *field = [FieldSpecifier new];
	field.type = t;
	field.key = k;
	return field;
}

+ (FieldSpecifier *)switchFieldWithKey:(NSString *)k title:(NSString *)switchTitle defaultValue:(BOOL)flag {
	FieldSpecifier *field = [FieldSpecifier fieldWithType:FieldSpecifierTypeSwitch key:k];
	field.title = switchTitle;
	field.defaultValue = @(flag);
	return field;
}

+ (FieldSpecifier *)emailFieldWithKey:(NSString *)k title:(NSString *)emailTitle defaultValue:(NSString *)defaultEmail {
	FieldSpecifier *field = [FieldSpecifier fieldWithType:FieldSpecifierTypeEmail key:k];
	field.title = emailTitle;
	field.defaultValue = defaultEmail;
	return field;
}

+ (FieldSpecifier *)URLFieldWithKey:(NSString *)k title:(NSString *)URLTitle defaultValue:(NSString *)defaultURL {
	FieldSpecifier *field = [FieldSpecifier fieldWithType:FieldSpecifierTypeURL key:k];
	field.title = URLTitle;
	field.defaultValue = defaultURL;
	return field;
}

+ (FieldSpecifier *)passwordFieldWithKey:(NSString *)k title:(NSString *)passwordTitle defaultValue:(NSString *)defaultPassword {
	FieldSpecifier *field = [FieldSpecifier fieldWithType:FieldSpecifierTypePassword key:k];
	field.title = passwordTitle;
	field.defaultValue = defaultPassword;
	return field;
}

+ (FieldSpecifier *)textFieldWithKey:(NSString *)k title:(NSString *)textTitle defaultValue:(NSString *)defaultText {
	FieldSpecifier *field = [FieldSpecifier fieldWithType:FieldSpecifierTypeText key:k];
	field.title = textTitle;
	field.defaultValue = defaultText;
	return field;
}

+ (FieldSpecifier *)numericFieldWithKey:(NSString *)k title:(NSString *)numericTitle defaultValue:(NSString *)defaultText {
	FieldSpecifier *field = [FieldSpecifier fieldWithType:FieldSpecifierTypeNumeric key:k];
	field.title = numericTitle;
	field.defaultValue = defaultText;
	return field;
}

+ (FieldSpecifier *)checkFieldWithKey:(NSString *)k title:(NSString *)checkmarkTitle defaultValue:(BOOL)checked {
	FieldSpecifier *field = [FieldSpecifier fieldWithType:FieldSpecifierTypeCheck key:k];
	field.title = checkmarkTitle;
	field.defaultValue = @(checked);
	return field;
}

+ (FieldSpecifier *)buttonFieldWithKey:(NSString *)k title:(NSString *)buttonTitle {
	FieldSpecifier *field = [FieldSpecifier fieldWithType:FieldSpecifierTypeButton key:k];
	field.title = buttonTitle;
	return field;
}

+ (FieldSpecifier *)subsectionFieldWithSections:(NSArray *)sections key:(NSString *)k title:(NSString *)subTitle {
	FieldSpecifier *field = [FieldSpecifier fieldWithType:FieldSpecifierTypeSection key:k];
	field.title = subTitle;
	field.defaultValue = nil;
	field.subsections = sections;
	return field;
}

+ (FieldSpecifier *)subsectionFieldWithSection:(FieldSectionSpecifier *)section key:(NSString *)k {
	return [self subsectionFieldWithSections:@[section] key:k title:section.title];
}

@end
