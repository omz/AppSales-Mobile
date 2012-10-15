//
//  PromoCodeOperation.m
//  AppSales
//
//  Created by Ole Zorn on 14.08.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "PromoCodeOperation.h"
#import "DownloadStepOperation.h"
#import "Product.h"
#import "ASAccount.h"
#import "PromoCode.h"
#import "NSDictionary+HTTP.h"
#import "RegexKitLite.h"

@interface PromoCodeOperation ()
+ (NSString *)scanNameForFormField:(NSString *)field withScanner:(NSScanner *)scanner;
+ (NSURLRequest *)postRequestWithURL:(NSURL *)URL body:(NSDictionary *)bodyDict;
+ (void)errorNotification:(NSString *)errorDescription;
@end

@implementation PromoCodeOperation

- (id)initWithProduct:(Product *)aProduct
{
	return [self initWithProduct:aProduct numberOfCodes:0];
}

- (id)initWithProduct:(Product *)aProduct numberOfCodes:(NSInteger)numberOfCodes
{
	self = [super init];
	
	NSSet *existingCodes = [aProduct.promoCodes valueForKey:@"code"];
	__block NSInteger numberOfCodesToRequest = numberOfCodes;
	
	NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	NSArray *cookies = [cookieStorage cookiesForURL:[NSURL URLWithString:@"https://itunesconnect.apple.com"]];
	for (NSHTTPCookie *cookie in cookies) {
		[cookieStorage deleteCookie:cookie];
	}
	NSString *username = aProduct.account.username;
	NSString *password = aProduct.account.password;
	NSString *productID = aProduct.productID;
	NSString *ittsBaseURL = @"https://itunesconnect.apple.com";
	
	
	DownloadStepOperation *step1 = [DownloadStepOperation operationWithInput:nil];
	NSURL *loginURL = [NSURL URLWithString:[ittsBaseURL stringByAppendingString:@"/WebObjects/iTunesConnect.woa"]];
	step1.request = [NSURLRequest requestWithURL:loginURL];
	
	DownloadStepOperation *step2 = [DownloadStepOperation operationWithInput:step1];
	step2.startBlock = ^(DownloadStepOperation *operation) {
		NSData *loginPageData = operation.inputOperation.data;
		NSString *loginPage = [[[NSString alloc] initWithData:loginPageData encoding:NSUTF8StringEncoding] autorelease];
		if (loginPage) {
			NSScanner *loginPageScanner = [NSScanner scannerWithString:loginPage];
			[loginPageScanner scanUpToString:@"action=\"" intoString:nil];
			if (![loginPageScanner scanString:@"action=\"" intoString:nil]) {
				[PromoCodeOperation errorNotification:@"could not log in"];
				[operation cancel];
				return;
			}
			NSString *loginAction = nil;
			[loginPageScanner scanUpToString:@"\"" intoString:&loginAction];
			
			NSDictionary *postDict = [NSDictionary dictionaryWithObjectsAndKeys:
									  username, @"theAccountName",
									  password, @"theAccountPW", 
									  @"39", @"1.Continue.x", // coordinates of submit button on screen.  any values seem to work
									  @"7", @"1.Continue.y",
									  nil];
			operation.request = [PromoCodeOperation postRequestWithURL:[NSURL URLWithString:[ittsBaseURL stringByAppendingString:loginAction]] body:postDict];
		} else {
			[PromoCodeOperation errorNotification:@"could not log in"];
			[operation cancel];
		}
	};
	
	
	DownloadStepOperation *step3 = [DownloadStepOperation operationWithInput:step2];
	step3.startBlock = ^(DownloadStepOperation *operation) {
		NSData *loginPageData = operation.inputOperation.data;
		NSString *loginPage = [[[NSString alloc] initWithData:loginPageData encoding:NSUTF8StringEncoding] autorelease];
		if (loginPage) {
			NSScanner *manageAppsScanner = [NSScanner scannerWithString:loginPage];
			NSString *paymentsAction = nil;
			[manageAppsScanner scanUpToString:@"alt=\"Manage Your Applications" intoString:NULL];
			[manageAppsScanner scanUpToString:@"<a href=\"" intoString:NULL];
			[manageAppsScanner scanString:@"<a href=\"" intoString:NULL];
			[manageAppsScanner scanUpToString:@"\"" intoString:&paymentsAction];
			if (paymentsAction) {
				NSString *manageAppsURLString = [NSString stringWithFormat:@"https://itunesconnect.apple.com%@", paymentsAction];
				operation.request = [NSURLRequest requestWithURL:[NSURL URLWithString:manageAppsURLString]];
			} else {
				[PromoCodeOperation errorNotification:@"could not find 'Manage Your Applications' link"];
				[operation cancel];
			}
		} else {
			[PromoCodeOperation errorNotification:@"could not load iTunes Connect"];
			[operation cancel];
		}
	};
	
	
	DownloadStepOperation *step4 = [DownloadStepOperation operationWithInput:step3];
	step4.startBlock = ^(DownloadStepOperation *operation) {
		NSData *manageAppsPageData = operation.inputOperation.data;
		NSString *manageAppsPage = [[[NSString alloc] initWithData:manageAppsPageData encoding:NSUTF8StringEncoding] autorelease];
		if (manageAppsPage) {
			NSScanner *searchFormScanner = [NSScanner scannerWithString:manageAppsPage];
			NSString *searchFormAction = nil;			
			if ([searchFormScanner scanUpToString:@"<div id=\"titleSearch" intoString:NULL] && [searchFormScanner scanUpToString:@"action=\"" intoString:NULL] && [searchFormScanner scanString:@"action=\"" intoString:NULL] && [searchFormScanner scanUpToString:@"\"" intoString:&searchFormAction]) {
				NSString *nameCompareFieldName = [PromoCodeOperation scanNameForFormField:@"search-param-compare-name" withScanner:searchFormScanner];
				NSString *nameValueFieldName = [PromoCodeOperation scanNameForFormField:@"search-param-value-name" withScanner:searchFormScanner];
				NSString *appleIDFieldName = [PromoCodeOperation scanNameForFormField:@"search-param-value-appleId" withScanner:searchFormScanner];
				NSString *statusFieldName = [PromoCodeOperation scanNameForFormField:@"search-param-value-statusSearch" withScanner:searchFormScanner];
				NSString *appTypeFieldName = [PromoCodeOperation scanNameForFormField:@"search-param-value-" withScanner:searchFormScanner];
				if (nameCompareFieldName && nameValueFieldName && appleIDFieldName && statusFieldName) {
					NSDictionary *bodyDict;
					if (appTypeFieldName) {
						bodyDict = [NSDictionary dictionaryWithObjectsAndKeys:
									@"0", nameCompareFieldName,
									@"", nameValueFieldName,
									productID, appleIDFieldName, 
									@"WONoSelectionString", statusFieldName,
									@"WONoSelectionString", appTypeFieldName,
									nil];
					} else {
						bodyDict = [NSDictionary dictionaryWithObjectsAndKeys:
									@"0", nameCompareFieldName,
									@"", nameValueFieldName,
									productID, appleIDFieldName, 
									@"WONoSelectionString", statusFieldName,
									nil];
					}
					operation.request = [PromoCodeOperation postRequestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://itunesconnect.apple.com%@", searchFormAction]] body:bodyDict];
				} else {
					[PromoCodeOperation errorNotification:@"could not parse 'Manage Your Applications' page"];
					[operation cancel];
				}
			}
		} else {
			[PromoCodeOperation errorNotification:@"could not parse 'Manage Your Applications' page"];
			[operation cancel];
		}
	};
	
	
	DownloadStepOperation *step5 = [DownloadStepOperation operationWithInput:step4];
	step5.startBlock = ^(DownloadStepOperation *operation) {
		NSData *searchResultPageData = operation.inputOperation.data;
		
		NSString *searchResultPage = [[[NSString alloc] initWithData:searchResultPageData encoding:NSUTF8StringEncoding] autorelease];
		if (searchResultPage) {
			NSScanner *searchResultScanner = [NSScanner scannerWithString:searchResultPage];
			if ([searchResultScanner scanUpToString:@"<div class=\"software-column-type-col-0\">" intoString:NULL]) {
				[searchResultScanner scanUpToString:@"<a href=\"" intoString:NULL];
				[searchResultScanner scanString:@"<a href=\"" intoString:NULL];
				NSString *appPageURLPath = nil;
				[searchResultScanner scanUpToString:@"\"" intoString:&appPageURLPath];
				NSString *appPageURLString = [NSString stringWithFormat:@"https://itunesconnect.apple.com%@", appPageURLPath];
				operation.request = [NSURLRequest requestWithURL:[NSURL URLWithString:appPageURLString]];
			} else {
				[PromoCodeOperation errorNotification:@"could not parse app search results page"];
				[operation cancel];
			}
		} else {
			[PromoCodeOperation errorNotification:@"could not parse app search results page"];
			[operation cancel];
		}
	};
	
	
	DownloadStepOperation *step6 = [DownloadStepOperation operationWithInput:step5];
	step6.startBlock = ^(DownloadStepOperation *operation) {
		NSData *appPageData = operation.inputOperation.data;
		NSString *appPage = [[[NSString alloc] initWithData:appPageData encoding:NSUTF8StringEncoding] autorelease];
		NSScanner *currentVersionScanner = [NSScanner scannerWithString:appPage];
		if (![currentVersionScanner scanUpToString:@"<div class=\"version-container\">" intoString:NULL] || ![currentVersionScanner scanUpToString:@"<a href=\"" intoString:NULL]) {
			[PromoCodeOperation errorNotification:@"could not parse app page"];
			[operation cancel];
		}
		[currentVersionScanner scanString:@"<a href=\"" intoString:NULL];
		NSString *currentVersionURLPath = nil;
		[currentVersionScanner scanUpToString:@"\"" intoString:&currentVersionURLPath];
		NSString *currentVersionURLString = [NSString stringWithFormat:@"https://itunesconnect.apple.com%@", currentVersionURLPath];
		operation.request = [NSURLRequest requestWithURL:[NSURL URLWithString:currentVersionURLString]];
	};
	
	
	DownloadStepOperation *step7 = [DownloadStepOperation operationWithInput:step6];
	step7.startBlock = ^(DownloadStepOperation *operation) {
		NSData *currentVersionPageData = operation.inputOperation.data;
		NSString *currentVersionPage = [[[NSString alloc] initWithData:currentVersionPageData encoding:NSUTF8StringEncoding] autorelease];
		NSString *promoCodesURLPath = [currentVersionPage stringByMatching:@"<a href=\"(.*?)\"><span class=\"promo-codes" capture:1];
		if (!promoCodesURLPath) {
			[PromoCodeOperation errorNotification:@"could not find promo codes link, perhaps the app was removed from sale?"];
			[operation cancel];
		}
		NSString *promoCodesURLString = [NSString stringWithFormat:@"https://itunesconnect.apple.com%@", promoCodesURLPath];
		operation.request = [NSURLRequest requestWithURL:[NSURL URLWithString:promoCodesURLString]];
	};
	
	
	DownloadStepOperation *step8 = [DownloadStepOperation operationWithInput:step7];
	step8.startBlock = ^(DownloadStepOperation *operation) {
		NSData *promoCodesPageData = operation.inputOperation.data;
		NSString *promoCodesPage = [[[NSString alloc] initWithData:promoCodesPageData encoding:NSUTF8StringEncoding] autorelease];
		
		NSScanner *codesRemainingScanner = [NSScanner scannerWithString:promoCodesPage];
		if (![codesRemainingScanner scanUpToString:@"<div class=\"codeString\"" intoString:NULL]) {
			[PromoCodeOperation errorNotification:@"could not parse promo code request page"];
			[operation cancel];
		}
		[codesRemainingScanner scanUpToString:@">" intoString:NULL];
		[codesRemainingScanner scanString:@">" intoString:NULL];
		NSInteger codesRemaining = -1;
		[codesRemainingScanner scanInteger:&codesRemaining];
		if (codesRemaining < 0) {
			[PromoCodeOperation errorNotification:@"could not parse promo code request page"];
			[operation cancel];
		}
		//NSLog(@"%i codes available", codesRemaining);
		if (codesRemaining < numberOfCodesToRequest) {
			//NSLog(@"More codes requested than available, requesting all codes that are left");
			numberOfCodesToRequest = codesRemaining;
		}
		NSScanner *viewHistoryScanner = [NSScanner scannerWithString:promoCodesPage];
		[viewHistoryScanner scanUpToString:@"<form name=\"mainForm\"" intoString:NULL];
		if (![viewHistoryScanner scanUpToString:@"action=\"" intoString:NULL]) {
			[PromoCodeOperation errorNotification:@"could not parse promo code request page"];
			[operation cancel];
		}
		[viewHistoryScanner scanString:@"action=\"" intoString:NULL];
		NSString *viewHistoryFormAction = nil;
		[viewHistoryScanner scanUpToString:@"\"" intoString:&viewHistoryFormAction];
		
		if (![viewHistoryScanner scanUpToString:@"class=\"customActionButton\"" intoString:NULL] || ![viewHistoryScanner scanUpToString:@"name=\"" intoString:NULL]) {
			[PromoCodeOperation errorNotification:@"could not parse promo code request page"];
			[operation cancel];
		}
		
		[viewHistoryScanner scanString:@"name=\"" intoString:NULL];
		NSString *viewHistoryButtonName = nil;
		[viewHistoryScanner scanUpToString:@"\"" intoString:&viewHistoryButtonName];
		
		if (![viewHistoryScanner scanUpToString:@"<td class=\"metadata-field-code" intoString:NULL] || ![viewHistoryScanner scanUpToString:@"name=\"" intoString:NULL]) {
			[PromoCodeOperation errorNotification:@"could not parse promo code request page"];
			[operation cancel];
		}
		
		[viewHistoryScanner scanString:@"name=\"" intoString:NULL];
		NSString *numberOfCodesFieldName = nil;
		[viewHistoryScanner scanUpToString:@"\"" intoString:&numberOfCodesFieldName];
		
		if (![viewHistoryScanner scanUpToString:@"class=\"continueActionButton\"" intoString:NULL]) {
			[PromoCodeOperation errorNotification:@"could not parse promo code request page"];
			[operation cancel];
		}
		[viewHistoryScanner scanString:@"class=\"continueActionButton\"" intoString:NULL];
		[viewHistoryScanner scanUpToString:@"name=\"" intoString:NULL];
		[viewHistoryScanner scanString:@"name=\"" intoString:NULL];
		NSString *continueButtonName = nil;
		[viewHistoryScanner scanUpToString:@"\"" intoString:&continueButtonName];
		if (!continueButtonName) {
			[PromoCodeOperation errorNotification:@"could not parse promo code request page"];
			[operation cancel];
		}
		
		if (numberOfCodes == 0) {
			NSString *viewHistoryURLString = [NSString stringWithFormat:@"https://itunesconnect.apple.com%@", viewHistoryFormAction];
			NSDictionary *bodyDict = [NSDictionary dictionaryWithObjectsAndKeys:
									  @"58", [NSString stringWithFormat:@"%@.x", viewHistoryButtonName], 
									  @"14", [NSString stringWithFormat:@"%@.y", viewHistoryButtonName], 
									  @"", numberOfCodesFieldName,
									  nil];
			operation.request = [PromoCodeOperation postRequestWithURL:[NSURL URLWithString:viewHistoryURLString] body:bodyDict];
		} else {
			NSString *requestCodesURLString = [NSString stringWithFormat:@"https://itunesconnect.apple.com%@", viewHistoryFormAction];
			NSDictionary *bodyDict = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSString stringWithFormat:@"%i", numberOfCodesToRequest], numberOfCodesFieldName,
									  @"58", [NSString stringWithFormat:@"%@.x", continueButtonName],
									  @"14", [NSString stringWithFormat:@"%@.y", continueButtonName],
									  nil];
			operation.request = [PromoCodeOperation postRequestWithURL:[NSURL URLWithString:requestCodesURLString] body:bodyDict];
		}
	};
	
	if (numberOfCodes == 0) {
		DownloadStepOperation *step9 = [DownloadStepOperation operationWithInput:step8];
		step9.startBlock = ^(DownloadStepOperation *operation) {
			NSString *historyPage = [[[NSString alloc] initWithData:operation.inputOperation.data encoding:NSUTF8StringEncoding] autorelease];
			
			NSArray *downloadPaths = [historyPage componentsMatchedByRegex:@"<a href=\"(.*?)\".*?download-codes" capture:1];
			NSArray *dateStrings = [historyPage componentsMatchedByRegex:@"<td>((Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)(.*?))</td>" capture:1];
			
			NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
			[dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
			[dateFormatter setDateFormat:@"MMM dd,yyyy HH:mm:ss"];
			[dateFormatter setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"en-us"] autorelease]];
			
			if ([dateStrings count] >= [downloadPaths count]) {
				int i = 0;
				NSDate *date = nil;
				for (NSString *downloadPath in downloadPaths) {
					NSString *dateString = [dateStrings objectAtIndex:i];
					date = [dateFormatter dateFromString:dateString];
					
					NSString *downloadURLString = [NSString stringWithFormat:@"https://itunesconnect.apple.com%@", downloadPath];
									
					DownloadStepOperation *codeDownloadStep = [DownloadStepOperation operationWithInput:nil];
					codeDownloadStep.request = [NSURLRequest requestWithURL:[NSURL URLWithString:downloadURLString]];
					codeDownloadStep.completionBlock = ^ {
						dispatch_async(dispatch_get_main_queue(), ^ {
							NSString *promoCodeFile = [[[NSString alloc] initWithData:codeDownloadStep.data encoding:NSUTF8StringEncoding] autorelease];
							NSArray *promoCodes = [promoCodeFile componentsSeparatedByString:@"\n"];
                            if ([promoCodes count] > 51) {
                                [PromoCodeOperation errorNotification:@"parsing the downloaded promo codes failed"];
                                [operation cancel];
                                return;
                            }
							for (NSString *promoCode in promoCodes) {
                                promoCode = [promoCode stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
								if ([promoCode length] == 12 && ![existingCodes containsObject:promoCode]) {
									PromoCode *newPromoCode = [NSEntityDescription insertNewObjectForEntityForName:@"PromoCode" inManagedObjectContext:aProduct.managedObjectContext];
									newPromoCode.code = promoCode;
									newPromoCode.requestDate = date;
									[[aProduct mutableSetValueForKey:@"promoCodes"] addObject:newPromoCode];
								}
                                if ([promoCode length] > 0 && [promoCode length] != 12) {
                                    [PromoCodeOperation errorNotification:@"parsing the downloaded promo codes failed"];
                                    [operation cancel];
                                    return;
                                }
							}
						});
					};
					[self.queue addOperation:codeDownloadStep];
					i++;
				}
			}
		};
		[super initWithOperations:[NSArray arrayWithObjects:step1, step2, step3, step4, step5, step6, step7, step8, step9, nil]];
	} else {
		DownloadStepOperation *step9 = [DownloadStepOperation operationWithInput:step8];
		step9.startBlock = ^(DownloadStepOperation *operation) {
			NSData *licenseAgreementPageData = operation.inputOperation.data;
			NSString *licenseAgreementPage = [[[NSString alloc] initWithData:licenseAgreementPageData encoding:NSUTF8StringEncoding] autorelease];
			NSScanner *licenseAgreementScanner = [NSScanner scannerWithString:licenseAgreementPage];
			if ([licenseAgreementScanner scanUpToString:@"<html>" intoString:NULL]) {
				NSString *licenseAgreementHTML = nil;
				[licenseAgreementScanner scanString:@"<html>" intoString:NULL];
				if ([licenseAgreementScanner scanUpToString:@"</html>" intoString:&licenseAgreementHTML]) {
					licenseAgreementHTML = [licenseAgreementHTML stringByAppendingString:@"</html>"];
				}
				if (!licenseAgreementHTML) {
					[licenseAgreementScanner setScanLocation:0];
					if ([licenseAgreementScanner scanUpToString:@"<h3 style=\"text-align:center;\">MAC APP STORE VOLUME CUSTOM CODE AGREEMENT</h3>" intoString:NULL]) {
						[licenseAgreementScanner scanUpToString:@"<td colspan=\"2\" class=\"check-agreement\"" intoString:&licenseAgreementHTML];
					}
				}
				if (licenseAgreementHTML) {
					[licenseAgreementScanner setScanLocation:0];
					if (![licenseAgreementScanner scanUpToString:@" <form name=\"mainForm\"" intoString:NULL] || ![licenseAgreementScanner scanUpToString:@"action=\"" intoString:NULL]) {
						[PromoCodeOperation errorNotification:@"could not parse license agreement page"];
						[operation cancel];
					}
					NSString *licenseAgreementFormAction = nil;
					[licenseAgreementScanner scanString:@"action=\"" intoString:NULL];
					[licenseAgreementScanner scanUpToString:@"\"" intoString:&licenseAgreementFormAction];
					
					if (![licenseAgreementScanner scanUpToString:@"<input type=\"checkbox\"" intoString:NULL] || ![licenseAgreementScanner scanUpToString:@"name=\"" intoString:NULL]) {
						[PromoCodeOperation errorNotification:@"could not parse license agreement page"];
						[operation cancel];
					}
					
					NSString *licenseAgreementCheckboxName = nil;
					[licenseAgreementScanner scanString:@"name=\"" intoString:NULL];
					[licenseAgreementScanner scanUpToString:@"\"" intoString:&licenseAgreementCheckboxName];
					
					if (![licenseAgreementScanner scanUpToString:@"class=\"continueActionButton\"" intoString:NULL] || ![licenseAgreementScanner scanUpToString:@"name=\"" intoString:NULL]) {
						[PromoCodeOperation errorNotification:@"could not parse license agreement page"];
						[operation cancel];
					}
					NSString *licenseAgreementContinueButtonName = nil;
					[licenseAgreementScanner scanString:@"name=\"" intoString:NULL];
					[licenseAgreementScanner scanUpToString:@"\"" intoString:&licenseAgreementContinueButtonName];
					
					NSDictionary *postDict = [NSDictionary dictionaryWithObjectsAndKeys:
											  licenseAgreementCheckboxName, licenseAgreementCheckboxName,
											  @"58", [NSString stringWithFormat:@"%@.x", licenseAgreementContinueButtonName],
											  @"14", [NSString stringWithFormat:@"%@.y", licenseAgreementContinueButtonName],
											  nil];
					NSString *continueURLString = [@"https://itunesconnect.apple.com" stringByAppendingString:licenseAgreementFormAction];
					operation.request = [PromoCodeOperation postRequestWithURL:[NSURL URLWithString:continueURLString] body:postDict];
					
					operation.paused = YES;
					[[NSNotificationCenter defaultCenter] postNotificationName:@"PromoCodeOperationLoadedLicenseAgreementNotification" object:operation userInfo:[NSDictionary dictionaryWithObject:licenseAgreementHTML forKey:@"licenseAgreement"]];
				} else {
					[PromoCodeOperation errorNotification:@"could not parse license agreement page"];
					[operation cancel];
				}
			} else {
				[PromoCodeOperation errorNotification:@"could not parse license agreement page"];
				[operation cancel];
			}
		};
		
		DownloadStepOperation *step10 = [DownloadStepOperation operationWithInput:step9];
		step10.startBlock = ^(DownloadStepOperation *operation) {
			NSData *codeDownloadPageData = operation.inputOperation.data;
			NSString *codeDownloadPage = [[[NSString alloc] initWithData:codeDownloadPageData encoding:NSUTF8StringEncoding] autorelease];
			
			NSString *downloadLinkURLPath = [codeDownloadPage stringByMatching:@"<a href=\"(.*?)\".*?download-codes" capture:1];
			NSString *downloadLinkURLString = [NSString stringWithFormat:@"https://itunesconnect.apple.com%@", downloadLinkURLPath];
			
			if (!downloadLinkURLString) {
				[PromoCodeOperation errorNotification:@"could not find promo codes download link"];
				[operation cancel];
			}
			operation.request = [NSURLRequest requestWithURL:[NSURL URLWithString:downloadLinkURLString]];
		};
		
		DownloadStepOperation *step11 = [DownloadStepOperation operationWithInput:step10];
		step11.startBlock = ^(DownloadStepOperation *operation) {
			NSData *promoCodeData = operation.inputOperation.data;
			NSString *promoCodesFile = [[[NSString alloc] initWithData:promoCodeData encoding:NSUTF8StringEncoding] autorelease];
			NSArray *promoCodes = [promoCodesFile componentsSeparatedByString:@"\n"];
			for (NSString *promoCode in promoCodes) {
				if ([promoCode length] > 0 && ![existingCodes containsObject:promoCode]) {
					PromoCode *newPromoCode = [NSEntityDescription insertNewObjectForEntityForName:@"PromoCode" inManagedObjectContext:aProduct.managedObjectContext];
					newPromoCode.code = promoCode;
					newPromoCode.requestDate = [NSDate date];
					[[aProduct mutableSetValueForKey:@"promoCodes"] addObject:newPromoCode];
				}
			}
		};
		
		[super initWithOperations:[NSArray arrayWithObjects:step1, step2, step3, step4, step5, step6, step7, step8, step9, step10, step11, nil]];
	}
	
    return self;
}

