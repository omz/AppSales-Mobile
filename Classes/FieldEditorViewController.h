//
//  FieldEditorViewController.h
//  AppSales
//
//  Created by Ole Zorn on 20.04.09.
//  Copyright 2009 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FieldSpecifier, FieldEditorViewController, FieldSectionSpecifier;

typedef NS_ENUM(NSInteger, FieldSpecifierType) {
	FieldSpecifierTypeText,
	FieldSpecifierTypePassword,
	FieldSpecifierTypeEmail,
	FieldSpecifierTypeURL,
	FieldSpecifierTypeSwitch,
	FieldSpecifierTypeCheck,
	FieldSpecifierTypeButton,
	FieldSpecifierTypeSection,
	FieldSpecifierTypeNumeric
};


@protocol FieldEditorViewControllerDelegate <NSObject>

@optional
- (void)fieldEditor:(FieldEditorViewController *)editor didFinishEditingWithValues:(NSDictionary *)returnValues;
- (void)fieldEditorDidCancel:(FieldEditorViewController *)editor;
- (void)fieldEditor:(FieldEditorViewController *)editor pressedButtonWithKey:(NSString *)key;

@end


@interface FieldEditorViewController : UITableViewController <UITextFieldDelegate, FieldEditorViewControllerDelegate> {

	id __weak delegate;
	id context;
	NSString *editorIdentifier;
	NSArray *fieldSections;
	NSMutableDictionary *values;
	NSString *doneButtonTitle;
	NSString *cancelButtonTitle;
	BOOL isSubSection;
	BOOL isOpeningSubsection;
	BOOL hasChanges;
	UITextField *selectedTextField;
}

@property (nonatomic, weak) id<FieldEditorViewControllerDelegate> delegate;
@property (nonatomic, strong) NSArray *fieldSections;
@property (nonatomic, strong) NSMutableDictionary *values;
@property (nonatomic, strong) NSString *doneButtonTitle;
@property (nonatomic, strong) NSString *cancelButtonTitle;
@property (nonatomic, strong) id context;
@property (nonatomic, strong) NSString *editorIdentifier;
@property (nonatomic, assign) BOOL isSubSection;
@property (nonatomic, assign) BOOL hasChanges;
@property (nonatomic, assign) BOOL showDoneButtonOnLeft;
@property (nonatomic, strong) UITextField *selectedTextField;

- (instancetype)initWithFieldSections:(NSArray *)sections title:(NSString *)title;
- (void)openSubsection:(FieldSpecifier *)subsectionField;
- (void)done;
- (void)dismissKeyboard;

@end


@interface FieldSectionSpecifier : NSObject {
	
	NSArray *fields;
	NSString *title;
	NSString *description;
	BOOL exclusiveSelection;
}

@property (nonatomic, strong) NSArray *fields;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *description;
@property (nonatomic, assign) BOOL exclusiveSelection;

+ (FieldSectionSpecifier *)sectionWithFields:(NSArray *)f title:(NSString *)t description:(NSString *)d;

@end


@interface FieldSpecifier : NSObject {
	
	FieldSpecifierType type;
	NSArray *subsections;
	NSString *key;
	NSString *title;
	NSString *placeholder;
	id defaultValue;
	BOOL shouldDisplayDisclosureIndicator;
}

@property (nonatomic, assign) FieldSpecifierType type;
@property (nonatomic, strong) NSArray *subsections;
@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *placeholder;
@property (nonatomic, strong) id defaultValue;
@property (nonatomic, assign) BOOL shouldDisplayDisclosureIndicator;

+ (FieldSpecifier *)fieldWithType:(FieldSpecifierType)t key:(NSString *)k;
+ (FieldSpecifier *)switchFieldWithKey:(NSString *)k title:(NSString *)switchTitle defaultValue:(BOOL)flag;
+ (FieldSpecifier *)emailFieldWithKey:(NSString *)k title:(NSString *)emailTitle defaultValue:(NSString *)defaultEmail;
+ (FieldSpecifier *)URLFieldWithKey:(NSString *)k title:(NSString *)URLTitle defaultValue:(NSString *)defaultURL;
+ (FieldSpecifier *)passwordFieldWithKey:(NSString *)k title:(NSString *)passwordTitle defaultValue:(NSString *)defaultPassword;
+ (FieldSpecifier *)textFieldWithKey:(NSString *)k title:(NSString *)textTitle defaultValue:(NSString *)defaultText;
+ (FieldSpecifier *)numericFieldWithKey:(NSString *)k title:(NSString *)numericTitle defaultValue:(NSString *)defaultText;
+ (FieldSpecifier *)checkFieldWithKey:(NSString *)k title:(NSString *)checkmarkTitle defaultValue:(BOOL)checked;
+ (FieldSpecifier *)buttonFieldWithKey:(NSString *)k title:(NSString *)buttonTitle;
+ (FieldSpecifier *)subsectionFieldWithSections:(NSArray *)sections key:(NSString *)k title:(NSString *)t;
+ (FieldSpecifier *)subsectionFieldWithSection:(FieldSectionSpecifier *)section key:(NSString *)k;

@end


@interface NamedTextField : UITextField {
	
	NSString *name;
}

@property (nonatomic, strong) NSString *name;

@end


@interface NamedSwitch: UISwitch {
	
	NSString *name;
}

@property (nonatomic, strong) NSString *name;

@end
