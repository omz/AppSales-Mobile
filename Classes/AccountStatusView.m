//
//  AccountStatusView.m
//  AppSales
//
//  Created by Ole Zorn on 03.08.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "AccountStatusView.h"
#import "ASAccount.h"

@implementation AccountStatusView

- (id)initWithFrame:(CGRect)frame account:(ASAccount *)anAccount
{
	self = [super initWithFrame:frame];
	if (self) {
		account = [anAccount retain];
		self.backgroundColor = [UIColor clearColor];
		activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(20, 5, 16, 16)];
		activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
		activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
		[self addSubview:activityIndicator];
		
		statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(36, 5, frame.size.width - 2 * 36, 16)];
		statusLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		statusLabel.backgroundColor = [UIColor clearColor];
		statusLabel.font = [UIFont systemFontOfSize:14.0];
		statusLabel.textColor = [UIColor colorWithRed:0.322 green:0.357 blue:0.443 alpha:1.0];
		statusLabel.textAlignment = NSTextAlignmentCenter;
		[self addSubview:statusLabel];
		
		[self updateStatus];
		
		[account addObserver:self forKeyPath:@"isDownloadingReports" options:NSKeyValueObservingOptionNew context:nil];
		[account addObserver:self forKeyPath:@"downloadStatus" options:NSKeyValueObservingOptionNew context:nil];
	}
	return self;
}

- (void)updateStatus
{
	if (account.isDownloadingReports) {
		[activityIndicator startAnimating];
		statusLabel.text = account.downloadStatus;
	} else {
		[activityIndicator stopAnimating];
		statusLabel.text = @"";
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	[self updateStatus];
}

- (void)dealloc
{
	[account removeObserver:self forKeyPath:@"isDownloadingReports"];
	[account removeObserver:self forKeyPath:@"downloadStatus"];
	[activityIndicator release];
	[statusLabel release];
	[account release];
	[super dealloc];
}

@end
