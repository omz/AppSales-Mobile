//
//  LoginManager.m
//  AppSales
//
//  Created by Nicolas Gomollon on 12/1/15.
//
//

#import "LoginManager.h"
#import "AccountsViewController.h"

// Apple Auth API
NSString *const kAppleAuthBaseURL      = @"https://idmsa.apple.com/appleauth/auth";
NSString *const kAppleAuthSignInAction = @"/signin";
NSString *const kAppleAuthDeviceAction = @"/verify/device/%@/securitycode";
NSString *const kAppleAuthCodeAction   = @"/verify/trusteddevice/securitycode";
NSString *const kAppleAuthTrustAction  = @"/2sv/trust";

// Apple Auth API Headers
NSString *const kAppleAuthWidgetKey        = @"X-Apple-Widget-Key";
NSString *const kAppleAuthWidgetValue      = @"e0b80c3bf78523bfe80974d320935bfa30add02e1bff88ec2166c6bd5a706c42";
NSString *const kAppleAuthSessionIdKey     = @"X-Apple-ID-Session-Id";
NSString *const kAppleAuthScntKey          = @"scnt";
NSString *const kAppleAuthAcceptKey        = @"Accept";
NSString *const kAppleAuthAcceptValue      = @"application/json, text/javascript, */*; q=0.01";
NSString *const kAppleAuthContentTypeKey   = @"Content-Type";
NSString *const kAppleAuthContentTypeValue = @"application/json;charset=UTF-8";
NSString *const kAppleAuthLocationKey      = @"Location";
NSString *const kAppleAuthSetCookieKey     = @"Set-Cookie";

// iTunes Connect Auth API
NSString *const kITCAuthBaseURL       = @"https://appstoreconnect.apple.com";
NSString *const kITCAuthSessionAction = @"/olympus/v1/session";

// iTunes Connect Reporter API
NSString *const kITCRBaseURL                 = @"https://reportingitc2.apple.com";
NSString *const kITCRGenerateCSRFTokenAction = @"/gsf/owasp/csrf-guard.js";
NSString *const kITCRGetAccessKeyAction      = @"/gsf/salesTrendsApp/businessareas/InternetServices/subjectareas/iTunes/proxy/getAccessKey";
NSString *const kITCRResetAccessKeyAction    = @"/gsf/salesTrendsApp/businessareas/InternetServices/subjectareas/iTunes/proxy/resetAccessKey";

// iTunes Connect Reporter API Headers
NSString *const kITCRXRequestedWithKey   = @"X-Requested-With";
NSString *const kITCRXRequestedWithValue = @"XMLHttpRequest";
NSString *const kITCRFetchCSRFTokenKey   = @"FETCH-CSRF-TOKEN";
NSString *const kITCRFetchCSRFTokenValue = @"1";
NSString *const kITCRCSRFKey             = @"CSRF";

// iTunes Connect Payments API
NSString *const kITCBaseURL                     = @"https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa";
NSString *const kITCPaymentVendorsAction        = @"/ra/paymentConsolidation/providers/%@/sapVendorNumbers";
NSString *const kITCPaymentVendorsPaymentAction = @"/ra/paymentConsolidation/providers/%@/sapVendorNumbers/%@?year=%ld&month=%ld";

@implementation LoginManager

- (instancetype)init {
	return [self initWithAccount:nil];
}

- (instancetype)initWithAccount:(ASAccount *)_account {
	self = [super init];
	if (self) {
		// Initialization code
		account = _account;
		authType = SCInputTypeUnknown;
		dateFormatter = [[NSDateFormatter alloc] init];
		dateFormatter.dateFormat = @"MMM dd, yyyy";
	}
	return self;
}

- (instancetype)initWithLoginInfo:(NSDictionary *)_loginInfo {
	self = [super init];
	if (self) {
		// Initialization code
		loginInfo = _loginInfo;
		authType = SCInputTypeUnknown;
		dateFormatter = [[NSDateFormatter alloc] init];
		dateFormatter.dateFormat = @"MMM dd, yyyy";
	}
	return self;
}

