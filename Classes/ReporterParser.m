//
//  ReporterParser.m
//  AppSales
//
//  Created by Nicolas Gomollon on 12/13/16.
//
//

#import "ReporterParser.h"

NSString *const kReporterStatusKey   = @"Status";
NSString *const kReporterErrorKey    = @"Error";
NSString *const kReporterCodeKey     = @"Code";
NSString *const kReporterMessageKey  = @"Message";

NSString *const kReporterAccountsKey = @"Accounts";
NSString *const kReporterAccountKey  = @"Account";
NSString *const kReporterNameKey     = @"Name";
NSString *const kReporterNumberKey   = @"Number";

NSString *const kReporterVendorsKey  = @"Vendors";
NSString *const kReporterVendorKey   = @"Vendor";

@implementation ReporterParser

- (instancetype)initWithData:(NSData *)data {
	self = [super init];
	if (self) {
		// Initialization code
		parser = [[NSXMLParser alloc] initWithData:data];
		parser.delegate = self;
		
		tags = [[NSMutableArray alloc] init];
		root = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (BOOL)parse {
	return [parser parse];
}

- (NSDictionary *)root {
	return root;
}

#pragma mark - NSXMLParserDelegate Methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary<NSString *,NSString *> *)attributeDict {
	if (currentNode == nil) {
		currentNode = [[NSMutableDictionary alloc] init];
	}
	currentNodeData = [[NSMutableString alloc] init];
	if ([elementName isEqualToString:kReporterAccountsKey] || [elementName isEqualToString:kReporterVendorsKey]) {
		currentNodeArray = [[NSMutableArray alloc] init];
	}
	[tags addObject:elementName];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	[currentNodeData appendString:string];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
	[tags removeLastObject];
	
	NSMutableDictionary *node = (tags.count == 1) ? root : currentNode;
	
	if (tags.count == 0) {
		currentNode = [NSMutableDictionary dictionaryWithDictionary:root];
		root = [[NSMutableDictionary alloc] init];
	}
	
	if (currentNodeData == nil) {
		if ([elementName isEqualToString:kReporterAccountKey] || [elementName isEqualToString:kReporterVendorKey]) {
			[currentNodeArray addObject:@{elementName: currentNode}];
		} else if ([elementName isEqualToString:kReporterAccountsKey] || [elementName isEqualToString:kReporterVendorsKey]) {
			root[elementName] = currentNodeArray;
		} else {
			root[elementName] = currentNode;
		}
		currentNode = nil;
	} else if ([elementName isEqualToString:kReporterCodeKey]) {
		node[elementName] = @(currentNodeData.integerValue);
	} else {
		node[elementName] = currentNodeData;
	}
	
	currentNodeData = nil;
}

@end
