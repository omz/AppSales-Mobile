
#import "NSString+UnescapeHtml.h"


@implementation NSString (unescapehtml)

static inline void replace(NSMutableString *string, NSString *search, NSString *replacement) {
	[string replaceOccurrencesOfString:search withString:replacement options:NSCaseInsensitiveSearch range:NSMakeRange(0, string.length)];
}

//
// http://stackoverflow.com/questions/705448/iphone-sdk-problem-with-ampersand-in-the-url-string
//
- (NSString*) correctlyEncodeToURL {
	NSMutableString *escaped = [NSMutableString stringWithString:[self stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];       
	replace(escaped, @"&",  @"%26");
	replace(escaped, @"+",  @"%2B");
	replace(escaped, @",",  @"%2C");
	replace(escaped, @"/",  @"%2F");
	replace(escaped, @":",  @"%3A");
	replace(escaped, @";",  @"%3B");
	replace(escaped, @"=",  @"%3D");
	replace(escaped, @"?",  @"%3F");
	replace(escaped, @"@",  @"%40");
	replace(escaped, @" ",  @"%20");
	replace(escaped, @"\t", @"%09");
	replace(escaped, @"#",  @"%23");
	replace(escaped, @"<",  @"%3C");
	replace(escaped, @">",  @"%3E");
	replace(escaped, @"\"", @"%22");
	replace(escaped, @"\n", @"%0A");
	return escaped;
}

- (NSString*) removeHtmlEscaping {
	const NSUInteger length = self.length;
	NSMutableString *translatedText = [NSMutableString stringWithCapacity:length];
	NSRange range = [self rangeOfString: @"&#"];
	int processedSoFar = 0;
	while (range.location != NSNotFound) {
		const int pos = range.location;
		[translatedText appendString:[self substringWithRange:NSMakeRange(processedSoFar, pos - processedSoFar)]];
		range = [self rangeOfString: @";" options:0 range: NSMakeRange(pos + 2, length - pos - 2)];
		const int code = [self substringWithRange:NSMakeRange(pos + 2, range.location - pos - 2)].intValue;
		[translatedText appendFormat: @"%C", (unichar)code];
		processedSoFar = range.location + 1;
		range = [self rangeOfString: @"&#" options:0 range:NSMakeRange(processedSoFar, length - processedSoFar)];
	}
	[translatedText appendString:[self substringFromIndex:processedSoFar]];
	
	
	replace(translatedText, @"&apos;", @"'");
	replace(translatedText, @"&quot;", @"\"");
	replace(translatedText, @"&amp;",  @"&");
	replace(translatedText, @"&lt;",   @"<");
	replace(translatedText, @"&gt;",   @">");
	
	// not an actual escaped character, but shows up enough that we'll deal with it here
	replace(translatedText, @"<br>",   @"\n");
	replace(translatedText, @"<br/>",  @"\n");
	replace(translatedText, @"<br />", @"\n");
	return translatedText;
}

- (NSString*) encodeIntoBasicHtml {
	NSMutableString *encoded = [NSMutableString stringWithString:self];
	replace(encoded, @"&",  @"&amp;"); // must be first
	replace(encoded, @"'",  @"&apos;");
	replace(encoded, @"\"", @"&quot;");
	replace(encoded, @"<",  @"&lt;");
	replace(encoded, @">",  @"&gt;");
	replace(encoded, @"  ", @" &nbsp;");
	replace(encoded, @"\n", @"<br/>"); // must be last
	return encoded;
}


@end
