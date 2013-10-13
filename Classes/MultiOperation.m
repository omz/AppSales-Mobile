//
//  MultiOperation.m
//  AppSales
//
//  Created by Ole Zorn on 14.08.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "MultiOperation.h"

@interface MultiOperation ()
- (void)finish;
@end

@implementation MultiOperation

@synthesize queue;

- (id)initWithOperations:(NSArray *)partialOperations
{
	self = [super init];
	if (self) {
		queue = [[NSOperationQueue alloc] init];
		queue.maxConcurrentOperationCount = 1;
		operations = [partialOperations retain];
	}
    return self;
}

- (BOOL)isConcurrent
{
	return YES;
}

- (void)start
{
	if ([self isCancelled]) {
		return;
	}
	for (NSOperation *operation in operations) {
		[queue addOperation:operation];
	}
	[operations release];
	operations = nil;
	
	[queue addObserver:self forKeyPath:@"operationCount" options:NSKeyValueObservingOptionNew context:nil];
	
	[self willChangeValueForKey:@"isExecuting"];
	executing = YES;
	[self didChangeValueForKey:@"isExecuting"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([queue operationCount] == 0) {
		[queue removeObserver:self forKeyPath:@"operationCount"];
		[self finish];
	}
}

- (void)cancel
{
	[super cancel];
	[self start];
	[queue cancelAllOperations];
	[self finish];
}

- (void)finish
{
	[self willChangeValueForKey:@"isFinished"];
	[self willChangeValueForKey:@"isExecuting"];
	finished = YES;
	executing = NO;
	[self didChangeValueForKey:@"isFinished"];
	[self didChangeValueForKey:@"isExecuting"];
}

- (BOOL)isExecuting
{
	return executing;
}

- (BOOL)isFinished
{
	return finished;
}

- (void)dealloc
{
	[queue release];
	[operations release];
	[super dealloc];
}


@end
