//
//  CalculatorView.m
//  AppSales
//
//  Created by Ole Zorn on 09.04.10.
//  Copyright 2010 omz:software. All rights reserved.
//

#import "CalculatorView.h"

@implementation CalculatorView


- (id)initWithFrame:(CGRect)rect
{
	CGSize calculatorSize = CGSizeMake(280,357);
	if ((self = [super initWithFrame:CGRectMake(rect.origin.x, rect.origin.y, calculatorSize.width, calculatorSize.height)])) {
		UIImageView *backgroundImageView = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, calculatorSize.width, calculatorSize.height)] autorelease];
		backgroundImageView.image = [UIImage imageNamed:@"CalculatorBackground.png"];
		[self addSubview:backgroundImageView];
		
		NSMutableArray *buttons = [NSMutableArray array];
		
		AudioServicesCreateSystemSoundID((CFURLRef)[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"CalculatorClick" ofType:@"caf"]], &clickSoundID);
		
		do {
		//C, <-, /, x
		UIButton *clearButton = [UIButton buttonWithType:UIButtonTypeCustom];
		clearButton.frame = CGRectMake(18, 95, 54, 40);
		[clearButton setTitle:@"C" forState:UIControlStateNormal];
		[buttons addObject:clearButton];
		
		UIButton *signButton = [UIButton buttonWithType:UIButtonTypeCustom];
		signButton.frame = CGRectMake(81, 95, 54, 40);
		[signButton setTitle:@"±" forState:UIControlStateNormal];
		[buttons addObject:signButton];
		
		UIButton *divideButton = [UIButton buttonWithType:UIButtonTypeCustom];
		divideButton.frame = CGRectMake(144, 95, 54, 40);
		[divideButton setTitle:@"÷" forState:UIControlStateNormal];
		[buttons addObject:divideButton];
		
		UIButton *multiplyButton = [UIButton buttonWithType:UIButtonTypeCustom];
		multiplyButton.frame = CGRectMake(207, 95, 54, 40);
		[multiplyButton setTitle:@"×" forState:UIControlStateNormal];
		[buttons addObject:multiplyButton];
		
		//7, 8, 9, -
		UIButton *sevenButton = [UIButton buttonWithType:UIButtonTypeCustom];
		sevenButton.frame = CGRectMake(18, 145, 54, 40);
		[sevenButton setTitle:@"7" forState:UIControlStateNormal];
		[buttons addObject:sevenButton];
		
		UIButton *eightButton = [UIButton buttonWithType:UIButtonTypeCustom];
		eightButton.frame = CGRectMake(81, 145, 54, 40);
		[eightButton setTitle:@"8" forState:UIControlStateNormal];
		[buttons addObject:eightButton];
		
		UIButton *nineButton = [UIButton buttonWithType:UIButtonTypeCustom];
		nineButton.frame = CGRectMake(144, 145, 54, 40);
		[nineButton setTitle:@"9" forState:UIControlStateNormal];
		[buttons addObject:nineButton];
		
		UIButton *minusButton = [UIButton buttonWithType:UIButtonTypeCustom];
		minusButton.frame = CGRectMake(207, 145, 54, 40);
		[minusButton setTitle:@"–" forState:UIControlStateNormal];
		[buttons addObject:minusButton];
		
		//4, 5, 6, +:
		UIButton *fourButton = [UIButton buttonWithType:UIButtonTypeCustom];
		fourButton.frame = CGRectMake(18, 195, 54, 40);
		[fourButton setTitle:@"4" forState:UIControlStateNormal];
		[buttons addObject:fourButton];
		
		UIButton *fiveButton = [UIButton buttonWithType:UIButtonTypeCustom];
		fiveButton.frame = CGRectMake(81, 195, 54, 40);
		[fiveButton setTitle:@"5" forState:UIControlStateNormal];
		[buttons addObject:fiveButton];
		
		UIButton *sixButton = [UIButton buttonWithType:UIButtonTypeCustom];
		sixButton.frame = CGRectMake(144, 195, 54, 40);
		[sixButton setTitle:@"6" forState:UIControlStateNormal];
		[buttons addObject:sixButton];
		
		UIButton *plusButton = [UIButton buttonWithType:UIButtonTypeCustom];
		plusButton.frame = CGRectMake(207, 195, 54, 40);
		[plusButton setTitle:@"+" forState:UIControlStateNormal];
		[buttons addObject:plusButton];
		
		//1, 2, 3:
		UIButton *oneButton = [UIButton buttonWithType:UIButtonTypeCustom];
		oneButton.frame = CGRectMake(18, 245, 54, 40);
		[oneButton setTitle:@"1" forState:UIControlStateNormal];
		[buttons addObject:oneButton];
		
		UIButton *twoButton = [UIButton buttonWithType:UIButtonTypeCustom];
		twoButton.frame = CGRectMake(81, 245, 54, 40);
		[twoButton setTitle:@"2" forState:UIControlStateNormal];
		[buttons addObject:twoButton];
		
		UIButton *threeButton = [UIButton buttonWithType:UIButtonTypeCustom];
		threeButton.frame = CGRectMake(144, 245, 54, 40);
		[threeButton setTitle:@"3" forState:UIControlStateNormal];
		[buttons addObject:threeButton];
		
		UIButton *equalsButton = [UIButton buttonWithType:UIButtonTypeCustom];
		equalsButton.frame = CGRectMake(207, 245, 54, 92);
		[equalsButton setTitle:@"=" forState:UIControlStateNormal];
		[buttons addObject:equalsButton];
		
		//0, .:
		UIButton *zeroButton = [UIButton buttonWithType:UIButtonTypeCustom];
		zeroButton.frame = CGRectMake(18, 297, 117, 40);
		[zeroButton setTitle:@"0" forState:UIControlStateNormal];
		[buttons addObject:zeroButton];
		
		UIButton *dotButton = [UIButton buttonWithType:UIButtonTypeCustom];
		dotButton.frame = CGRectMake(144, 297, 54, 40);
		[dotButton setTitle:@"." forState:UIControlStateNormal];
		[buttons addObject:dotButton];
		} while (NO);
		
		UIImage *buttonImageNormal = [[UIImage imageNamed:@"CalculatorButtonNormal.png"] stretchableImageWithLeftCapWidth:10 topCapHeight:10];
		UIImage *buttonImageHighlighted = [[UIImage imageNamed:@"CalculatorButtonHighlighted.png"] stretchableImageWithLeftCapWidth:10 topCapHeight:10];
		UIImage *buttonImageNormal2 = [[UIImage imageNamed:@"CalculatorButton2Normal.png"] stretchableImageWithLeftCapWidth:10 topCapHeight:10];
		UIImage *buttonImageHighlighted2 = [[UIImage imageNamed:@"CalculatorButton2Highlighted.png"] stretchableImageWithLeftCapWidth:10 topCapHeight:10];
		UIImage *buttonImageNormal3 = [[UIImage imageNamed:@"CalculatorButton3Normal.png"] stretchableImageWithLeftCapWidth:10 topCapHeight:10];
		UIImage *buttonImageHighlighted3 = [[UIImage imageNamed:@"CalculatorButton3Highlighted.png"] stretchableImageWithLeftCapWidth:10 topCapHeight:10];
		UIImage *buttonImageNormal4 = [[UIImage imageNamed:@"CalculatorButton4Normal.png"] stretchableImageWithLeftCapWidth:10 topCapHeight:10];
		UIImage *buttonImageHighlighted4 = [[UIImage imageNamed:@"CalculatorButton4Highlighted.png"] stretchableImageWithLeftCapWidth:10 topCapHeight:10];
		
		for (UIButton *button in buttons) {
			button.titleLabel.font = [UIFont fontWithName:@"Verdana" size:20.0];
			[button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
			NSString *title = button.titleLabel.text;
			if ([title isEqual:@"="]) {
				[button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];;
				[button setBackgroundImage:buttonImageNormal4 forState:UIControlStateNormal];
				[button setBackgroundImage:buttonImageHighlighted4 forState:UIControlStateHighlighted];	
			}
			else if ([title isEqual:@"C"]) {
				[button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];;
				[button setBackgroundImage:buttonImageNormal3 forState:UIControlStateNormal];
				[button setBackgroundImage:buttonImageHighlighted3 forState:UIControlStateHighlighted];	
			} else if ([title isEqual:@"0"] || [title isEqual:@"."] || [title intValue] != 0) {
				[button setBackgroundImage:buttonImageNormal forState:UIControlStateNormal];
				[button setBackgroundImage:buttonImageHighlighted forState:UIControlStateHighlighted];	
			} else {
				[button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
				[button setBackgroundImage:buttonImageNormal2 forState:UIControlStateNormal];
				[button setBackgroundImage:buttonImageHighlighted2 forState:UIControlStateHighlighted];	
			}
			[button addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
			[button addTarget:self action:@selector(buttonDown:) forControlEvents:UIControlEventTouchDown];
			[self addSubview:button];
		}
		
		displayLabel = [[[UILabel alloc] initWithFrame:CGRectMake(17, 20, 244, 44)] autorelease];
		displayLabel.text = @"0";
		
		displayLabel.textAlignment = UITextAlignmentRight;
		displayLabel.font = [UIFont fontWithName:@"Verdana" size:40];
		displayLabel.backgroundColor = [UIColor clearColor];
		displayLabel.adjustsFontSizeToFitWidth = YES;
		displayLabel.lineBreakMode = UILineBreakModeHeadTruncation;
		displayLabel.minimumFontSize = 17.0;
		[self addSubview:displayLabel];
		
		UIButton *displayButton = [UIButton buttonWithType:UIButtonTypeCustom];
		displayButton.frame = CGRectMake(13, 12, 253, 64);
		[displayButton addTarget:self action:@selector(displayTapped:) forControlEvents:UIControlEventTouchUpInside];
		[self addSubview:displayButton];
		
		stack = [NSMutableArray new];
		[stack addObject:displayLabel.text];
    }
    return self;
}


#pragma mark -
#pragma mark UI Actions
- (void)copy:(id)sender
{	
	[[UIPasteboard generalPasteboard] setString:displayLabel.text];
}

- (BOOL)canBecomeFirstResponder 
{
    return YES;
}

- (void)displayTapped:(id)sender
{
	[self.superview bringSubviewToFront:self];
	[self becomeFirstResponder];
	
	[[UIMenuController sharedMenuController] setTargetRect:[sender frame] inView:self];
	[[UIMenuController sharedMenuController] setMenuVisible:YES animated:YES];
}

- (void)buttonDown:(id)sender
{
	AudioServicesPlaySystemSound(clickSoundID);
	[self.superview bringSubviewToFront:self];
}

- (void)buttonPressed:(id)sender
{
	UIButton *button = (UIButton *)sender;
	NSString *title = button.titleLabel.text;
	[self enterCalculatorButton:title];
}

- (void)setDisplay:(NSString *)newDisplay
{
	displayLabel.text = newDisplay;
}

#pragma mark -
#pragma mark Calculator Engine

- (void)enterCalculatorButton:(NSString *)title
{
	NSString *currentDisplay = [[[stack lastObject] retain] autorelease];
	NSString *newDisplay = nil;
	TokenType lastTokenType = [self tokenTypeFor:[stack lastObject]];
	ButtonType buttonType = [self buttonTypeFor:title];
	
	if (buttonType == ButtonTypeClear) {
		[stack removeAllObjects];
		[stack addObject:@"0"];
		[self setDisplay:@"0"];
	}
	if ([currentDisplay isEqual:NSLocalizedString(@"Error",nil)]) {
		return;
	}
	if (buttonType == ButtonTypeDigit) {
		if (lastTokenType == TokenTypeOperand) {
			if (displaysResult || [currentDisplay isEqual:@"0"]) {
				newDisplay = title;
			} else {
				newDisplay = [currentDisplay stringByAppendingString:title];
			}
			[stack removeLastObject];
			[stack addObject:newDisplay];
			[self setDisplay:newDisplay];
		} else { //Operator
			[stack addObject:title];
			[self setDisplay:title];
		}
		displaysResult = NO;
	}
	if (buttonType == ButtonTypeSign) {
		if (lastTokenType == TokenTypeOperand) {
			if ([currentDisplay doubleValue] != 0) {
				if ([[currentDisplay substringToIndex:1] isEqual:@"-"]) {
					newDisplay = [currentDisplay substringFromIndex:1];
				} else {
					newDisplay = [NSString stringWithFormat:@"-%@", currentDisplay];
				}
				[stack removeLastObject];
				[stack addObject:newDisplay];
				[self setDisplay:newDisplay];
			}
		}
	}
	if (buttonType == ButtonTypeSeparator) {
		if (lastTokenType == TokenTypeOperator) {
			[stack addObject:@"0."];
			[self setDisplay:@"0."];
		} else {
			if ([currentDisplay rangeOfString:@"."].location == NSNotFound) {
				newDisplay = [currentDisplay stringByAppendingString:@"."];
				[stack removeLastObject];
				[stack addObject:newDisplay];
				[self setDisplay:newDisplay];
			}
		}
		displaysResult = NO;
	}
	if (buttonType == ButtonTypeOperator) {
		if (lastTokenType == TokenTypeOperand) {
			int currentOpPrecedence = [self precedenceForOperator:title];
			if ([self numberOfOperatorsOnStack] > 1 || [self firstOperatorPrecedence] >= currentOpPrecedence) {
				[self evaluateStack];
				[self setDisplay:[stack lastObject]];
			}
			[stack addObject:title];
		} else {
			//Another operator is already on the stack, replace it
			[stack removeLastObject];
			[stack addObject:title];
		}
		displaysResult = NO;
	}
	if (buttonType == ButtonTypeEquals) {
		[self evaluateStack];
		[self setDisplay:[stack lastObject]];
		displaysResult = YES;
	}
	
}

- (void)evaluateStack
{
	if ([self tokenTypeFor:[stack lastObject]] == TokenTypeOperator) {
		[stack removeLastObject];
	}
	if ([stack count] == 3) {
		NSString *operand1 = [stack objectAtIndex:0];
		NSString *operator = [stack objectAtIndex:1];
		NSString *operand2 = [stack objectAtIndex:2];
		double n1 = [operand1 doubleValue];
		double n2 = [operand2 doubleValue];
		double result = 0.0;
		BOOL error = NO;
		if ([operator isEqual:@"+"]) {
			result = n1 + n2;
		} else if ([operator isEqual:@"÷"]) {
			if (n2 == 0) {
				error = YES;
			} else {
				result = n1 / n2;
			}
		} else if ([operator isEqual:@"×"]) {
			result = n1 * n2;
		} else {
			result = n1 - n2;
		}
		if (!error) {
			NSNumberFormatter *numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
			[numberFormatter setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"en-us"] autorelease]];
			[numberFormatter setMinimumFractionDigits:0];
			[numberFormatter setMaximumFractionDigits:10];
			[numberFormatter setMinimumIntegerDigits:1];
			NSString *resultString = [numberFormatter stringFromNumber:[NSNumber numberWithDouble:result]];
			[stack removeAllObjects];
			[stack addObject:resultString];
		} else {
			[stack removeAllObjects];
			[stack addObject:NSLocalizedString(@"Error",nil)];
		}
	}
	if ([stack count] == 5) {
		double n1 = [[stack objectAtIndex:0] doubleValue];
		double n2 = [[stack objectAtIndex:2] doubleValue];
		double n3 = [[stack objectAtIndex:4] doubleValue];
		NSString *operator1 = [stack objectAtIndex:1];
		NSString *operator2 = [stack objectAtIndex:3];
		double partialResult = 0.0;
		BOOL error = NO;
		if ([operator2 isEqual:@"×"]) {
			partialResult = n2 * n3;
		} else {
			if (n3 == 0) {
				error = YES;
			} else {
				partialResult = n2 / n3;
			}
		}
		double result;
		if ([operator1 isEqual:@"+"]) {
			result = n1 + partialResult;
		} else {
			result = n1 - partialResult;
		}
		if (!error) {
			NSNumberFormatter *numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
			[numberFormatter setMinimumFractionDigits:0];
			[numberFormatter setMaximumFractionDigits:10];
			[numberFormatter setMinimumIntegerDigits:1];
			NSString *resultString = [numberFormatter stringFromNumber:[NSNumber numberWithDouble:result]];
			[stack removeAllObjects];
			[stack addObject:resultString];
		} else {
			[stack removeAllObjects];
			[stack addObject:NSLocalizedString(@"Error",nil)];
		}
	}
}

