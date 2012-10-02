//
//  MultiOperation.h
//  AppSales
//
//  Created by Ole Zorn on 14.08.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MultiOperation : NSOperation {

	BOOL executing;
	BOOL finished;
	
	NSArray *operations;
	NSOperationQueue *queue;
}

@property (readonly) NSOperationQueue *queue;

- (id)initWithOperations:(NSArray *)partialOperations;

@end
