//
//  This class was created by Nonnus,
//  who graciously decided to share it with the CocoaHTTPServer community.
//

#import <UIKit/UIKit.h>
@class   HTTPServer;

@interface iPhoneHTTPServerAppDelegate : NSObject <UIApplicationDelegate> 
{
    UIWindow *window;
	HTTPServer *httpServer;
	NSDictionary *addresses;
	
	IBOutlet UILabel *displayInfo;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

-(IBAction) startStopServer:(id)sender;
@end