+ (NSString *)scanNameForFormField:(NSString *)field withScanner:(NSScanner *)scanner
{
	[scanner scanUpToString:[NSString stringWithFormat:@"class='%@'", field] intoString:NULL];
	[scanner scanUpToString:@"name=\"" intoString:NULL];
	if ([scanner scanString:@"name=\"" intoString:NULL]) {
		NSString *fieldName = nil;
		[scanner scanUpToString:@"\"" intoString:&fieldName];
		return fieldName;
	}
	return nil;
}

+ (NSURLRequest *)postRequestWithURL:(NSURL *)URL body:(NSDictionary *)bodyDict
{
	NSString *postDictString = [bodyDict formatForHTTP];
	NSData *httpBody = [postDictString dataUsingEncoding:NSASCIIStringEncoding];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:httpBody];
	return request;
}

+ (void)errorNotification:(NSString *)errorDescription
{
	dispatch_async(dispatch_get_main_queue(), ^ {
		[[NSNotificationCenter defaultCenter] postNotificationName:ASPromoCodeDownloadFailedNotification object:nil userInfo:[NSDictionary dictionaryWithObject:errorDescription forKey:kASPromoCodeDownloadFailedErrorDescription]];
	});
}

- (void)dealloc
{
	[super dealloc];
}

@end
