//
//  ReviewsParser.h
//  AppSales
//
//  Created by Nicolas Gomollon on 12/3/15.
//
//

#import <Foundation/Foundation.h>

extern NSString *const kReviewUpdatedKey;
extern NSString *const kReviewTitleKey;
extern NSString *const kReviewContentKey;
extern NSString *const kReviewRatingKey;
extern NSString *const kReviewVersionKey;
extern NSString *const kReviewAuthorNameKey;

@interface ReviewsParser : NSObject <NSXMLParserDelegate> {
	NSXMLParser *parser;
	NSMutableArray *reviews;
	NSMutableDictionary *currentElement;
	NSMutableString *currentElementData;
}

- (id)initWithData:(NSData *)data;
- (BOOL)parse;
- (NSArray *)reviews;

@end
