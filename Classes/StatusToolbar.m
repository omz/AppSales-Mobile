//
//  StatusToolbar.m
//  AppSales
//
//  Created by Nicolas Gomollon on 6/21/17.
//
//

#import "StatusToolbar.h"
#import "ReportDownloadCoordinator.h"

@implementation StatusToolbar

- (instancetype)init {
	return [self initWithFrame:CGRectZero];
}

- (instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:CGRectMake(0.0f, CGFLOAT_MAX, 320.0f, 44.0f)];
	if (self) {
		// Initialization code
		self.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
		self.translucent = YES;
		self.barStyle = UIBarStyleBlackTranslucent;
		self.hidden = YES;
		visible = NO;
		
		activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
		UIBarButtonItem *activityIndicatorItem = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
		
		statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 2.0f, 200.0f, 20.0f)];
		statusLabel.font = [UIFont boldSystemFontOfSize:14.0f];
		statusLabel.backgroundColor = [UIColor clearColor];
		statusLabel.textColor = [UIColor whiteColor];
		statusLabel.textAlignment = NSTextAlignmentCenter;
		statusLabel.text = NSLocalizedString(@"Loading...", nil);
		
		progressBar = [[UIProgressView alloc] initWithFrame:CGRectMake(0.0f, 25.0f, 200.0f, 10.0f)];
		progressBar.progress = 0.0f;
		
		UIView *statusView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 200.0f, 40.0f)];
		[statusView addSubview:statusLabel];
		[statusView addSubview:progressBar];
		
		UIBarButtonItem *statusItem = [[UIBarButtonItem alloc] initWithCustomView:statusView];
		
		UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
		
		stopButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(stopDownload:)];
		
		self.items = @[activityIndicatorItem, flexSpace, statusItem, flexSpace, stopButtonItem];
	}
	return self;
}

- (void)show {
	if (visible || (self.superview == nil)) { return; }
	visible = YES;
	[activityIndicator startAnimating];
	
	CGFloat statusHeight = 44.0f;
	CGFloat statusOffsetY = statusHeight;
	if (@available(iOS 11.0, *)) {
		statusOffsetY += self.superview.safeAreaInsets.bottom;
	}
	
	self.frame = CGRectMake(0.0f, self.superview.bounds.size.height, self.superview.bounds.size.width, statusHeight);
	
	[UIView animateWithDuration:0.4 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
		self.hidden = NO;
        self->stopButtonItem.enabled = YES;
		self.frame = CGRectMake(0.0f, self.superview.bounds.size.height - statusOffsetY, self.superview.bounds.size.width, statusHeight);
	} completion:nil];
}

- (void)hide {
	if (!visible || (self.superview == nil)) { return; }
	visible = NO;
	[activityIndicator stopAnimating];
	
	[UIView animateWithDuration:0.4 delay:1.5 options:UIViewAnimationOptionCurveEaseInOut animations:^{
		self.frame = CGRectMake(0.0f, self.superview.bounds.size.height, self.superview.bounds.size.width, 44.0f);
	} completion:^(BOOL finished) {
		self.hidden = YES;
		self.status = NSLocalizedString(@"Loading...", nil);
		self.progress = 0.0f;
	}];
}

- (BOOL)isVisible {
	return visible;
}

- (NSString *)status {
	return statusLabel.text;
}

- (void)setStatus:(NSString *)status {
	statusLabel.text = status;
}

- (CGFloat)progress {
	return progressBar.progress;
}

- (void)setProgress:(CGFloat)progress {
	progressBar.progress = progress;
}

- (void)stopDownload:(UIBarButtonItem *)sender {
	ReportDownloadCoordinator *coordinator = [ReportDownloadCoordinator sharedReportDownloadCoordinator];
	[coordinator cancelAllDownloads];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
	if ([keyPath isEqualToString:@"downloadStatus"]) {
		self.status = change[NSKeyValueChangeNewKey];
	}
	if ([keyPath isEqualToString:@"downloadProgress"]) {
		self.progress = [change[NSKeyValueChangeNewKey] floatValue];
	}
}

@end