- (NSString *)providerID {
	return account.providerID ?: providerID;
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
	NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	
	NSArray *cookies = [cookieStorage cookiesForURL:[NSURL URLWithString:@"https://itunesconnect.apple.com"]];
	for (NSHTTPCookie *cookie in cookies) {
		[cookieStorage deleteCookie:cookie];
	}
	
	cookies = [cookieStorage cookiesForURL:[NSURL URLWithString:@"https://reportingitc.apple.com"]];
	for (NSHTTPCookie *cookie in cookies) {
		[cookieStorage deleteCookie:cookie];
	}
	
	cookies = [cookieStorage cookiesForURL:[NSURL URLWithString:@"https://reportingitc2.apple.com"]];
	for (NSHTTPCookie *cookie in cookies) {
		[cookieStorage deleteCookie:cookie];
	}
	
	cookies = [cookieStorage cookiesForURL:[NSURL URLWithString:@"https://reportingitc-reporter.apple.com"]];
	for (NSHTTPCookie *cookie in cookies) {
		[cookieStorage deleteCookie:cookie];
	}
	
	if (self.shouldDeleteCookies) {
		cookies = [cookieStorage cookiesForURL:[NSURL URLWithString:@"https://idmsa.apple.com"]];
		for (NSHTTPCookie *cookie in cookies) {
			[cookieStorage deleteCookie:cookie];
		}
	}
}

