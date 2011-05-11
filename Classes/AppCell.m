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
	if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
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
    
    UIColor *whiteColor = [UIColor whiteColor];
    if (cell.highlighted) {
        [whiteColor set];
    } else {
        [[UIColor blackColor] set];
    }
	[app.appName drawInRect:CGRectMake(50, 3, 140, 30) withFont:[UIFont boldSystemFontOfSize:17.0]];
	
	[[UIImage imageNamed:@"5stars_gray.png"] drawInRect:CGRectMake(200, 8, 90, 15)];
	UIImage *starsImage = [UIImage imageNamed:@"5stars.png"];
	CGSize size = CGSizeMake(90,15);
	if (&UIGraphicsBeginImageContextWithOptions) {
		UIGraphicsBeginImageContextWithOptions(size, NO, UIScreen.mainScreen.scale);
	} else { // iOS 3.x
		UIGraphicsBeginImageContext(size);
	}
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	[starsImage drawAtPoint:CGPointZero];
	float averageStars = [app currentStars];
	float widthOfStars = 90 - (averageStars / 5.0) * 90.0;
	[[UIColor clearColor] set];
	CGContextSetBlendMode(ctx, kCGBlendModeCopy);
	CGContextFillRect(ctx, CGRectMake(90 - widthOfStars, 0, widthOfStars, 15));
	UIImage *averageStarsImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	[averageStarsImage drawInRect:CGRectMake(200, 8, 90, 15)];
	//[[UIImage imageNamed:@"5stars.png"] drawInRect:CGRectMake(200, 15, 88, 15)];
	
	if (cell.highlighted) {
		[whiteColor set];
	} else if(app.newCurrentReviewsCount) {
		[[UIColor redColor] set];
	} else {
		[[UIColor darkGrayColor] set];
    }
    
    UIFont *systemFontOfSize12 = [UIFont systemFontOfSize:12.0];
    
	[app.currentVersion drawInRect:CGRectMake(50, 25, 140, 15) withFont:systemFontOfSize12];
	NSString *recentSummary;
	if (app.newCurrentReviewsCount) {
        recentSummary = [NSString stringWithFormat:NSLocalizedString(@"%1.2f avg, %4i new",nil), app.currentStars, app.newCurrentReviewsCount];
	} else {
        recentSummary = [NSString stringWithFormat:NSLocalizedString(@"%1.2f avg, %4i reviews",nil), app.currentStars, app.currentReviewsCount];
    }
    CGSize recentSummarySize = [recentSummary sizeWithFont:systemFontOfSize12];
	[recentSummary drawInRect:CGRectMake(290-recentSummarySize.width, 40-recentSummarySize.height, recentSummarySize.width, recentSummarySize.height) withFont:systemFontOfSize12];
	
	if (cell.highlighted) {
		[whiteColor set];
    } else if(app.newReviewsCount) {
        [[UIColor colorWithRed:255/255.0f green:90/255.0f blue:90/255.0f alpha:1] set];
    } else {
		[[UIColor lightGrayColor] set];
    }
    
    UIFont *italicSystemFontOfSize12 = systemFontOfSize12; //[UIFont italicSystemFontOfSize:12.0];
    
	[NSLocalizedString(@"Overall", nil) drawInRect:CGRectMake(50, 40, 140, 15) withFont:italicSystemFontOfSize12];
	NSString *overallSummary;
	if (app.newReviewsCount) {
        overallSummary = [NSString stringWithFormat:NSLocalizedString(@"%1.2f avg, %4i new",nil), app.averageStars, app.newReviewsCount];
	} else {
        overallSummary = [NSString stringWithFormat:NSLocalizedString(@"%1.2f avg, %4i reviews",nil), app.averageStars, app.totalReviewsCount];
    }
    CGSize overallSummarySize = [overallSummary sizeWithFont:systemFontOfSize12];
	[overallSummary drawInRect:CGRectMake(290-overallSummarySize.width, 55-overallSummarySize.height, overallSummarySize.width, overallSummarySize.height) withFont:italicSystemFontOfSize12];
}

@end
