//
//  AppCell.m
//  AppSalesMobile
//
//  Created by Ole Zorn on 12.09.09.
//  Copyright 2009 omz:software. All rights reserved.
//

#import "AppCell.h"
#import "App.h"
#import "AppIconManager.h"

@implementation AppCell

@synthesize app;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier 
{
	if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
		cellView = [[[AppCellView alloc] initWithCell:self] autorelease];
		[self.contentView addSubview:cellView];
    }
    return self;
}

- (void)setApp:(App *)newApp
{
	[newApp retain];
	[app release];
	app = newApp;
	[cellView setNeedsDisplay];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated 
{
	[super setSelected:selected animated:animated];
}


- (void)dealloc 
{
	[app release];
	
	[super dealloc];
}


@end

@implementation AppCellView

- (id)initWithCell:(AppCell *)appCell
{
    CGRect bounds = appCell.bounds;
    bounds.size.height = 60;
	[super initWithFrame:bounds];
	self.backgroundColor = [UIColor whiteColor];
	cell = appCell;
	return self;
}

- (void)drawRect:(CGRect)rect
{
	CGContextRef c = UIGraphicsGetCurrentContext();
	App *app = cell.app;
	
	[[UIColor colorWithWhite:0.95 alpha:1.0] set];
	CGContextFillRect(c, CGRectMake(0,0,45,59));
	
	UIImage *appIcon = [[AppIconManager sharedManager] iconForAppID:app.appID];
	[appIcon drawInRect:CGRectMake(6, 7, 28, 28)];
	[[UIImage imageNamed:@"ProductMask.png"] drawInRect:CGRectMake(4, 6, 32, 32)];
	
	[((cell.highlighted) ? [UIColor whiteColor] : [UIColor blackColor]) set];
	[app.appName drawInRect:CGRectMake(50, 3, 140, 30) withFont:[UIFont boldSystemFontOfSize:17.0]];
	
	[[UIImage imageNamed:@"5stars_gray.png"] drawInRect:CGRectMake(200, 8, 90, 15)];
	UIImage *starsImage = [UIImage imageNamed:@"5stars.png"];
	CGSize size = CGSizeMake(90,15);
	if (&UIGraphicsBeginImageContextWithOptions) {
		UIGraphicsBeginImageContextWithOptions(size, NO, UIScreen.mainScreen.scale);
	} else { // ipad
		UIGraphicsBeginImageContext(size);
	}
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	[starsImage drawInRect:CGRectMake(0,0,90,15)];
	float averageStars = [app recentStars];
	float widthOfStars = 90.0 - (averageStars / 5.0) * 90.0;
	[[UIColor clearColor] set];
	CGContextSetBlendMode(ctx, kCGBlendModeCopy);
	CGContextFillRect(ctx, CGRectMake(90 - widthOfStars, 0, widthOfStars, 15));
	UIImage *averageStarsImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	[averageStarsImage drawInRect:CGRectMake(200, 8, 90, 15)];
	//[[UIImage imageNamed:@"5stars.png"] drawInRect:CGRectMake(200, 15, 88, 15)];
	
	if(cell.highlighted)
		[[UIColor whiteColor] set];
	else if(app.newRecentReviewsCount)
		[[UIColor redColor] set];
	else
		[[UIColor darkGrayColor] set];
    
	[app.recentVersion drawInRect:CGRectMake(50, 25, 140, 15) withFont:[UIFont systemFontOfSize:12.0]];
	NSString *recentSummary = [NSString stringWithFormat:NSLocalizedString(@"%1.2f avg, %i reviews",nil), app.recentStars, app.recentReviewsCount];
	if (app.newRecentReviewsCount) {
		recentSummary = [recentSummary stringByAppendingFormat:NSLocalizedString(@" (%i new)",nil), app.newRecentReviewsCount];
	}
    CGSize recentSummarySize = [recentSummary sizeWithFont:[UIFont systemFontOfSize:12.0]];
	[recentSummary drawInRect:CGRectMake(290-recentSummarySize.width, 40-recentSummarySize.height, recentSummarySize.width, recentSummarySize.height) withFont:[UIFont systemFontOfSize:12.0]];
	
	if(cell.highlighted)
		[[UIColor whiteColor] set];
	else if(app.newReviewsCount)
		[[UIColor redColor] set];
	else
		[[UIColor lightGrayColor] set];
    
	[@"Overall" drawInRect:CGRectMake(50, 40, 140, 15) withFont:[UIFont italicSystemFontOfSize:12.0]];
	NSString *overallSummary = [NSString stringWithFormat:NSLocalizedString(@"%1.2f avg, %i reviews",nil), app.averageStars, [app.reviewsByUser count]];
	if (app.newRecentReviewsCount) {
		overallSummary = [overallSummary stringByAppendingFormat:NSLocalizedString(@" (%i new)",nil), app.newRecentReviewsCount];
	}
    CGSize overallSummarySize = [overallSummary sizeWithFont:[UIFont systemFontOfSize:12.0]];
	[overallSummary drawInRect:CGRectMake(290-overallSummarySize.width, 55-overallSummarySize.height, overallSummarySize.width, overallSummarySize.height) withFont:[UIFont italicSystemFontOfSize:12.0]];
}

@end