- (void)logIn {
	[self logOut];
	
	authType = SCInputTypeUnknown;
	appleAuthTrustedDeviceId = nil;
	if (trustedDevices == nil) {
		trustedDevices = [[NSMutableArray alloc] init];
	} else {
		[trustedDevices removeAllObjects];
	}
	
	NSDictionary *bodyDict = @{@"accountName": account.username ?: loginInfo[kAccountUsername],
							   @"password": account.password ?: loginInfo[kAccountPassword],
							   @"rememberMe": @(YES)};
	NSData *bodyData = [NSJSONSerialization dataWithJSONObject:bodyDict options:0 error:nil];
	
	NSURL *signInURL = [NSURL URLWithString:[kAppleAuthBaseURL stringByAppendingString:kAppleAuthSignInAction]];
	NSMutableURLRequest *signInRequest = [NSMutableURLRequest requestWithURL:signInURL];
	[signInRequest setHTTPMethod:@"POST"];
	[signInRequest setValue:kAppleAuthWidgetValue forHTTPHeaderField:kAppleAuthWidgetKey];
	[signInRequest setValue:kAppleAuthAcceptValue forHTTPHeaderField:kAppleAuthAcceptKey];
	[signInRequest setValue:kAppleAuthContentTypeValue forHTTPHeaderField:kAppleAuthContentTypeKey];
	[signInRequest setHTTPBody:bodyData];
	
	NSHTTPURLResponse *signInResponse = nil;
	[NSURLConnection sendSynchronousRequest:signInRequest returningResponse:&signInResponse error:nil];
	NSString *location = signInResponse.allHeaderFields[kAppleAuthLocationKey];
	appleAuthSessionId = signInResponse.allHeaderFields[kAppleAuthSessionIdKey];
	appleAuthScnt = signInResponse.allHeaderFields[kAppleAuthScntKey];
	
	if ((appleAuthSessionId.length == 0) || (appleAuthScnt.length == 0)) {
		// Wrong credentials?
		if ([self.delegate respondsToSelector:@selector(loginFailed:)]) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[self.delegate loginFailed:self];
			});
		}
	} else if (location.length == 0) {
		// We're in!
		[self fetchRemainingCookies];
	} else {
		// This account has either Two-Step Verification or Two-Factor Authentication enabled.
		NSURL *authURL = [NSURL URLWithString:kAppleAuthBaseURL];
		NSMutableURLRequest *authRequest = [NSMutableURLRequest requestWithURL:authURL];
		[authRequest setHTTPMethod:@"GET"];
		[authRequest setValue:kAppleAuthWidgetValue forHTTPHeaderField:kAppleAuthWidgetKey];
		[authRequest setValue:appleAuthSessionId forHTTPHeaderField:kAppleAuthSessionIdKey];
		[authRequest setValue:appleAuthScnt forHTTPHeaderField:kAppleAuthScntKey];
		[authRequest setValue:kAppleAuthAcceptValue forHTTPHeaderField:kAppleAuthAcceptKey];
		[authRequest setValue:kAppleAuthContentTypeValue forHTTPHeaderField:kAppleAuthContentTypeKey];
		NSHTTPURLResponse *authResponse = nil;
		NSData *authData = [NSURLConnection sendSynchronousRequest:authRequest returningResponse:&authResponse error:nil];
		NSDictionary *authDict = [NSJSONSerialization JSONObjectWithData:authData options:0 error:nil];
		
		NSString *authenticationType = authDict[@"authType"] ?: authDict[@"authenticationType"];
		if ([authenticationType isEqualToString:@"hsa"]) {
			// This account has Two-Step Verification enabled.
			authType = SCInputTypeTwoStepVerificationCode;
			NSNumber *accountLocked = authDict[@"accountLocked"];
			NSNumber *recoveryKeyLocked = authDict[@"recoveryKeyLocked"];
			NSNumber *securityCodeLocked = authDict[@"securityCodeLocked"];
			[trustedDevices addObjectsFromArray:authDict[@"trustedDevices"] ?: @[]];
			if (accountLocked.boolValue || recoveryKeyLocked.boolValue || securityCodeLocked.boolValue) {
				// User is temporarily locked out of account, and is unable to sign in at the moment. Try again later?
				if ([self.delegate respondsToSelector:@selector(loginFailed:)]) {
					dispatch_async(dispatch_get_main_queue(), ^{
						[self.delegate loginFailed:self];
					});
				}
			} else if (trustedDevices.count == 0) {
				// Account has no trusted devices.
				if ([self.delegate respondsToSelector:@selector(loginFailed:)]) {
					dispatch_async(dispatch_get_main_queue(), ^{
						[self.delegate loginFailed:self];
					});
				}
			} else {
				// Allow user to choose a trusted device.
				[self performSelectorOnMainThread:@selector(chooseTrustedDevice) withObject:nil waitUntilDone:NO];
			}
		} else if ([authenticationType isEqualToString:@"hsa2"]) {
			// This account has Two-Factor Authentication enabled.
			authType = SCInputTypeTwoFactorAuthenticationCode;
			NSDictionary *securityCodeDict = authDict[@"securityCode"];
			NSNumber *tooManyCodesSent = securityCodeDict[@"tooManyCodesSent"];
			NSNumber *tooManyCodesValidated = securityCodeDict[@"tooManyCodesValidated"];
			NSNumber *securityCodeLocked = securityCodeDict[@"securityCodeLocked"];
			if (tooManyCodesSent.boolValue || tooManyCodesValidated.boolValue || securityCodeLocked.boolValue) {
				// User is temporarily locked out of account, and is unable to sign in at the moment. Try again later?
				if ([self.delegate respondsToSelector:@selector(loginFailed:)]) {
					dispatch_async(dispatch_get_main_queue(), ^{
						[self.delegate loginFailed:self];
					});
				}
			} else {
				// Display security code input controller.
				dispatch_async(dispatch_get_main_queue(), ^{
					SecurityCodeInputController *securityCodeInput = [[SecurityCodeInputController alloc] initWithType:SCInputTypeTwoFactorAuthenticationCode];
					securityCodeInput.delegate = self;
					[securityCodeInput show];
				});
			}
		} else {
			// Something else went wrong.
			if ([self.delegate respondsToSelector:@selector(loginFailed:)]) {
				dispatch_async(dispatch_get_main_queue(), ^{
					[self.delegate loginFailed:self];
				});
			}
		}
	}
}

