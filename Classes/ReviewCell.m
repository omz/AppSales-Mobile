//
//  ReviewCell.m
//  AppSalesMobile
//
//  Created by Ole Zorn on 12.09.09.
//  Copyright 2009 omz:software. All rights reserved.
//

#import "ReviewCell.h"
#import "Review.h"

@implementation ReviewCell

@synthesize review;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        cellView = [[[ReviewCellView alloc] initWithCell:self] autorelease];
		[self.contentView addSubview:cellView];
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


@implementation ReviewCellView

- (id)initWithCell:(ReviewCell *)reviewCell
{
	[super initWithFrame:reviewCell.bounds];
	self.backgroundColor = [UIColor whiteColor];
	self.frame = CGRectMake(0,0,320,84);
	cell = reviewCell;
	dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
	
	return self;
}

- (void)drawRect:(CGRect)rect
{
	CGContextRef c = UIGraphicsGetCurrentContext();
	Review *review = cell.review;
	[[UIColor colorWithWhite:0.95 alpha:1.0] set];
	CGContextFillRect(c, CGRectMake(0,0,45,84));
	
	UIImage *flagImage = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png", review.countryCode]];
	[flagImage drawInRect:CGRectMake(6, 20, 32, 32)];
	
	[[UIColor blackColor] set];
	[[review.countryCode uppercaseString] drawInRect:CGRectMake(0, 53, 44, 9) withFont:[UIFont systemFontOfSize:9.0] lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentCenter];
	
	NSMutableString *starsString = [NSMutableString string];
	for (int i = 0; i < review.stars; i++) {
		[starsString appendString:@"★"];
	}
	
	[[UIColor colorWithRed:1.000 green:0.800 blue:0.000 alpha:1.0] set];
	[starsString drawInRect:CGRectMake(50, 0, 75, 14) withFont:[UIFont boldSystemFontOfSize:14.0] lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentLeft];
	
	[((cell.highlighted) ? [UIColor whiteColor] : [UIColor darkGrayColor]) set];
	NSString *userAndDate = [NSString stringWithFormat:@"%@  –  %@", review.user, [dateFormatter stringFromDate:review.reviewDate]];
	[userAndDate drawInRect:CGRectMake(125, 2, 188, 14) withFont:[UIFont boldSystemFontOfSize:12.0] lineBreakMode:UILineBreakModeMiddleTruncation alignment:UITextAlignmentRight];
		
	[((cell.highlighted) ? [UIColor whiteColor] : [UIColor blackColor]) set];
	[review.title drawInRect:CGRectMake(50, 16, 265, 18) withFont:[UIFont boldSystemFontOfSize:15.0] lineBreakMode:UILineBreakModeTailTruncation alignment:UITextAlignmentLeft];
		
	[((cell.highlighted) ? [UIColor whiteColor] : [UIColor darkGrayColor]) set];
	[review.text drawInRect:CGRectMake(50, 36, 265, 45) withFont:[UIFont systemFontOfSize:12.0] lineBreakMode:UILineBreakModeTailTruncation alignment:UITextAlignmentLeft];
	
}	

- (void)dealloc
{
	[dateFormatter release];
	[super dealloc];
}

@end