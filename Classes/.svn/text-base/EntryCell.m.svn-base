/*
 EntryCell.m
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

#import "EntryCell.h"
#import "Entry.h"

@implementation EntryCell

@synthesize entry;

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier 
{
    if (self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier]) {
		iconView = [[[UIImageView alloc] initWithFrame:CGRectMake(6,6,32,32)] autorelease];
		descriptionLabel = [[[UILabel alloc] initWithFrame:CGRectMake(45, 0, 270, 44)] autorelease];
		descriptionLabel.font = [UIFont systemFontOfSize:15.0];
		descriptionLabel.lineBreakMode = UILineBreakModeWordWrap;
		descriptionLabel.numberOfLines = 2;
		
		[self.contentView addSubview:descriptionLabel];
		[self.contentView addSubview:iconView];
		
    }
    return self;
}

- (void)setEntry:(Entry *)newEntry
{
	[newEntry retain];
	[entry release];
	entry = newEntry;
	if (entry == nil)
		return;
	
	descriptionLabel.text = [self.entry description];
	UIImage *icon;
	if (self.entry.transactionType == 1) {
		if (self.entry.units >= 0)
			icon = [UIImage imageNamed:@"Purchase.png"];
		else
			icon = [UIImage imageNamed:@"Return.png"];
	}
	else {
		icon = [UIImage imageNamed:@"Download.png"];
	}
	iconView.image = icon;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    [super setSelected:selected animated:animated];
}


- (void)dealloc 
{
	self.entry = nil;
    [super dealloc];
}


@end