- (void)fetchRemainingCookies {
	NSURL *trustURL = [NSURL URLWithString:[kAppleAuthBaseURL stringByAppendingString:kAppleAuthTrustAction]];
	NSMutableURLRequest *trustRequest = [NSMutableURLRequest requestWithURL:trustURL];
	[trustRequest setHTTPMethod:@"GET"];
	[trustRequest setValue:kAppleAuthWidgetValue forHTTPHeaderField:kAppleAuthWidgetKey];
	[trustRequest setValue:appleAuthSessionId forHTTPHeaderField:kAppleAuthSessionIdKey];
	[trustRequest setValue:appleAuthScnt forHTTPHeaderField:kAppleAuthScntKey];
	[trustRequest setValue:kAppleAuthContentTypeValue forHTTPHeaderField:kAppleAuthContentTypeKey];
	[NSURLConnection sendSynchronousRequest:trustRequest returningResponse:nil error:nil];
	
	NSURL *authSessionURL = [NSURL URLWithString:[kITCAuthBaseURL stringByAppendingString:kITCAuthSessionAction]];
	NSHTTPURLResponse *authSessionResponse = nil;
	NSData *authSessionData = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:authSessionURL] returningResponse:&authSessionResponse error:nil];
	NSDictionary *authSessionDict = [NSJSONSerialization JSONObjectWithData:authSessionData options:0 error:nil];
	
	provider = authSessionDict[@"provider"];
	availableProviders = authSessionDict[@"availableProviders"];
	
	providerID = [(NSNumber *)provider[@"providerId"] description];
	
	if ((providerID == nil) || (providerID.length == 0) || (availableProviders == nil) || (availableProviders.count == 0)) {
		// Failed to fetch available providers.
		if ([self.delegate respondsToSelector:@selector(loginFailed:)]) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[self.delegate loginFailed:self];
			});
		}
	} else if (availableProviders.count > 1) {
		// Multiple providers available.
		if (account != nil) {
			// Logging in with an existing account.
			if ((account.providerID == nil) || (account.providerID.length == 0)) {
				// Provider ID missing for account.
				if ([self.delegate respondsToSelector:@selector(loginFailed:)]) {
					dispatch_async(dispatch_get_main_queue(), ^{
						[self.delegate loginFailed:self];
					});
				}
			} else if (providerID != account.providerID) {
				// Current provider ID does not match preferred account provider ID.
				for (NSDictionary *provider in availableProviders) {
					if (loginInfo[kAccountProviderID] == [(NSNumber *)provider[@"providerId"] description]) {
						[self changeToProvider:provider];
						return;
					}
				}
				// Failed to find preferred account provider ID.
				if ([self.delegate respondsToSelector:@selector(loginFailed:)]) {
					dispatch_async(dispatch_get_main_queue(), ^{
						[self.delegate loginFailed:self];
					});
				}
			} else {
				// Preferred provider ID for account already selected.
				if ([self.delegate respondsToSelector:@selector(loginSucceeded:)]) {
					dispatch_async(dispatch_get_main_queue(), ^{
						[self.delegate loginSucceeded:self];
					});
				}
			}
		} else {
			// Auto-Fill Wizard
			if (loginInfo[kAccountProviderID] == nil) {
				// No preferred provider ID.
				dispatch_async(dispatch_get_main_queue(), ^{
					[self chooseProvider];
				});
			} else if (providerID != loginInfo[kAccountProviderID]) {
				// Current provider ID does not match preferred provider ID.
				for (NSDictionary *provider in availableProviders) {
					if (loginInfo[kAccountProviderID] == [(NSNumber *)provider[@"providerId"] description]) {
						[self changeToProvider:provider];
						return;
					}
				}
				// Failed to find preferred provider ID.
				dispatch_async(dispatch_get_main_queue(), ^{
					[self chooseProvider];
				});
			} else {
				// Preferred provider ID for account already selected.
				if ([self.delegate respondsToSelector:@selector(loginSucceeded:)]) {
					dispatch_async(dispatch_get_main_queue(), ^{
						[self.delegate loginSucceeded:self];
					});
				}
			}
		}
	} else {
		// One provider available.
		if ([self.delegate respondsToSelector:@selector(loginSucceeded:)]) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[self.delegate loginSucceeded:self];
			});
		}
	}
}

