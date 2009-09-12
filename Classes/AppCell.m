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
	[super initWithFrame:appCell.bounds];
	self.backgroundColor = [UIColor whiteColor];
	cell = appCell;
	return self;
}

- (void)drawRect:(CGRect)rect
{
	CGContextRef c = UIGraphicsGetCurrentContext();
	App *app = cell.app;
	
	[[UIColor colorWithWhite:0.95 alpha:1.0] set];
	CGContextFillRect(c, CGRectMake(0,0,45,44));
	
	UIImage *appIcon = [[AppIconManager sharedManager] iconForAppNamed:app.appName];
	[appIcon drawInRect:CGRectMake(6, 7, 28, 28)];
	[[UIImage imageNamed:@"ProductMask.png"] drawInRect:CGRectMake(4, 6, 32, 32)];
	
	[((cell.highlighted) ? [UIColor whiteColor] : [UIColor blackColor]) set];
	[app.appName drawInRect:CGRectMake(50, 3, 140, 30) withFont:[UIFont boldSystemFontOfSize:17.0]];
	
	[[UIImage imageNamed:@"5stars_gray.png"] drawInRect:CGRectMake(200, 15, 90, 15)];
	UIImage *starsImage = [UIImage imageNamed:@"5stars.png"];
	UIGraphicsBeginImageContext(CGSizeMake(90,15));
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	[starsImage drawInRect:CGRectMake(0,0,90,15)];
	float averageStars = [app averageStars];
	float widthOfStars = 90.0 - (averageStars / 5.0) * 90.0;
	[[UIColor clearColor] set];
	CGContextSetBlendMode(ctx, kCGBlendModeCopy);
	CGContextFillRect(ctx, CGRectMake(90 - widthOfStars, 0, widthOfStars, 15));
	UIImage *averageStarsImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	[averageStarsImage drawInRect:CGRectMake(200, 15, 90, 15)];
	//[[UIImage imageNamed:@"5stars.png"] drawInRect:CGRectMake(200, 15, 88, 15)];
	
	[((cell.highlighted) ? [UIColor whiteColor] : [UIColor darkGrayColor]) set];
	int numberOfReviews = [app.reviewsByUser count];
	NSString *numberOfReviewsDescription = [NSString stringWithFormat:NSLocalizedString(@"%i Reviews (%i new)",nil), numberOfReviews, app.newReviewsCount];
	[numberOfReviewsDescription drawInRect:CGRectMake(50, 25, 140, 15) withFont:[UIFont systemFontOfSize:12.0]];
}	

@end