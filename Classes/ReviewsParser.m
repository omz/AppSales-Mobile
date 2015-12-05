//
//  ReviewsParser.m
//  AppSales
//
//  Created by Nicolas Gomollon on 12/3/15.
//
//

#import "ReviewsParser.h"

NSString *const kElementEntry  = @"entry";
NSString *const kElementArtist = @"im:artist";

NSString *const kReviewUpdatedKey    = @"updated";
NSString *const kReviewTitleKey      = @"title";
NSString *const kReviewContentKey    = @"content";
NSString *const kReviewRatingKey     = @"im:rating";
NSString *const kReviewVersionKey    = @"im:version";
NSString *const kReviewAuthorNameKey = @"name";

@implementation ReviewsParser

- (instancetype)initWithData:(NSData *)data {
	self = [super init];
	if (self) {
		// Initialization code
		parser = [[NSXMLParser alloc] initWithData:data];
		parser.delegate = self;
		
		reviews = [[NSMutableArray alloc] init];
	}
	return self;
}

- (BOOL)parse {
	return [parser parse];
}

- (NSArray *)reviews {
	return reviews;
}

#pragma mark - NSXMLParserDelegate Methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary<NSString *,NSString *> *)attributeDict {
	currentElementData = [[NSMutableString alloc] init];
	if ([elementName isEqualToString:kElementEntry]) {
		currentElement = [[NSMutableDictionary alloc] init];
	}
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	[currentElementData appendString:string];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
	if (currentElement != nil) {
		// We only care about elements in a valid review entry.
		if ([elementName isEqualToString:kElementEntry]) {
			// We are done parsing the review entry.
			[reviews addObject:currentElement];
			currentElement = nil;
		} else if ([elementName isEqualToString:kElementArtist]) {
			// This is the app entry; not a review entry.
			currentElement = nil;
		} else if ([elementName isEqualToString:kReviewUpdatedKey] ||
				   [elementName isEqualToString:kReviewTitleKey] ||
				   [elementName isEqualToString:kReviewVersionKey] ||
				   [elementName isEqualToString:kReviewAuthorNameKey]) {
			// This is an element we're looking for, so save it.
			currentElement[elementName] = currentElementData;
		} else if ([elementName isEqualToString:kReviewContentKey]) {
			// This is an element we're looking for, so save it.
			currentElement[elementName] = [self parseContentHTML:currentElementData];
		} else if ([elementName isEqualToString:kReviewRatingKey]) {
			// This is an element we're looking for, so save it.
			currentElement[elementName] = @([currentElementData integerValue]);
		}
	}
	currentElementData = nil;
}

- (NSString *)parseContentHTML:(NSString *)contentHTML {
	NSScanner *scanner = [NSScanner scannerWithString:contentHTML];
	NSString *text = nil;
	[scanner scanUpToString:@"</table>" intoString:nil];
	[scanner scanString:@"</table>" intoString:nil];
	[scanner scanUpToString:@"<font" intoString:nil];
	[scanner scanString:@"<font" intoString:nil];
	[scanner scanUpToString:@"><br/>" intoString:nil];
	[scanner scanString:@"><br/>" intoString:nil];
	[scanner scanUpToString:@"</font><br/>" intoString:&text];
	return text;
}

@end
