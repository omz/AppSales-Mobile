
#import "NSString+UnescapeHtml.h"


@implementation NSString (html)

- (NSString*) correctlyEncodeToURL {
	// http://stackoverflow.com/questions/705448/iphone-sdk-problem-with-ampersand-in-the-url-string
	NSMutableString *escaped = [NSMutableString stringWithString:[self stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];       
	[escaped replaceOccurrencesOfString:@"&" withString:@"%26" options:NSCaseInsensitiveSearch range:NSMakeRange(0, escaped.length)];
	[escaped replaceOccurrencesOfString:@"+" withString:@"%2B" options:NSCaseInsensitiveSearch range:NSMakeRange(0, escaped.length)];
	[escaped replaceOccurrencesOfString:@"," withString:@"%2C" options:NSCaseInsensitiveSearch range:NSMakeRange(0, escaped.length)];
	[escaped replaceOccurrencesOfString:@"/" withString:@"%2F" options:NSCaseInsensitiveSearch range:NSMakeRange(0, escaped.length)];
	[escaped replaceOccurrencesOfString:@":" withString:@"%3A" options:NSCaseInsensitiveSearch range:NSMakeRange(0, escaped.length)];
	[escaped replaceOccurrencesOfString:@";" withString:@"%3B" options:NSCaseInsensitiveSearch range:NSMakeRange(0, escaped.length)];
	[escaped replaceOccurrencesOfString:@"=" withString:@"%3D" options:NSCaseInsensitiveSearch range:NSMakeRange(0, escaped.length)];
	[escaped replaceOccurrencesOfString:@"?" withString:@"%3F" options:NSCaseInsensitiveSearch range:NSMakeRange(0, escaped.length)];
	[escaped replaceOccurrencesOfString:@"@" withString:@"%40" options:NSCaseInsensitiveSearch range:NSMakeRange(0, escaped.length)];
	[escaped replaceOccurrencesOfString:@" " withString:@"%20" options:NSCaseInsensitiveSearch range:NSMakeRange(0, escaped.length)];
	[escaped replaceOccurrencesOfString:@"\t" withString:@"%09" options:NSCaseInsensitiveSearch range:NSMakeRange(0, escaped.length)];
	[escaped replaceOccurrencesOfString:@"#" withString:@"%23" options:NSCaseInsensitiveSearch range:NSMakeRange(0, escaped.length)];
	[escaped replaceOccurrencesOfString:@"<" withString:@"%3C" options:NSCaseInsensitiveSearch range:NSMakeRange(0, escaped.length)];
	[escaped replaceOccurrencesOfString:@">" withString:@"%3E" options:NSCaseInsensitiveSearch range:NSMakeRange(0, escaped.length)];
	[escaped replaceOccurrencesOfString:@"\"" withString:@"%22" options:NSCaseInsensitiveSearch range:NSMakeRange(0, escaped.length)];
	[escaped replaceOccurrencesOfString:@"\n" withString:@"%0A" options:NSCaseInsensitiveSearch range:NSMakeRange(0, escaped.length)];
	return escaped;
}


- (NSString*) removeHtmlEscaping {
	NSMutableString* translatedText = [NSMutableString string];
	NSRange range = [self rangeOfString: @"&#"];
	int processedSoFar = 0;
	while (range.location != NSNotFound) {
		int pos = range.location;
		[translatedText appendString: [self substringWithRange: NSMakeRange(processedSoFar, pos - processedSoFar)]];
		range = [self rangeOfString: @";" options: 0 range: NSMakeRange(pos + 2, [self length] - pos - 2)];
		int code = [[self substringWithRange: NSMakeRange(pos + 2, range.location - pos - 2)] intValue];
		[translatedText appendFormat: @"%C", (unichar) code];
		processedSoFar = range.location + 1;
		range = [self rangeOfString: @"&#" options: 0 range: NSMakeRange(processedSoFar, [self length] - processedSoFar)];
	}
	[translatedText appendString: [self substringFromIndex: processedSoFar]];
	
	
	[translatedText replaceOccurrencesOfString:@"&apos;" withString:@"'" options:NSCaseInsensitiveSearch 
										 range:NSMakeRange(0, translatedText.length)];
	[translatedText replaceOccurrencesOfString:@"&quot;" withString:@"\"" options:NSCaseInsensitiveSearch 
										 range:NSMakeRange(0, translatedText.length)];
	[translatedText replaceOccurrencesOfString:@"&amp;" withString:@"&" options:NSCaseInsensitiveSearch 
										 range:NSMakeRange(0, translatedText.length)];
	[translatedText replaceOccurrencesOfString:@"&lt;" withString:@"<" options:NSCaseInsensitiveSearch 
										 range:NSMakeRange(0, translatedText.length)];
	[translatedText replaceOccurrencesOfString:@"&gt;" withString:@">" options:NSCaseInsensitiveSearch 
										 range:NSMakeRange(0, translatedText.length)];
	
	// not an actual escaped character, but shows up enough that we'll deal with it here
	[translatedText replaceOccurrencesOfString:@"<br/>" withString:@"\n" options:NSCaseInsensitiveSearch 
										 range:NSMakeRange(0, translatedText.length)];
	[translatedText replaceOccurrencesOfString:@"<br />" withString:@"\n" options:NSCaseInsensitiveSearch 
										 range:NSMakeRange(0, translatedText.length)];
	return translatedText;
}

- (NSString*) encodeIntoBasicHtml {
	NSMutableString *encoded = [NSMutableString stringWithString:self];
	[encoded replaceOccurrencesOfString:@"&" withString:@"&amp;" options:NSCaseInsensitiveSearch
								  range:NSMakeRange(0, encoded.length)]; // must be first
	[encoded replaceOccurrencesOfString:@"'" withString:@"&apos;" options:NSCaseInsensitiveSearch
								  range:NSMakeRange(0, encoded.length)];
	[encoded replaceOccurrencesOfString:@"\"" withString:@"&quot;" options:NSCaseInsensitiveSearch
								  range:NSMakeRange(0, encoded.length)];
	[encoded replaceOccurrencesOfString:@"<" withString:@"&lt;" options:NSCaseInsensitiveSearch 
								  range:NSMakeRange(0, encoded.length)];
	[encoded replaceOccurrencesOfString:@">" withString:@"&gt;" options:NSCaseInsensitiveSearch
								  range:NSMakeRange(0, encoded.length)];
	[encoded replaceOccurrencesOfString:@"  " withString:@" &nbsp;" options:NSCaseInsensitiveSearch
								  range:NSMakeRange(0, encoded.length)];
	[encoded replaceOccurrencesOfString:@"\n" withString:@"<br/>" options:NSCaseInsensitiveSearch
								  range:NSMakeRange(0, encoded.length)]; // must be last
	return encoded;
}


@end
