
#import <Foundation/Foundation.h>

@class App;

@interface AppManager : NSObject {	
	NSMutableDictionary *appsByID;
}

+ (AppManager*) sharedManager;

@property (readonly) NSUInteger numberOfApps;
@property (readonly) NSArray *allApps;
@property (readonly) NSArray *allAppIDs;
@property (readonly) NSArray *allAppsSorted;
@property (readonly) NSArray *allAppNamesSorted;

- (NSString *)appIDForAppName:(NSString *)appName;
- (App*) appWithID:(NSString*)appID;
- (void) addApp:(App*)app;
- (BOOL) createOrUpdateAppIfNeededWithID:(NSString*)appID name:(NSString*)appName;
- (void) removeAppWithID:(NSString*)appID;
- (void) saveToDisk;

@end
