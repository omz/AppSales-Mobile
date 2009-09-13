/*
 ProductCell.h
 AppSalesMobile
 
 * Copyright (c) 2008, omz:software
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the <organization> nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY omz:software ''AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL <copyright holder> BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "ProductCell.h"
#import "CurrencyManager.h"

@implementation ProductCell

@synthesize totalRevenue, graphColor, productInfo;

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier]) {
		UIColor *calendarBackgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
		UIView *calendarBackgroundView = [[[UIView alloc] initWithFrame:CGRectMake(0,0,45,44)] autorelease];
		calendarBackgroundView.backgroundColor = calendarBackgroundColor;
		
		iconView = [[[UIImageView alloc] initWithFrame:CGRectMake(6, 7, 28, 28)] autorelease];
		iconView.image = [UIImage imageNamed:@"Product.png"];
		
		UIImageView *iconMaskView = [[[UIImageView alloc] initWithFrame:CGRectMake(4, 6, 32, 32)] autorelease];
		iconMaskView.image = [UIImage imageNamed:@"ProductMask.png"];
		
		detailsLabel = [[[UILabel alloc] initWithFrame:CGRectMake(50, 27, 250, 14)] autorelease];
		detailsLabel.textColor = [UIColor blackColor];
		detailsLabel.font = [UIFont systemFontOfSize:12.0]; 
		detailsLabel.textAlignment = UITextAlignmentCenter;
		
		revenueLabel = [[[UILabel alloc] initWithFrame:CGRectMake(50, 0, 100, 30)] autorelease];
		revenueLabel.font = [UIFont boldSystemFontOfSize:20.0];
		revenueLabel.textAlignment = UITextAlignmentRight;
		revenueLabel.adjustsFontSizeToFitWidth = YES;
		
		graphLabel = [[[UILabel alloc] initWithFrame:CGRectMake(160, 4, 130, 21)] autorelease];
		graphLabel.textAlignment = UITextAlignmentRight;
		graphLabel.font = [UIFont boldSystemFontOfSize:12.0];
		graphLabel.backgroundColor = [UIColor clearColor];
		graphLabel.textColor = [UIColor whiteColor];
		graphLabel.text = @"## %";
		
		self.graphColor = [UIColor colorWithRed:0.54 green:0.61 blue:0.67 alpha:1.0];
		
		UIView *graphBackground = [[[UIView alloc] initWithFrame:CGRectMake(160, 4, 130, 21)] autorelease];
		graphBackground.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1.0];
		
		graphView = [[[UIView alloc] initWithFrame:CGRectMake(160, 4, 130, 21)] autorelease];
		graphView.backgroundColor = self.graphColor;
		
		[self.contentView addSubview:calendarBackgroundView];
		[self.contentView addSubview:iconView];
		[self.contentView addSubview:revenueLabel];
		[self.contentView addSubview:graphBackground];
		[self.contentView addSubview:graphView];
		[self.contentView addSubview:graphLabel];
		[self.contentView addSubview:iconView];
		[self.contentView addSubview:iconMaskView];
		[self.contentView addSubview:detailsLabel];
		
		percentFormatter = [NSNumberFormatter new];
		[percentFormatter setMaximumFractionDigits:1];
		[percentFormatter setMinimumIntegerDigits:1];
		
		revenueFormatter = [NSNumberFormatter new];
		[revenueFormatter setMinimumFractionDigits:2];
		[revenueFormatter setMaximumFractionDigits:2];
		[revenueFormatter setMinimumIntegerDigits:1];
		
		self.totalRevenue = 1.0;
    }
    return self;
}

- (void)setAppIcon:(UIImage *)newIcon
{
	iconView.image = newIcon;
}

- (void)setProductInfo:(NSDictionary *)newProductInfo
{
	[newProductInfo retain];
	[productInfo release];
	productInfo = newProductInfo;
	if (productInfo == nil)
		return;
	
	NSString *details = [NSString stringWithFormat:@"%@ × %@", [productInfo objectForKey:@"units"], [productInfo objectForKey:@"name"]];
	detailsLabel.text = details;
	
	revenueLabel.text = [[CurrencyManager sharedManager] baseCurrencyDescriptionForAmount:[revenueFormatter stringFromNumber:[productInfo objectForKey:@"revenue"]]];
	
	float revenue = [[productInfo objectForKey:@"revenue"] floatValue];
	float percent;
	if (revenue > 0)
		percent = revenue / self.totalRevenue;
	else
		percent = 0.0;
	NSString *percentString = [NSString stringWithFormat:@"%@ %% ", [percentFormatter stringFromNumber:[NSNumber numberWithFloat:percent*100]]];
	graphLabel.text = percentString;
	
	graphView.frame = CGRectMake(160, 4, 130.0 * percent, 21);
	
}

- (void)dealloc 
{
	self.graphColor = nil;
	self.productInfo = nil;
	[revenueFormatter release];
	[percentFormatter release];
	[super dealloc];
}


@end
