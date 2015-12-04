//
//  LoginManager.m
//  AppSales
//
//  Created by Nicolas Gomollon on 12/1/15.
//
//

#import "LoginManager.h"

NSString *const kMemberCenterAuthAppID          = @"891bd3417a7776362562d2197f89480a8547b108fd934911bcbea0110d07f757";
NSString *const kMemberCenterBaseURL            = @"https://idmsa.apple.com/IDMSWebAuth/";
NSString *const kMemberCenterAuthenticateAction = @"authenticate";
NSString *const kMemberCenterValidateCodeAction = @"validateSecurityCode";
NSString *const kMemberCenterLogoutURL          = @"https://developer.apple.com/membercenter/logout.action";

NSString *const kITCBaseURL            = @"https://itunesconnect.apple.com";
NSString *const kITCLoginPageAction    = @"/WebObjects/iTunesConnect.woa";
NSString *const kITCPaymentsPageAction = @"/WebObjects/iTunesConnect.woa/da/jumpTo?page=paymentsAndFinancialReports";

@implementation LoginManager

- (id)init {
	return [self initWithAccount:nil];
}

- (id)initWithAccount:(ASAccount *)_account {
	self = [super init];
	if (self) {
		// Initialization code
		account = _account;
	}
	return self;
}

- (id)initWithLoginInfo:(NSDictionary *)_loginInfo {
	self = [super init];
	if (self) {
		// Initialization code
		loginInfo = _loginInfo;
	}
	return self;
}

- (BOOL)isLoggedIn {
	for (NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]) {
		if ([cookie.domain rangeOfString:@"apple.com"].location != NSNotFound) {
			if ([cookie.name isEqualToString:@"myacinfo"]) {
				return YES;
			}
		}
	}
	return NO;
}

- (void)logOut {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
		NSURL *logoutURL = [NSURL URLWithString:kMemberCenterLogoutURL];
		[NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:logoutURL] returningResponse:nil error:nil];
		
		if (self.shouldDeleteCookies) {
			NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
			
			NSArray *cookies = [cookieStorage cookiesForURL:[NSURL URLWithString:@"https://idmsa.apple.com"]];
			for (NSHTTPCookie *cookie in cookies) {
				[cookieStorage deleteCookie:cookie];
			}
			
			cookies = [cookieStorage cookiesForURL:[NSURL URLWithString:@"https://itunesconnect.apple.com"]];
			for (NSHTTPCookie *cookie in cookies) {
				[cookieStorage deleteCookie:cookie];
			}
			
			cookies = [cookieStorage cookiesForURL:[NSURL URLWithString:@"https://reportingitc.apple.com"]];
			for (NSHTTPCookie *cookie in cookies) {
				[cookieStorage deleteCookie:cookie];
			}
		}
	});
}

