#import "AppDelegate.h"
#import "LoginViewController.h"
#import "MainTabBarController.h"
#import <FirebaseCore/FirebaseCore.h>
#import <FirebaseAuth/FirebaseAuth.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // 1. Initialize Firebase
    [FIRApp configure];

    // 2. Decide initial screen based on auth state
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];

    UIViewController *rootVC;
    if ([FIRAuth auth].currentUser) {
        // Already logged in — go straight to the tab bar
        rootVC = [sb instantiateViewControllerWithIdentifier:@"MainTabBarController"];
    } else {
        rootVC = [sb instantiateViewControllerWithIdentifier:@"LoginViewController"];
    }

    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = rootVC;
    [self.window makeKeyAndVisible];

    return YES;
}

@end
