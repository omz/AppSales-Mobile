//
//  DownloadStepOperation.m
//  AppSales
//
//  Created by Ole Zorn on 14.08.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "DownloadStepOperation.h"

@interface DownloadStepOperation ()
- (void)finish;
@end

@implementation DownloadStepOperation

@synthesize inputOperation, startBlock, request, connection, data, paused;

- (id)init
{
    self = [super init];
    if (self) {
		
    }
    return self;
}

- (void)setStartBlock:(DownloadStepStartBlock)block
{
	startBlock = Block_copy(block);
}

+ (id)operationWithInput:(DownloadStepOperation *)otherOperation
{
	DownloadStepOperation *operation = [[[self alloc] init] autorelease];
	operation.inputOperation = otherOperation;
	return operation;
}

- (BOOL)isConcurrent
{
	return YES;
}

- (void)start
{
	//NSOperationQueue ignores the return value of isConcurrent since Mac OS X 10.6 (iOS 4.0?), so 
	//we have to ensure that we run on the main thread ourselves...
	if (![NSThread isMainThread]) {
		[self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:YES];
		return;
	}
	
	[self willChangeValueForKey:@"isExecuting"];
	executing = YES;
	[self didChangeValueForKey:@"isExecuting"];
	
	if ([self isCancelled]) {
		return;
	}
	if ([self.inputOperation isCancelled]) {
		//input operation was cancelled, also cancel all subsequent operations...
		[self cancel];
		return;
	}
	
	if (self.startBlock) {
		self.startBlock(self);
		self.startBlock = nil; //ensures that the startBlock is only executed once (e.g. when pausing and resuming the operation)
		self.inputOperation = nil; //the input operation is only needed by the startBlock, which has been executed by now
	}
	
	if (self.paused) {
		//The startBlock may set this property to delay loading the request, e.g. to wait for user confirmation
		return;
	}
	
	if (self.request) {
		self.data = [NSMutableData data];
		self.connection = [NSURLConnection connectionWithRequest:self.request delegate:self];
		[self.connection start];
	} else {
		//If there is no request, finish immediately
		[self finish];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)chunk
{
	[self.data appendData:chunk];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	[self finish];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[self cancel];
}

- (void)cancel
{
	[super cancel];
	[self.connection cancel];
	//iOS 5 will complain if we mark an operation as finished without starting it...
	[self start];
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
	Block_release(startBlock);
	[connection release];
	[data release];
	[inputOperation release];
	[super dealloc];
}

@end