- (void)logIn {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
		[self logOut];
		
		if (trustedDevices == nil) {
			trustedDevices = [[NSMutableArray alloc] init];
		} else {
			[trustedDevices removeAllObjects];
		}
		
		NSString *bodyString = [NSString stringWithFormat:@"appleId=%@&accountPassword=%@&appIdKey=%@", NSStringPercentEscaped(account.username ?: loginInfo[@"username"]), NSStringPercentEscaped(account.password ?: loginInfo[@"password"]), kMemberCenterAuthAppID];
		NSData *bodyData = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
		
		NSURL *authenticateURL = [NSURL URLWithString:[kMemberCenterBaseURL stringByAppendingString:kMemberCenterAuthenticateAction]];
		NSMutableURLRequest *authenticateRequest = [NSMutableURLRequest requestWithURL:authenticateURL];
		[authenticateRequest setHTTPMethod:@"POST"];
		[authenticateRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
		[authenticateRequest setHTTPBody:bodyData];
		
		NSHTTPURLResponse *response = nil;
		NSData *authenticatePageData = [NSURLConnection sendSynchronousRequest:authenticateRequest returningResponse:&response error:NULL];
		NSString *authenticatePage = [[NSString alloc] initWithData:authenticatePageData encoding:NSUTF8StringEncoding];
		NSScanner *authenticatePageScanner = [NSScanner scannerWithString:authenticatePage];
		[authenticatePageScanner scanUpToString:@"<form id=\"command\" name=\"deviceForm\"" intoString:NULL];
		[authenticatePageScanner scanString:@"<form id=\"command\" name=\"deviceForm\"" intoString:NULL];
		if (self.isLoggedIn) {
			// We're in!
			if ([self.delegate respondsToSelector:@selector(loginSucceeded)]) {
				dispatch_async(dispatch_get_main_queue(), ^{
					[self.delegate loginSucceeded];
				});
			}
		} else if ([authenticatePageScanner scanString:@"action=\"" intoString:NULL]) {
			// Looks like this account has Two-Step Verification enabled.
			NSString *_generateCodeAction = nil;
			[authenticatePageScanner scanUpToString:@"\"" intoString:&_generateCodeAction];
			generateCodeAction = _generateCodeAction;
			[authenticatePageScanner scanUpToString:@"<div id=\"devices\">" intoString:NULL];
			if ([authenticatePageScanner scanString:@"<div id=\"devices\">" intoString:NULL]) {
				NSRegularExpression *htmlTagsRegex = [NSRegularExpression regularExpressionWithPattern:@"<[^>]*>" options:0 error:nil];
				NSUInteger scanLocation = authenticatePageScanner.scanLocation;
				[authenticatePageScanner scanUpToString:@"<div class=\"formrow radio hsa\">" intoString:NULL];
				while ([authenticatePageScanner scanString:@"<div class=\"formrow radio hsa\">" intoString:NULL]) {
					NSString *name = nil;
					NSString *value = nil;
					
					// Parse device index.
					[authenticatePageScanner scanUpToString:@"value=\"" intoString:NULL];
					[authenticatePageScanner scanString:@"value=\"" intoString:NULL];
					[authenticatePageScanner scanUpToString:@"\"" intoString:&value];
					
					// Parse device name.
					[authenticatePageScanner scanUpToString:@"<label" intoString:NULL];
					[authenticatePageScanner scanString:@">" intoString:NULL];
					[authenticatePageScanner scanUpToString:@"</label>" intoString:&name];
					
					// Clean up device name.
					name = [htmlTagsRegex stringByReplacingMatchesInString:name options:0 range:NSMakeRange(0, name.length) withTemplate:@""];
					name = [name stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@" "];
					name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
					
					NSMutableDictionary *trustedDevice = [[NSMutableDictionary alloc] init];
					trustedDevice[@"name"] = name;
					trustedDevice[@"value"] = value;
					
					[trustedDevices addObject:trustedDevice];
					[authenticatePageScanner scanUpToString:@"<div class=\"formrow radio hsa\">" intoString:NULL];
				}
				
				if (trustedDevices.count > 0) {
					NSString *_ctkn = nil;
					authenticatePageScanner.scanLocation = scanLocation;
					[authenticatePageScanner scanUpToString:@"<input type=\"hidden\" id=\"ctkn\" name=\"ctkn\"" intoString:NULL];
					[authenticatePageScanner scanString:@"<input type=\"hidden\" id=\"ctkn\" name=\"ctkn\"" intoString:NULL];
					[authenticatePageScanner scanUpToString:@"value=\"" intoString:NULL];
					[authenticatePageScanner scanString:@"value=\"" intoString:NULL];
					[authenticatePageScanner scanUpToString:@"\"" intoString:&_ctkn];
					ctkn = _ctkn;
					
					if (ctkn != nil) {
						[self performSelectorOnMainThread:@selector(chooseTrustedDevice) withObject:nil waitUntilDone:NO];
					} else if ([self.delegate respondsToSelector:@selector(loginFailed)]) {
						dispatch_async(dispatch_get_main_queue(), ^{
							[self.delegate loginFailed];
						});
					}
				} else if ([self.delegate respondsToSelector:@selector(loginFailed)]) {
					dispatch_async(dispatch_get_main_queue(), ^{
						[self.delegate loginFailed];
					});
				}
			} else if ([self.delegate respondsToSelector:@selector(loginFailed)]) {
				dispatch_async(dispatch_get_main_queue(), ^{
					[self.delegate loginFailed];
				});
			}
		} else {
			// Wrong credentials?
			if ([self.delegate respondsToSelector:@selector(loginFailed)]) {
				dispatch_async(dispatch_get_main_queue(), ^{
					[self.delegate loginFailed];
				});
			}
		}
	});
}

- (void)generateCode:(NSString *)_deviceIndex {
	deviceIndex = _deviceIndex;
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
		NSString *bodyString = [NSString stringWithFormat:@"deviceIndex=%@&ctkn=%@", _deviceIndex, NSStringPercentEscaped(ctkn)];
		NSData *bodyData = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
		
		NSURL *generateCodeURL = [NSURL URLWithString:[kMemberCenterBaseURL stringByAppendingString:generateCodeAction]];
		NSMutableURLRequest *generateCodeRequest = [NSMutableURLRequest requestWithURL:generateCodeURL];
		[generateCodeRequest setHTTPMethod:@"POST"];
		[generateCodeRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
		[generateCodeRequest setHTTPBody:bodyData];
		
		NSHTTPURLResponse *response = nil;
		NSData *generateCodePageData = [NSURLConnection sendSynchronousRequest:generateCodeRequest returningResponse:&response error:NULL];
		NSString *generateCodePage = [[NSString alloc] initWithData:generateCodePageData encoding:NSUTF8StringEncoding];
		NSScanner *generateCodePageScanner = [NSScanner scannerWithString:generateCodePage];
		
		NSString *_ctkn = nil;
		[generateCodePageScanner scanUpToString:@"<input type=\"hidden\" id=\"ctkn\" name=\"ctkn\"" intoString:NULL];
		[generateCodePageScanner scanString:@"<input type=\"hidden\" id=\"ctkn\" name=\"ctkn\"" intoString:NULL];
		[generateCodePageScanner scanUpToString:@"value=\"" intoString:NULL];
		[generateCodePageScanner scanString:@"value=\"" intoString:NULL];
		[generateCodePageScanner scanUpToString:@"\"" intoString:&_ctkn];
		ctkn = _ctkn;
		
		if (ctkn != nil) {
			dispatch_async(dispatch_get_main_queue(), ^{
				SecurityCodeInputController *securityCodeInput = [[SecurityCodeInputController alloc] init];
				securityCodeInput.delegate = self;
				[securityCodeInput show];
			});
		} else if ([self.delegate respondsToSelector:@selector(loginFailed)]) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[self.delegate loginFailed];
			});
		}
	});
}