- (void)chooseProvider {
	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Select Your Primary Provider", nil)
																			 message:nil
																	  preferredStyle:UIAlertControllerStyleActionSheet];
	
	for (NSDictionary *provider in availableProviders) {
		NSString *providerName = provider[@"name"];
		NSString *providerID = [(NSNumber *)provider[@"providerId"] description];
		NSString *buttonTitle = [NSString stringWithFormat:@"%@ (%@)", providerName, providerID];
		[alertController addAction:[UIAlertAction actionWithTitle:buttonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
				[self changeToProvider:provider];
			});
		}]];
	}
	
	[alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
		if ([self.delegate respondsToSelector:@selector(loginFailed:)]) {
			// User canceled the provider selection, so we're unable to log in.
			[self.delegate loginFailed:self];
		}
	}]];
	
	UIViewController *viewController = [UIApplication sharedApplication].keyWindow.rootViewController;
	while (viewController.presentedViewController != nil) {
		viewController = viewController.presentedViewController;
	}
	[viewController presentViewController:alertController animated:YES completion:nil];
}

- (void)changeToProvider:(NSDictionary *)_provider {
	provider = _provider;
	providerID = [(NSNumber *)_provider[@"providerId"] description];
	
	NSDictionary *bodyDict = @{@"provider": _provider};
	NSData *bodyData = [NSJSONSerialization dataWithJSONObject:bodyDict options:0 error:nil];
	
	NSURL *authSessionURL = [NSURL URLWithString:[kITCAuthBaseURL stringByAppendingString:kITCAuthSessionAction]];
	NSMutableURLRequest *authSessionRequest = [NSMutableURLRequest requestWithURL:authSessionURL];
	[authSessionRequest setHTTPMethod:@"POST"];
	[authSessionRequest setValue:kAppleAuthContentTypeValue forHTTPHeaderField:kAppleAuthContentTypeKey];
	[authSessionRequest setHTTPBody:bodyData];
    [[NSURLSession.sharedSession dataTaskWithRequest:authSessionRequest
                                   completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if ([self.delegate respondsToSelector:@selector(loginSucceeded:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate loginSucceeded:self];
            });
        }
    }] resume];
}

- (void)generateCode:(NSString *)_appleAuthTrustedDeviceId {
	appleAuthTrustedDeviceId = _appleAuthTrustedDeviceId;
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
		NSURL *deviceURL = [NSURL URLWithString:[kAppleAuthBaseURL stringByAppendingFormat:kAppleAuthDeviceAction, _appleAuthTrustedDeviceId]];
		NSMutableURLRequest *deviceRequest = [NSMutableURLRequest requestWithURL:deviceURL];
		[deviceRequest setHTTPMethod:@"PUT"];
		[deviceRequest setValue:kAppleAuthWidgetValue forHTTPHeaderField:kAppleAuthWidgetKey];
        [deviceRequest setValue:self->appleAuthSessionId forHTTPHeaderField:kAppleAuthSessionIdKey];
        [deviceRequest setValue:self->appleAuthScnt forHTTPHeaderField:kAppleAuthScntKey];
		[deviceRequest setValue:kAppleAuthContentTypeValue forHTTPHeaderField:kAppleAuthContentTypeKey];
        [[NSURLSession.sharedSession dataTaskWithRequest:deviceRequest
                                       completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            
            NSDictionary *deviceDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            
            NSDictionary *securityCode = deviceDict[@"securityCode"];
            NSNumber *securityCodeLength = securityCode[@"length"];
            if (securityCodeLength.integerValue == 4) {
                // Display security code input controller.
                dispatch_async(dispatch_get_main_queue(), ^{
                    SecurityCodeInputController *securityCodeInput = [[SecurityCodeInputController alloc] initWithType:SCInputTypeTwoStepVerificationCode];
                    securityCodeInput.delegate = self;
                    [securityCodeInput show];
                });
            } else {
                // Authentication is requesting a security code with an unsupported number of digits.
                if ([self.delegate respondsToSelector:@selector(loginFailed:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.delegate loginFailed:self];
                    });
                }
            }
        }] resume];
	});
}

