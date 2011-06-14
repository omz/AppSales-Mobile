//
//  ReviewCell.m
//  AppSalesMobile
//
//  Created by Ole Zorn on 12.09.09.
//  Copyright 2009 omz:software. All rights reserved.
//

#import "ReviewCell.h"
#import "Review.h"
#import "Day.h"
#import "NSDateFormatter+SharedInstances.h"

@implementation ReviewCell

@synthesize review;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        cellView = [[ReviewCellView alloc] initWithCell:self];
		[self.contentView addSubview:cellView];
        [cellView release];
    }
    return self;
}

- (void)setReview:(Review *)newReview
{
	[newReview retain];
	[review release];
	review = newReview;
	
	[cellView setNeedsDisplay];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated 
{
	[super setSelected:selected animated:animated];
}

- (void)dealloc 
{
	[review release];
    [super dealloc];
}


@end


#define CELL_COUNTRY_WIDTH 37
#define CELL_COUNTRY_HEIGHT 84

@implementation ReviewCellView

- (id)initWithCell:(ReviewCell *)reviewCell
{
	[super initWithFrame:reviewCell.bounds];
	self.backgroundColor = [UIColor whiteColor];
	self.frame = CGRectMake(0,0,320,CELL_COUNTRY_HEIGHT);
	cell = reviewCell;
	
	return self;
}

- (void)drawRect:(CGRect)rect
{
	CGContextRef c = UIGraphicsGetCurrentContext();
	Review *review = cell.review;
	if (review.newOrUpdatedReview) {
		[[UIColor colorWithRed:0.85 green:0.85 blue:0.95 alpha:1.0] set];
	} else {
		[[UIColor colorWithWhite:0.95 alpha:1.0] set];
	}
	CGContextFillRect(c, CGRectMake(0,0,CELL_COUNTRY_WIDTH,CELL_COUNTRY_HEIGHT));
	
	UIImage *flagImage = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png", review.countryCode]];
	[flagImage drawInRect:CGRectMake(6, 30, 24, 24)];
    
    UIColor *whiteColor = [UIColor whiteColor];
    UIColor *darkGrayColor = [UIColor darkGrayColor];
    UIColor *blackColor = [UIColor blackColor];
	[blackColor set];
    
	[[review.countryCode uppercaseString] drawInRect:CGRectMake(0, 54, CELL_COUNTRY_WIDTH, 9) withFont:[UIFont systemFontOfSize:9.0]
									   lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentCenter];
	
	NSMutableString *starsString = [NSMutableString stringWithCapacity:5];
	for (NSUInteger i = review.stars; i > 0 ; i--) {
		[starsString appendString:@"★"];
	}
	
	[[UIColor colorWithRed:1.0 green:0.8 blue:0.0 alpha:1.0] set];
	[starsString drawInRect:CGRectMake(CELL_COUNTRY_WIDTH+5, 0, 100, 14) withFont:[UIFont boldSystemFontOfSize:14.0] lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentLeft];
	
	[((cell.highlighted) ? whiteColor : darkGrayColor) set];
	NSString *userAndDate = [NSString stringWithFormat:@"%@  –  %@", review.user, [[NSDateFormatter sharedShortDateFormatter] stringFromDate:review.reviewDate]];
	[userAndDate drawInRect:CGRectMake(125, 2, 188, 14) withFont:[UIFont boldSystemFontOfSize:12.0] lineBreakMode:UILineBreakModeMiddleTruncation alignment:UITextAlignmentRight];
		
	[((cell.highlighted) ? whiteColor : blackColor) set];
	[review.presentationTitle drawInRect:CGRectMake(CELL_COUNTRY_WIDTH+5, 17, 265, 18) withFont:[UIFont boldSystemFontOfSize:15.0] lineBreakMode:UILineBreakModeTailTruncation alignment:UITextAlignmentLeft];
		
	[((cell.highlighted) ? whiteColor : darkGrayColor) set];
	[review.presentationText drawInRect:CGRectMake(CELL_COUNTRY_WIDTH+5, 36, 265, 45) withFont:[UIFont systemFontOfSize:12.0] lineBreakMode:UILineBreakModeTailTruncation alignment:UITextAlignmentLeft];
	
}	

@end