- (void)validateCode:(NSString *)securityCode {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
		NSString *bodyString = [NSString stringWithFormat:@"digit1=%c&digit2=%c&digit3=%c&digit4=%c&rememberMeSelected=%@&ctkn=%@", [securityCode characterAtIndex:0], [securityCode characterAtIndex:1], [securityCode characterAtIndex:2], [securityCode characterAtIndex:3], YES ? @"true" : @"false", NSStringPercentEscaped(ctkn)];
		NSData *bodyData = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
		
		NSURL *validateCodeURL = [NSURL URLWithString:[kMemberCenterBaseURL stringByAppendingString:kMemberCenterValidateCodeAction]];
		NSMutableURLRequest *validateCodeRequest = [NSMutableURLRequest requestWithURL:validateCodeURL];
		[validateCodeRequest setHTTPMethod:@"POST"];
		[validateCodeRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
		[validateCodeRequest setHTTPBody:bodyData];
		
		NSHTTPURLResponse *response = nil;
		NSData *validateCodePageData = [NSURLConnection sendSynchronousRequest:validateCodeRequest returningResponse:&response error:NULL];
		NSString *validateCodePage = [[NSString alloc] initWithData:validateCodePageData encoding:NSUTF8StringEncoding];
		NSScanner *validateCodePageScanner = [NSScanner scannerWithString:validateCodePage];
		
		ctkn = nil;
		if (self.isLoggedIn) {
			// We're in!
			if ([self.delegate respondsToSelector:@selector(loginSucceeded)]) {
				dispatch_async(dispatch_get_main_queue(), ^{
					[self.delegate loginSucceeded];
				});
			}
		} else {
			// Incorrect verification code. Retry?
			NSString *_ctkn = nil;
			[validateCodePageScanner scanUpToString:@"<input type=\"hidden\" id=\"ctkn\" name=\"ctkn\"" intoString:NULL];
			[validateCodePageScanner scanString:@"<input type=\"hidden\" id=\"ctkn\" name=\"ctkn\"" intoString:NULL];
			[validateCodePageScanner scanUpToString:@"value=\"" intoString:NULL];
			[validateCodePageScanner scanString:@"value=\"" intoString:NULL];
			[validateCodePageScanner scanUpToString:@"\"" intoString:&_ctkn];
			ctkn = _ctkn;
			
			if (ctkn != nil) {
				[self generateCode:deviceIndex];
			} else if ([self.delegate respondsToSelector:@selector(loginFailed)]) {
				dispatch_async(dispatch_get_main_queue(), ^{
					[self.delegate loginFailed];
				});
			}
		}
	});
}

- (void)chooseTrustedDevice {
	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Verify Your Identity", nil)
																			 message:NSLocalizedString(@"Your Apple ID is protected with two-step verification.\nChoose a trusted device to receive a verification code.", nil)
																	  preferredStyle:UIAlertControllerStyleActionSheet];
	
	for (NSDictionary *trustedDevice in trustedDevices) {
		NSString *deviceName = trustedDevice[@"name"];
		NSString *deviceValue = trustedDevice[@"value"];
		[alertController addAction:[UIAlertAction actionWithTitle:deviceName style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
			[self generateCode:deviceValue];
		}]];
	}
	
	[alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
		if ([self.delegate respondsToSelector:@selector(loginFailed)]) {
			// User canceled the verification, so we're unable to log in.
			[self.delegate loginFailed];
		}
	}]];
	
	UIViewController *viewController = [UIApplication sharedApplication].keyWindow.rootViewController;
	while (viewController.presentedViewController != nil) {
		viewController = viewController.presentedViewController;
	}
	[viewController presentViewController:alertController animated:YES completion:nil];
}

- (void)securityCodeInputSubmitted:(NSString *)securityCode {
	[self validateCode:securityCode];
}

- (void)securityCodeInputCanceled {
	// User canceled the verification, so we're unable to log in.
	if ([self.delegate respondsToSelector:@selector(loginFailed)]) {
		[self.delegate loginFailed];
	}
}

@end
