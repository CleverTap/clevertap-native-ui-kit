#import "RootTabBarController.h"
#import "CleverTapIntegrationViewController.h"
#import "SlotDemoViewController.h"
#import "UIKitDemoViewController.h"
#import "DemoMenuViewController.h"

@implementation RootTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.viewControllers = @[
        [self makeTab:[CleverTapIntegrationViewController new] title:@"Events" sfSymbol:@"antenna.radiowaves.left.and.right"],
        [self makeTab:[SlotDemoViewController new] title:@"Slots" sfSymbol:@"square.stack.3d.up"],
        [self makeTab:[UIKitDemoViewController new] title:@"UIKit" sfSymbol:@"macwindow"],
        [self makeMoreTab],
    ];
}

- (UIViewController *)makeTab:(UIViewController *)vc title:(NSString *)title sfSymbol:(NSString *)symbol {
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.tabBarItem = [[UITabBarItem alloc] initWithTitle:title image:[UIImage systemImageNamed:symbol] tag:0];
    return nav;
}

- (UIViewController *)makeMoreTab {
    DemoMenuViewController *menu = [DemoMenuViewController new];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:menu];
    nav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"More" image:[UIImage systemImageNamed:@"ellipsis.circle"] tag:0];
    return nav;
}

@end
