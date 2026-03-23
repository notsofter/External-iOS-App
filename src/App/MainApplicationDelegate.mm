#import "MainApplicationDelegate.h"
#import "SessionViewController.h"
#import "../Helpers/CustomDefaults.h"
#import "../Helpers/Device.h"

@implementation MainApplicationDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions
{
    [[CustomDefaults sharedInstance] setCustomPath:[Device getDocumentsApp]];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.window makeKeyAndVisible];
    
    SessionViewController *sessionVC = [[SessionViewController alloc] init];
    self.window.rootViewController = sessionVC;

    return YES;
}

@end