- (int)firstOperatorPrecedence
{
	for (NSString *token in stack) {
		if ([self tokenTypeFor:token] == TokenTypeOperator) {
			if ([token isEqual:@"+"] || [token isEqual:@"–"]) {
				return 1;
			} else {
				return 2;
			}
		}
	}
	return 0;
}

- (int)precedenceForOperator:(NSString *)op
{
	if ([op isEqual:@"+"] || [op isEqual:@"–"]) {
		return 1;
	}
	return 2;
}

- (int)numberOfOperatorsOnStack
{
	int c = 0;
	for (NSString *token in stack) {
		if ([self tokenTypeFor:token] == TokenTypeOperator) {
			c++;
		}
	}
	return c;
}

- (TokenType)tokenTypeFor:(NSString *)tokenString
{
	if ([tokenString isEqual:@"+"] || [tokenString isEqual:@"–"] || [tokenString isEqual:@"÷"] || [tokenString isEqual:@"×"]) {
		return TokenTypeOperator;
	}
	return TokenTypeOperand;
}

- (ButtonType)buttonTypeFor:(NSString *)buttonTitle
{
	int i = [buttonTitle intValue];
	if (i != 0 || [buttonTitle isEqual:@"0"]) {
		return ButtonTypeDigit;
	}
	if ([buttonTitle isEqual:@"."]) {
		return ButtonTypeSeparator;
	}
	if ([buttonTitle isEqual:@"±"]) {
		return ButtonTypeSign;
	}
	if ([buttonTitle isEqual:@"+"] || [buttonTitle isEqual:@"–"] || [buttonTitle isEqual:@"÷"] || [buttonTitle isEqual:@"×"]) {
		return ButtonTypeOperator;
	}
	if ([buttonTitle isEqual:@"="]) {
		return ButtonTypeEquals;
	}
	if ([buttonTitle isEqual:@"C"]) {
		return ButtonTypeClear;
	}
	return ButtonTypeUnknown;
}

- (void)dealloc 
{
	[stack release];
	[super dealloc];
}


@end
