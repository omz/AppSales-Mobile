//
//  ReporterParser.h
//  AppSales
//
//  Created by Nicolas Gomollon on 12/13/16.
//
//

#import <Foundation/Foundation.h>

extern NSString *const kReporterStatusKey;
extern NSString *const kReporterErrorKey;
extern NSString *const kReporterCodeKey;
extern NSString *const kReporterMessageKey;

extern NSString *const kReporterAccountsKey;
extern NSString *const kReporterAccountKey;
extern NSString *const kReporterNameKey;
extern NSString *const kReporterNumberKey;

extern NSString *const kReporterVendorsKey;
extern NSString *const kReporterVendorKey;

@interface ReporterParser : NSObject <NSXMLParserDelegate> {
	NSXMLParser *parser;
	NSMutableArray *tags;
	NSMutableDictionary *root;
	NSMutableDictionary *currentNode;
	NSMutableString *currentNodeData;
	NSMutableArray *currentNodeArray;
}

- (instancetype)initWithData:(NSData *)data;
- (BOOL)parse;
- (NSDictionary *)root;

@end
