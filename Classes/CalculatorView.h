//
//  CalculatorView.h
//  AppSales
//
//  Created by Ole Zorn on 09.04.10.
//  Copyright 2010 omz:software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import "MovableView.h"

typedef enum TokenType {
	TokenTypeOperator,
	TokenTypeOperand
} TokenType;

typedef enum ButtonType {
	ButtonTypeUnknown,
	ButtonTypeDigit,
	ButtonTypeSeparator,
	ButtonTypeSign,
	ButtonTypeOperator,
	ButtonTypeEquals,
	ButtonTypeClear
} ButtonType;

@class CalculatorMO;

@interface CalculatorView : MovableView {

	SystemSoundID clickSoundID;
	UILabel *displayLabel;
	
	NSMutableArray *stack;
	BOOL displaysResult;
}

- (void)buttonDown:(id)sender;
- (void)buttonPressed:(id)sender;
- (void)enterCalculatorButton:(NSString *)title;
- (void)setDisplay:(NSString *)newDisplay;
- (int)numberOfOperatorsOnStack;
- (int)firstOperatorPrecedence;
- (int)precedenceForOperator:(NSString *)op;
- (void)evaluateStack;
- (TokenType)tokenTypeFor:(NSString *)tokenString;
- (ButtonType)buttonTypeFor:(NSString *)buttonTitle;


@end
