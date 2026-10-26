#import "AppDelegate.h"

#import <React/RCTBundleURLProvider.h>
#import <CleverTapSDK/CleverTap.h>
#import "CleverTapReactManager.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  [CleverTap setDebugLevel:2];
  [CleverTap autoIntegrate];
  [[CleverTapReactManager sharedInstance] applicationDidLaunchWithOptions:launchOptions];

  self.moduleName = @"ND076";
  // You can add your custom initial props in the dictionary below.
  // They will be passed down to the ViewController used by React Native.
  self.initialProps = @{};

  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (NSURL *)sourceURLForBridge:(RCTBridge *)bridge
{
  return [self bundleURL];
}

- (NSURL *)bundleURL
{
#if DEBUG
  return [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index"];
#else
  return [[NSBundle mainBundle] URLForResource:@"main" withExtension:@"jsbundle"];
#endif
}

@end
