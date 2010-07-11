
#import <Foundation/Foundation.h>

@class App;

@interface AppManager : NSObject {	
	NSMutableDictionary *appsByID;
}

+ (AppManager*) sharedManager;

@property (readonly) NSUInteger numberOfApps;
@property (readonly) NSArray *allApps;
@property (readonly) NSArray *allAppIDs;

- (NSString *)appIDForAppName:(NSString *)appName;
- (App*) appWithID:(NSString*)appID;
- (void) addApp:(App*)app;
- (BOOL) createOrUpdateAppIfNeededWithID:(NSString*)appID name:(NSString*)appName;
- (NSArray*) appNamesSorted;
- (void) saveToDisk;

@end
