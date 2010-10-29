#import "NSDictionary+HTTP.h"


@implementation NSDictionary (HTTPExtensions)

- (NSString *) formatForHTTP
{
	return [self formatForHTTPUsingEncoding:NSASCIIStringEncoding];
}

- (NSString *) formatForHTTPUsingEncoding:(NSStringEncoding)inEncoding
{
	return [self formatForHTTPUsingEncoding:inEncoding ordering:nil];
}

- (NSString *) formatForHTTPUsingEncoding:(NSStringEncoding)inEncoding ordering:(NSArray *)inOrdering
{
	NSMutableString *s = [NSMutableString stringWithCapacity:256];
	NSEnumerator *e = (nil == inOrdering) ? [self keyEnumerator] : [inOrdering objectEnumerator];
	CFStringEncoding cfStrEnc = CFStringConvertNSStringEncodingToEncoding(inEncoding);
	
    for (id key in e)
	{
        id keyObject = [self objectForKey: key];
		// conform with rfc 1738 3.3, also escape URL-like characters that might be in the parameters
		NSString *escapedKey
		= (NSString *) CFURLCreateStringByAddingPercentEscapes(
															   NULL, (CFStringRef) key, NULL, (CFStringRef) @";:@&=/+", cfStrEnc);
        if ([keyObject respondsToSelector: @selector(objectEnumerator)])
        {
            for (id	aValue in [keyObject objectEnumerator])
            {
                NSString *escapedObject
                = (NSString *) CFURLCreateStringByAddingPercentEscapes(
                                                                       NULL, (CFStringRef) [aValue description], NULL, (CFStringRef) @";:@&=/+", cfStrEnc);
                [s appendFormat:@"%@=%@&", escapedKey, escapedObject];
				[escapedObject release];
				escapedObject = 0;
            }
        }
        else
        {
            NSString *escapedObject
            = (NSString *) CFURLCreateStringByAddingPercentEscapes(
                                                                   NULL, (CFStringRef) [keyObject description], NULL, (CFStringRef) @";:@&=/+", cfStrEnc);
            [s appendFormat:@"%@=%@&", escapedKey, escapedObject];
			[escapedObject release];
			escapedObject = 0;
        }
		[escapedKey release];
		escapedKey = 0;
	}
	// Delete final & from the string
	if (![s isEqualToString:@""])
	{
		[s deleteCharactersInRange:NSMakeRange([s length]-1, 1)];
	}
	return s;	
}

@end