- (void)validateCode:(NSString *)securityCode {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
		NSDictionary *bodyDict = nil;
        switch (self->authType) {
			case SCInputTypeTwoStepVerificationCode:
				bodyDict = @{@"code": securityCode};
				break;
			case SCInputTypeTwoFactorAuthenticationCode:
				bodyDict = @{@"securityCode": @{@"code": securityCode}};
				break;
			default:
				bodyDict = @{};
				break;
		}
		NSData *bodyData = [NSJSONSerialization dataWithJSONObject:bodyDict options:0 error:nil];
		
		NSURL *verifyURL = [NSURL URLWithString:[kAppleAuthBaseURL stringByAppendingFormat:kAppleAuthCodeAction]];
        if (self->authType == SCInputTypeTwoStepVerificationCode) {
            verifyURL = [NSURL URLWithString:[kAppleAuthBaseURL stringByAppendingFormat:kAppleAuthDeviceAction, self->appleAuthTrustedDeviceId]];
		}
		NSMutableURLRequest *verifyRequest = [NSMutableURLRequest requestWithURL:verifyURL];
		[verifyRequest setHTTPMethod:@"POST"];
		[verifyRequest setValue:kAppleAuthWidgetValue forHTTPHeaderField:kAppleAuthWidgetKey];
        [verifyRequest setValue:self->appleAuthSessionId forHTTPHeaderField:kAppleAuthSessionIdKey];
        [verifyRequest setValue:self->appleAuthScnt forHTTPHeaderField:kAppleAuthScntKey];
		[verifyRequest setValue:kAppleAuthContentTypeValue forHTTPHeaderField:kAppleAuthContentTypeKey];
		[verifyRequest setHTTPBody:bodyData];
        [[NSURLSession.sharedSession dataTaskWithRequest:verifyRequest
                                       completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            
            NSString *setCookie = ((NSHTTPURLResponse*)response).allHeaderFields[kAppleAuthSetCookieKey];
            if (([setCookie rangeOfString:@"myacinfo"].location != NSNotFound) || self.isLoggedIn) {
                // We're in!
                [self fetchRemainingCookies];
            } else {
                // Incorrect verification code. Retry?
                switch (self->authType) {
                    case SCInputTypeTwoStepVerificationCode: {
                        [self performSelectorOnMainThread:@selector(chooseTrustedDevice) withObject:nil waitUntilDone:NO];
                        break;
                    }
                    case SCInputTypeTwoFactorAuthenticationCode: {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            SecurityCodeInputController *securityCodeInput = [[SecurityCodeInputController alloc] initWithType:SCInputTypeTwoFactorAuthenticationCode];
                            securityCodeInput.delegate = self;
                            [securityCodeInput show];
                        });
                        break;
                    }
                    default: {
                        break;
                    }
                }
            }
        }] resume];
	});
}

- (void)chooseTrustedDevice {
	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Verify Your Identity", nil)
																			 message:NSLocalizedString(@"Your Apple ID is protected with two-step verification.\nChoose a trusted device to receive a verification code.", nil)
																	  preferredStyle:UIAlertControllerStyleActionSheet];
	
	for (NSDictionary *trustedDevice in trustedDevices) {
		NSNumber *isDevice = trustedDevice[@"device"];
		NSString *deviceName = trustedDevice[@"name"];
		if (isDevice.boolValue) {
			NSString *modelName = trustedDevice[@"modelName"];
			deviceName = [deviceName stringByAppendingFormat:@" (%@)", modelName];
		} else if ([trustedDevice[@"type"] isEqualToString:@"sms"]) {
			deviceName = [NSString stringWithFormat:@"Phone number ending in %@", trustedDevice[@"lastTwoDigits"]];
		}
		NSString *deviceId = trustedDevice[@"id"];
		[alertController addAction:[UIAlertAction actionWithTitle:deviceName style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
			[self generateCode:deviceId];
		}]];
	}
	
	[alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
		if ([self.delegate respondsToSelector:@selector(loginFailed:)]) {
			// User canceled the verification, so we're unable to log in.
			[self.delegate loginFailed:self];
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
	if ([self.delegate respondsToSelector:@selector(loginFailed:)]) {
		[self.delegate loginFailed:self];
	}
}

- (void)generateCSRFTokenWithCompletionBlock:(void(^)(NSString *csrfToken))completionBlock {
	NSURL *generateCSRFTokenURL = [NSURL URLWithString:[kITCRBaseURL stringByAppendingString:kITCRGenerateCSRFTokenAction]];
	NSMutableURLRequest *generateRequest = [NSMutableURLRequest requestWithURL:generateCSRFTokenURL];
	[generateRequest setHTTPMethod:@"POST"];
	[generateRequest setValue:kITCRFetchCSRFTokenValue forHTTPHeaderField:kITCRFetchCSRFTokenKey];
	[generateRequest setValue:kITCRXRequestedWithValue forHTTPHeaderField:kITCRXRequestedWithKey];
    [[NSURLSession.sharedSession dataTaskWithRequest:generateRequest
                                   completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        NSString *generateString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (generateString != nil) {
            NSRange csrfRange = [generateString rangeOfString:@"CSRF:"];
            if (csrfRange.location != NSNotFound) {
                NSUInteger csrfStart = csrfRange.location + csrfRange.length;
                completionBlock([generateString substringFromIndex:csrfStart]);
                return;
            }
        }
        completionBlock(nil);
    }] resume];
}

