
#import <Foundation/Foundation.h>

@interface NSString (html)

- (NSString*) correctlyEncodeToURL; // works how you'd expect stringByAddingPercentEscapesUsingEncoding() to behave
- (NSString*) removeHtmlEscaping;

@end
