//
//  RootViewController.m
//  PTPasscodeViewControllerDemo
//
//  Created by Lasha Dolidze on 7/7/10.
//  Copyright Picktek LLC 2010. All rights reserved.
//  Distributed under GPL license v 2.x or later	 	
//  http://www.gnu.org/licenses/gpl-2.0.html
//

#import "PTPasscodeViewController.h"

///////////////////////////////////////////////////////////////////////////////////
// Private Methods
@interface PTPasscodeViewController (Private)
- (UITextField*) createPasscodeEntry:(CGRect)textFieldFrame tag:(NSInteger)tag;
- (UIView*) createPanel:(CGRect)rect tagIndex:(NSInteger)tagIndex;
- (void) switchPanel:(NSInteger)panelTag;
@end

@implementation PTPasscodeViewController

@synthesize currentPanel;
@synthesize delegate = _delegate;

#pragma mark -
#pragma mark View lifecycle

-(id)initWithDelegate:(id)delegate {
    //CGRect rect = [[UIScreen mainScreen] bounds];
    if ((self = [super init])) {
        _delegate = delegate;            
    }
    return self;
}


- (UITextField*) createPasscodeEntry:(CGRect)textFieldFrame tag:(NSInteger)tag
{
    //CGRect textFieldFrame = CGRectMake(40.0, 60.0, 60.0, 60.0);
    UITextField *textField = [[UITextField alloc] initWithFrame:textFieldFrame];
    [textField setBorderStyle:UITextBorderStyleBezel];
    [textField setTextColor:[UIColor blackColor]];
    [textField setTextAlignment:UITextAlignmentCenter];
    [textField setFont:[UIFont systemFontOfSize:41]];
    [textField setTag:tag];
    [textField setSecureTextEntry:YES];
    [textField setBackgroundColor:[UIColor whiteColor]];
    textField.keyboardType = UIKeyboardTypeNumberPad;

    return textField;
}

- (UIView*) createPanel:(CGRect)rect tagIndex:(NSInteger)tagIndex
{
    UIView *panelView = [[UILabel alloc] initWithFrame:rect];
    [panelView setTag:tagIndex];
    [panelView setBounds:rect];
    [panelView setBackgroundColor:[UIColor clearColor]];
    
    UITextField *textField = [self createPasscodeEntry:CGRectMake(rect.origin.x + 25.0, 60.0, kPasscodeEntryWidth, kPasscodeEntryHeight) tag:tagIndex + 1];
    [panelView addSubview:textField];
    [textField  release];
    
    textField = [self createPasscodeEntry:CGRectMake(rect.origin.x + 95.0, 60.0, kPasscodeEntryWidth, kPasscodeEntryHeight) tag:tagIndex + 2];
    [panelView addSubview:textField];
    [textField  release];
    
    textField = [self createPasscodeEntry:CGRectMake(rect.origin.x + 165.0, 60.0, kPasscodeEntryWidth, kPasscodeEntryHeight) tag:tagIndex + 3];
    [panelView addSubview:textField];
    [textField  release];
    
    textField = [self createPasscodeEntry:CGRectMake(rect.origin.x + 235.0, 60.0, kPasscodeEntryWidth, kPasscodeEntryHeight) tag:tagIndex + 4];
    [panelView addSubview:textField];
    [textField  release];    
    
    
    // Create title
    CGRect labelFrame = CGRectMake(rect.origin.x + 25.0, 22.0, kPasscodeEntryWidth * 4 + 30, 30.0);
    UILabel *label = [[UILabel alloc] initWithFrame:labelFrame];
    [label setTag:kPasscodePanelTitleTag];
    [label setFont:[UIFont boldSystemFontOfSize:15]];
    [label setTextAlignment:UITextAlignmentCenter];    
    [label setTextColor:[UIColor colorWithRed:66.0/255.0 green:85.0/255.0 blue:102.0/255.0 alpha:1.0]];
    [label setBackgroundColor:[UIColor clearColor]];
    [panelView addSubview:label];
    [label release];

    // Create summary
    labelFrame = CGRectMake(rect.origin.x + 25.0, 130.0, kPasscodeEntryWidth * 4 + 30, 40.0);
    label = [[UILabel alloc] initWithFrame:labelFrame];
    [label setTag:kPasscodePanelSummaryTag];
    [label setFont:[UIFont boldSystemFontOfSize:12]];
    [label setNumberOfLines:0];
    [label setBaselineAdjustment:UIBaselineAdjustmentNone];
    [label setTextAlignment:UITextAlignmentCenter];    
    [label setTextColor:[UIColor colorWithRed:66.0/255.0 green:85.0/255.0 blue:102.0/255.0 alpha:1.0]];
    [label setBackgroundColor:[UIColor clearColor]];
    [panelView addSubview:label];
    [label release];
    
    return panelView;
}
                      

