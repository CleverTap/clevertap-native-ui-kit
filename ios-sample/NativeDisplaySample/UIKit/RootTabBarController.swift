import UIKit
import SwiftUI

/// Programmatic UITabBarController configuring the 5 primary app tabs.
/// UITabBarController retains each UIViewController across tab switches,
/// so state is preserved without any extra work.
class RootTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        viewControllers = [
            makeTab(
                UIHostingController(rootView: CleverTapIntegrationView()),
                title: "Events",
                sfSymbol: "antenna.radiowaves.left.and.right"
            ),
            makeTab(
                UIHostingController(rootView: SlotDemoView()),
                title: "Slots",
                sfSymbol: "square.stack.3d.up"
            ),
            makeTab(
                UIKitTestViewController(),
                title: "UIKit",
                sfSymbol: "macwindow"
            ),
            makeTab(
                UIKitSlotDemoViewController(),
                title: "UIKit Slots",
                sfSymbol: "square.grid.3x3"
            ),
            makeTab(
                UIHostingController(rootView: TestConfigBrowserView()),
                title: "Browser",
                sfSymbol: "testtube.2"
            ),
            makeTab(
                makeMoreTab(),
                title: "More",
                sfSymbol: "ellipsis.circle"
            ),
        ]
    }

    // MARK: - Private helpers

    private func makeTab(_ vc: UIViewController, title: String, sfSymbol: String) -> UIViewController {
        vc.tabBarItem = UITabBarItem(
            title: title,
            image: UIImage(systemName: sfSymbol),
            tag: 0
        )
        return vc
    }

    private func makeMoreTab() -> UIViewController {
        let hosting = UIHostingController(rootView: NavigationView { MoreMenuView() })
        let nav = UINavigationController(rootViewController: hosting)
        return nav
    }
}