- (NSDictionary *)getAccessKey:(NSString *)csrfToken {
	NSURL *getAccessKeyURL = [NSURL URLWithString:[kITCRBaseURL stringByAppendingString:kITCRGetAccessKeyAction]];
	NSMutableURLRequest *getRequest = [NSMutableURLRequest requestWithURL:getAccessKeyURL];
	[getRequest setHTTPMethod:@"GET"];
	[getRequest setValue:kITCRXRequestedWithValue forHTTPHeaderField:kITCRXRequestedWithKey];
	[getRequest setValue:csrfToken forHTTPHeaderField:kITCRCSRFKey];
	NSHTTPURLResponse *getResponse = nil;
	NSData *getData = [NSURLConnection sendSynchronousRequest:getRequest returningResponse:&getResponse error:nil];
	NSDictionary *getDict = [NSJSONSerialization JSONObjectWithData:getData options:0 error:nil];
    NSString *status = getDict[@"status"];
    if ((status != nil) && [status isEqualToString:@"success"]) {
        if (getDict[@"result"]) {
            NSDictionary *result = getDict[@"result"];
            if (result[@"data"]) {
                NSDictionary *data = result[@"data"];
                NSMutableDictionary *resultDict = [[NSMutableDictionary alloc] init];
                resultDict[@"accessKey"] = data[@"accessKey"];
                resultDict[@"createdDate"] = [dateFormatter dateFromString:data[@"createdDate"]];
                resultDict[@"expiryDate"] = [dateFormatter dateFromString:data[@"expiryDate"]];
                return resultDict;
            }
        }
    }
	return nil;
}

- (NSDictionary *)resetAccessKey:(NSString *)csrfToken {
	NSURL *resetAccessKeyURL = [NSURL URLWithString:[kITCRBaseURL stringByAppendingString:kITCRResetAccessKeyAction]];
	NSMutableURLRequest *resetRequest = [NSMutableURLRequest requestWithURL:resetAccessKeyURL];
	[resetRequest setHTTPMethod:@"GET"];
	[resetRequest setValue:kITCRXRequestedWithValue forHTTPHeaderField:kITCRXRequestedWithKey];
	[resetRequest setValue:csrfToken forHTTPHeaderField:kITCRCSRFKey];
	NSHTTPURLResponse *resetResponse = nil;
	NSData *resetData = [NSURLConnection sendSynchronousRequest:resetRequest returningResponse:&resetResponse error:nil];
	NSDictionary *resetDict = [NSJSONSerialization JSONObjectWithData:resetData options:0 error:nil];
    NSString *status = resetDict[@"status"];
    if ((status != nil) && [status isEqualToString:@"success"]) {
        if (resetDict[@"result"]) {
            NSDictionary *result = resetDict[@"result"];
            if (result[@"data"]) {
                NSDictionary *data = result[@"data"];
                NSMutableDictionary *resultDict = [[NSMutableDictionary alloc] init];
                resultDict[@"accessKey"] = data[@"accessKey"];
                resultDict[@"createdDate"] = [dateFormatter dateFromString:data[@"createdDate"]];
                resultDict[@"expiryDate"] = [dateFormatter dateFromString:data[@"expiryDate"]];
                return resultDict;
            }
        }
    }
    return nil;
}

@end
