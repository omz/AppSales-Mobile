//
//  ReviewCell.m
//  AppSales
//
//  Created by Nicolas Gomollon on 12/17/15.
//
//

#import "ReviewCell.h"
#import "Review.h"

@implementation ReviewCell

@synthesize review;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
	if (self) {
		// Initialization code
		self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		dateFormatter = [[NSDateFormatter alloc] init];
		dateFormatter.dateStyle = NSDateFormatterMediumStyle;
	}
	return self;
}

- (void)prepareForReuse {
	[super prepareForReuse];
	self.imageView.image = nil;
	self.textLabel.font = [UIFont systemFontOfSize:15.0f];
	self.textLabel.text = NSLocalizedString(@"Untitled", nil);
	NSString *detailText = [@"" stringByPaddingToLength:5 withString:@"\u2606" startingAtIndex:0];
	NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:detailText];
	[attributedText addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:12.0f] range:NSMakeRange(0, detailText.length)];
	[attributedText addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:255.0f/255.0f green:150.0f/255.0f blue:0.0f/255.0f alpha:1.0f] range:NSMakeRange(0, detailText.length)];
	self.detailTextLabel.attributedText = attributedText;
}

- (void)setReview:(Review *)_review {
	review = _review;
	
	self.imageView.image = [UIImage imageNamed:review.countryCode.uppercaseString];
	
	self.textLabel.font = review.unread.boolValue ? [UIFont boldSystemFontOfSize:15.0f] : [UIFont systemFontOfSize:15.0f];
	self.textLabel.text = review.title ?: NSLocalizedString(@"Untitled", nil);
	
	NSString *ratingString = [@"" stringByPaddingToLength:review.rating.integerValue withString:@"\u2605" startingAtIndex:0];
	ratingString = [ratingString stringByPaddingToLength:5 withString:@"\u2606" startingAtIndex:0];
	NSString *detailText = [NSString stringWithFormat:@"%@ %@ - %@", ratingString, review.nickname, [dateFormatter stringFromDate:review.created]];
	
	NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:detailText];
	[attributedText addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:12.0f] range:NSMakeRange(0, detailText.length)];
	[attributedText addAttribute:NSForegroundColorAttributeName value:[UIColor darkGrayColor] range:NSMakeRange(0, detailText.length)];
	[attributedText addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:255.0f/255.0f green:150.0f/255.0f blue:0.0f/255.0f alpha:1.0f] range:NSMakeRange(0, 5)];
	
	self.detailTextLabel.attributedText = attributedText;
}

@end
