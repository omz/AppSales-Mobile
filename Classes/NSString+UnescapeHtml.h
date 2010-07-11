
#import <Foundation/Foundation.h>

@interface NSString (unescapehtml)

- (NSString*) correctlyEncodeToURL; // works how you'd expect stringByAddingPercentEscapesUsingEncoding() to behave
- (NSString*) removeHtmlEscaping;

- (NSString*) encodeIntoBasicHtml; // converts common html problems, such as <>&'\n

@end
