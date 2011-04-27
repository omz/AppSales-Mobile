
#import "AppManager.h"
#import "App.h"
#import "AppSalesUtils.h"

#define APP_ENCODED_FILE_NAME @"encodedApps"

@implementation AppManager

+ (AppManager*) sharedManager {
    ASSERT_IS_MAIN_THREAD();
	static AppManager *shared = nil;
	if (! shared) {
		shared = [AppManager new];
	}
	return shared;
}

- (id) init {
    self = [super init];
	if (self) {
		NSString *reviewsFile = [getDocPath() stringByAppendingPathComponent:APP_ENCODED_FILE_NAME];
		if ([[NSFileManager defaultManager] fileExistsAtPath:reviewsFile]) {
			appsByID = [[NSKeyedUnarchiver unarchiveObjectWithFile:reviewsFile] retain];
		} else {
			appsByID = [NSMutableDictionary new];
		}
	}
	return self;
}

- (NSString *)appIDForAppName:(NSString *)appName {
	for(App *app in self.allApps){
		for(NSString *n in app.allAppNames){
			if([n isEqualToString:appName])
				return app.appID;
		}
	}
	return nil;
}

- (NSArray*) allApps {
	return appsByID.allValues;
}

- (NSArray*) allAppIDs {
	return appsByID.allKeys;
}


- (App*) appWithID:(NSString*)appID {
	return [appsByID objectForKey:appID];
}

- (void) addApp:(App*)app {
	[appsByID setObject:app forKey:app.appID];
}

- (void) removeAppWithID:(NSString*)appID {
    [appsByID removeObjectForKey:appID];
}

- (BOOL) createOrUpdateAppIfNeededWithID:(NSString*)appID name:(NSString*)appName {
	App *app = [self appWithID:appID];
	if (app == nil) {
		app = [[App alloc] initWithID:appID name:appName];
		[self addApp:app];
		[app release];
		return YES;
	}
	if (! [app.appName isEqualToString:appName]) {
		[app updateApplicationName:appName]; // name of app has changed
	}
	return NO; // was already present
}

- (NSUInteger) numberOfApps {
	return appsByID.count;
}

- (NSArray*) allAppsSorted {
	NSArray *allApps = appsByID.allValues;
	NSSortDescriptor *appSorter = [[[NSSortDescriptor alloc] initWithKey:@"appName" ascending:YES] autorelease];
	return [allApps sortedArrayUsingDescriptors:[NSArray arrayWithObject:appSorter]];
}

- (NSArray*) allAppNamesSorted {
	NSArray *sortedApps = self.allAppsSorted;
	NSMutableArray *sortedNames = [NSMutableArray arrayWithCapacity:sortedApps.count];
	for (App *app in sortedApps) {
		[sortedNames addObject:app.appName];
	}
	return sortedNames;
}

- (void) saveToDisk {
	NSString *fullPath = [getDocPath() stringByAppendingPathComponent:APP_ENCODED_FILE_NAME];
	[NSKeyedArchiver archiveRootObject:appsByID toFile:fullPath];
}


@end