- (void) switchPanel:(NSInteger)panelTag
{
    CGRect rect = _scrollView.frame;
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.2];
    [_scrollView setFrame:CGRectMake(panelTag, rect.origin.y, rect.size.width, rect.size.height)];
    [UIView commitAnimations];
    
    currentPanel = (UIView*)[_scrollView viewWithTag:panelTag];

    if ([self.delegate respondsToSelector:@selector(didShowPasscodePanel:panelView:)]) {
        [self.delegate didShowPasscodePanel:self panelView:currentPanel];
    }
    
    [self clearPanel];
}


- (void)viewDidLoad {
    
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    CGRect frm = CGRectMake(0.0, 0.0, kPasscodePanelWidth * kPasscodePanelCount, kPasscodePanelHeight);
    _scrollView = [[UILabel alloc] initWithFrame:frm];

    [_scrollView setBackgroundColor:[UIColor clearColor]];
    [self.view addSubview:_scrollView];
    
    // Create Panel One
    UIView *panelView = [self createPanel:CGRectMake(0.0, 0.0, kPasscodePanelWidth, kPasscodePanelHeight) tagIndex:kPasscodePanelOne];
    [_scrollView addSubview:panelView];
    [self switchPanel:kPasscodePanelOne];
    [panelView release];
    // -------------------------------------------
    
    // Create Panel Two
    panelView = [self createPanel:CGRectMake(kPasscodePanelWidth, 0.0, kPasscodePanelWidth, kPasscodePanelHeight) tagIndex:kPasscodePanelTwo];
    [_scrollView addSubview:panelView];
    [panelView release];
    // -------------------------------------------

    // Create Panel Three
    panelView = [self createPanel:CGRectMake(kPasscodePanelWidth * 2, 0.0, kPasscodePanelWidth, kPasscodePanelHeight) tagIndex:kPasscodePanelThree];
    [_scrollView addSubview:panelView];
    [panelView release];
    // -------------------------------------------
 
    // Create frake input text
    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectZero];
    [textField setDelegate:self];
    [textField setTag:kPasscodeFakeTextField];
    [textField setHidden:YES];
    textField.keyboardType = UIKeyboardTypeNumberPad;
    [self.view addSubview:textField];
    [textField release];
    [textField becomeFirstResponder];
    // -------------------------------------------
    
    
}


#pragma mark Public methods

- (void) clearPanel
{
    NSInteger panelTag = [currentPanel tag];
    
    UITextField *entryText =  (UITextField*)[currentPanel viewWithTag:panelTag + 1];
    [entryText setText:@""];
    
    entryText =  (UITextField*)[currentPanel viewWithTag:panelTag + 2];
    [entryText setText:@""];
    
    entryText =  (UITextField*)[currentPanel viewWithTag:panelTag + 3];
    [entryText setText:@""];
    
    entryText =  (UITextField*)[currentPanel viewWithTag:panelTag + 4];
    [entryText setText:@""];
    
    // Clear fake text field
    UITextField *textField = (UITextField*)[self.view viewWithTag:kPasscodeFakeTextField];
    [textField setText:@""];
}

-(UILabel*)titleLabel {
    return (UILabel*)[currentPanel viewWithTag:kPasscodePanelTitleTag];
}

-(UILabel*)summaryLabel {
    return (UILabel*)[currentPanel viewWithTag:kPasscodePanelSummaryTag];
}

-(BOOL)prevPanel
{
    NSInteger tag = [currentPanel tag];
    if(tag != 0) {
        [self switchPanel:tag + kPasscodePanelWidth];
        return TRUE;
    }
    return FALSE;
}

-(BOOL)nextPanel
{
    NSInteger tag = [currentPanel tag];
    if(tag != -640) {
        [self switchPanel:tag - kPasscodePanelWidth];
        return TRUE;
    }
    return FALSE;   
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    BOOL ret = FALSE;
    
    NSString *passcode = [textField text];
    passcode = [passcode stringByReplacingCharactersInRange:range withString:string];
  
  //  NSLog(@"passcode - %@", passcode);
    
    NSInteger index = [passcode length];
    if([string length] == 0) {
        index++;
    }
    
    if(index <= 4) {
        NSInteger tag = [currentPanel tag];
        UITextField *tf = (UITextField*)[currentPanel viewWithTag:tag + index];
       // NSLog(@"%@ - %@ - %@, %d, %d", string, [textField text], passcode, tag, index);
         
        if ([self.delegate respondsToSelector:@selector(shouldChangePasscode:panelView:passCode:lastNumber:)]) {
            if([self.delegate shouldChangePasscode:self panelView:currentPanel passCode:[passcode intValue] lastNumber:[string intValue]]) {
                [tf setText:string];
                ret = TRUE;
            }
        } else {
            [tf setText:string];
            ret = TRUE;        
        }
        
        // Did end passcode
        if(index == 4 && ret) {
            if ([self.delegate respondsToSelector:@selector(didEndPasscodeEditing:panelView:passCode:)]) {
                return [self.delegate didEndPasscodeEditing:self panelView:currentPanel passCode:[passcode intValue]];
                //ret = FALSE;
            }
        }
        
        return ret;
    } 
    
    return ret;
}

/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}
*/

/*
 // Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations.
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
 */



#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {
    [_scrollView release];

    [super dealloc];
}


@end

