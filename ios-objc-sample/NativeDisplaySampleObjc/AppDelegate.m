//
//  AppDelegate.m
//  NativeDisplaySampleObjc
//

#import "AppDelegate.h"
@import CleverTapSDK;
@import CleverTapNativeDisplay;
@import UserNotifications;

@interface AppDelegate () <UNUserNotificationCenterDelegate>
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self registerForPush];

    [CleverTap setDebugLevel:CleverTapLogDebug];
    [CleverTap autoIntegrate];

    [NativeDisplayBridge setLogLevel:NDLogLevelDebug];
    [[NativeDisplayBridge shared] bind:[CleverTap sharedInstance] forwardTo:nil];
    [[NativeDisplayBridge shared] fetchNativeDisplays:[CleverTap sharedInstance]];
    return YES;
}

- (void)registerForPush {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    center.delegate = self;
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionBadge | UNAuthorizationOptionSound)
                          completionHandler:^(BOOL granted, NSError *error) {
        if (granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] registerForRemoteNotifications];
            });
        }
    }];
}

#pragma mark - UISceneSession lifecycle

- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}

- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
}

@end
