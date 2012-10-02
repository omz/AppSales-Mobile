//
//  DownloadStepOperation.h
//  AppSales
//
//  Created by Ole Zorn on 14.08.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DownloadStepOperation;

typedef void(^DownloadStepStartBlock)(DownloadStepOperation *operation);

@interface DownloadStepOperation : NSOperation {

	DownloadStepOperation *inputOperation;
	DownloadStepStartBlock startBlock;
	BOOL paused;
	
	BOOL executing;
	BOOL finished;
	
	NSURLConnection *connection;
	NSMutableData *data;
}

@property (nonatomic, retain) DownloadStepOperation *inputOperation;
@property (nonatomic, retain) NSURLRequest *request;
@property (nonatomic, copy) DownloadStepStartBlock startBlock;
@property (nonatomic, retain) NSURLConnection *connection;
@property (nonatomic, retain) NSMutableData *data;
@property (nonatomic, assign) BOOL paused;

+ (id)operationWithInput:(DownloadStepOperation *)otherOperation;

@end
