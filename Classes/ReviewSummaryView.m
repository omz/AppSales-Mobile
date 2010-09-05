//
//  ReviewSummaryView.m
//  AppSalesMobile
//
//  Created by Ole Zorn on 06.04.10.
//  Copyright 2010 omz:software. All rights reserved.
//

#import "ReviewSummaryView.h"
#import "AppIconManager.h"
#import "App.h"
#import "Review.h"

@implementation ReviewSummaryView

@synthesize app;

- (id)initWithFrame:(CGRect)frame app:(App *)anApp
{
	if ((self = [super initWithFrame:frame])) {
		UIImageView *backgroundView = [[[UIImageView alloc] initWithFrame:self.bounds] autorelease];
		backgroundView.image = [UIImage imageNamed:@"ReviewBackground.png"];
		[self addSubview:backgroundView];
		self.app = anApp;
		
		UIImageView *iconView = [[[UIImageView alloc] initWithFrame:CGRectMake(84, 13, 57, 57)] autorelease];
		iconView.image = [[AppIconManager sharedManager] iconForAppID:app.appID];
		[self addSubview:iconView];
		
		UILabel *nameLabel = [[[UILabel alloc] initWithFrame:CGRectMake(10, 76, 205, 20)] autorelease];
		nameLabel.font = [UIFont boldSystemFontOfSize:16.0];
		nameLabel.text = app.appName;
		nameLabel.textAlignment = UITextAlignmentCenter;
		nameLabel.backgroundColor = [UIColor clearColor];
		nameLabel.textColor = [UIColor darkGrayColor];
		[self addSubview:nameLabel];
		
		UILabel *numberOfReviewsLabel = [[[UILabel alloc] initWithFrame:CGRectMake(10, 95, 205, 20)] autorelease];
		numberOfReviewsLabel.font = [UIFont systemFontOfSize:14.0];
		numberOfReviewsLabel.text = [NSString stringWithFormat:@"%i Reviews (+%i)", [app.reviewsByUser count], app.newReviewsCount];
		numberOfReviewsLabel.textAlignment = UITextAlignmentCenter;
		numberOfReviewsLabel.backgroundColor = [UIColor clearColor];
		numberOfReviewsLabel.textColor = [UIColor darkGrayColor];
		[self addSubview:numberOfReviewsLabel];
		
		int maxNumberOfReviews = 1;
		NSMutableDictionary *numberOfReviewsByStars = [NSMutableDictionary dictionary];
		for (Review *review in [app.reviewsByUser allValues]) {
			int numberOfReviews = [[numberOfReviewsByStars objectForKey:[NSNumber numberWithInt:review.stars]] intValue];
			numberOfReviews++;
			if (numberOfReviews > maxNumberOfReviews) maxNumberOfReviews = numberOfReviews;
			[numberOfReviewsByStars setObject:[NSNumber numberWithInt:numberOfReviews] forKey:[NSNumber numberWithInt:review.stars]];
		}
		
		int i = 0;
		for (int stars=5; stars>0; stars--) {
			UILabel *starsLabel = [[[UILabel alloc] initWithFrame:CGRectMake(10, 122 + (i * 18), 80, 15)] autorelease];
			NSMutableString *starsString = [NSMutableString string];
			for (int s=0; s<stars; s++) { [starsString appendString:@"★"]; }
			starsLabel.text = starsString;
			starsLabel.textAlignment = UITextAlignmentRight;
			starsLabel.font = [UIFont boldSystemFontOfSize:14.0];
			starsLabel.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
			starsLabel.textColor = [UIColor grayColor];
			[self addSubview:starsLabel];
			
			int numberOfReviews = [[numberOfReviewsByStars objectForKey:[NSNumber numberWithInt:stars]] intValue];
			float barWidth = ((float)numberOfReviews / (float)maxNumberOfReviews) * 80;
			UIView *barView = [[[UIView alloc] initWithFrame:CGRectMake(95, 122 + (i * 18), barWidth, 15)] autorelease];
			barView.backgroundColor = [UIColor grayColor];
			barView.userInteractionEnabled = NO;
			[self addSubview:barView];
			
			numberOfReviewsLabel = [[[UILabel alloc] initWithFrame:CGRectMake(barView.frame.origin.x + barView.frame.size.width + 5, 122 + (i*18), 35, 15)] autorelease];
			numberOfReviewsLabel.text = [NSString stringWithFormat:@"%i", numberOfReviews];
			numberOfReviewsLabel.font = [UIFont systemFontOfSize:13.0];
			numberOfReviewsLabel.textColor = [UIColor grayColor];
			numberOfReviewsLabel.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
			[self addSubview:numberOfReviewsLabel];
			
			i++;
		}
		
    }
    return self;
}


- (void)dealloc 
{
	[app release];
    [super dealloc];
}


@end
