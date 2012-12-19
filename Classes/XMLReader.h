//
//  XMLReader.h
//  AppSales
//
//  Created by René Bigot on 19/12/12.
//  Author : Jay Mehta
//  Found on StackOverflow.com : http://stackoverflow.com/questions/10845732/xml-parser-objective-c
//
//

#import <Foundation/Foundation.h>


@interface XMLReader : NSObject<NSXMLParserDelegate>
{
    NSMutableArray *dictionaryStack;
    NSMutableString *textInProgress;
    NSError **errorPointer;
}

+ (NSDictionary *)dictionaryForXMLData:(NSData *)data error:(NSError **)errorPointer;
+ (NSDictionary *)dictionaryForXMLString:(NSString *)string error:(NSError **)errorPointer;

@end
