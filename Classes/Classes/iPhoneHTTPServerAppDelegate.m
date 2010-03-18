//
//  This class was created by Nonnus,
//  who graciously decided to share it with the CocoaHTTPServer community.
//

#import "iPhoneHTTPServerAppDelegate.h"
#import "HTTPServer.h"
#import "MyHTTPConnection.h"
#import "localhostAddresses.h"


@implementation iPhoneHTTPServerAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(UIApplication *)application 
{
	[window makeKeyAndVisible];
	
	NSString *root = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0];
	
	httpServer = [HTTPServer new];
	[httpServer setType:@"_http._tcp."];
	[httpServer setConnectionClass:[MyHTTPConnection class]];
	[httpServer setDocumentRoot:[NSURL fileURLWithPath:root]];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(displayInfoUpdate:) name:@"LocalhostAdressesResolved" object:nil];
	[localhostAddresses performSelectorInBackground:@selector(list) withObject:nil];
}

- (void)displayInfoUpdate:(NSNotification *) notification
{
	NSLog(@"displayInfoUpdate:");

	if(notification)
	{
		[addresses release];
		addresses = [[notification object] copy];
		NSLog(@"addresses: %@", addresses);
	}

	if(addresses == nil)
	{
		return;
	}
	
	NSString *info;
	UInt16 port = [httpServer port];
	
	NSString *localIP = nil;
	
	localIP = [addresses objectForKey:@"en0"];
	
	if (!localIP)
	{
		localIP = [addresses objectForKey:@"en1"];
	}

	if (!localIP)
		info = @"Wifi: No Connection!\n";
	else
		info = [NSString stringWithFormat:@"http://iphone.local:%d		http://%@:%d\n", port, localIP, port];

	NSString *wwwIP = [addresses objectForKey:@"www"];

	if (wwwIP)
		info = [info stringByAppendingFormat:@"Web: %@:%d\n", wwwIP, port];
	else
		info = [info stringByAppendingString:@"Web: Unable to determine external IP\n"];

	displayInfo.text = info;
}


- (IBAction)startStopServer:(id)sender
{
	if ([sender isOn])
	{
		// You may OPTIONALLY set a port for the server to run on.
		// 
		// If you don't set a port, the HTTP server will allow the OS to automatically pick an available port,
		// which avoids the potential problem of port conflicts. Allowing the OS server to automatically pick
		// an available port is probably the best way to do it if using Bonjour, since with Bonjour you can
		// automatically discover services, and the ports they are running on.
	//	[httpServer setPort:8080];
		
		NSError *error;
		if(![httpServer start:&error])
		{
			NSLog(@"Error starting HTTP Server: %@", error);
		}

		[self displayInfoUpdate:nil];
	}
	else
	{
		[httpServer stop];
	}
}

- (void)dealloc 
{
	[httpServer release];
    [window release];
    [super dealloc];
}


@end
