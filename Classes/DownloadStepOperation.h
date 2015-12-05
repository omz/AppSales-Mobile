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

@property (nonatomic, strong) DownloadStepOperation *inputOperation;
@property (nonatomic, strong) NSURLRequest *request;
@property (nonatomic, copy) DownloadStepStartBlock startBlock;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, assign) BOOL paused;

+ (instancetype)operationWithInput:(DownloadStepOperation *)otherOperation;

@end
