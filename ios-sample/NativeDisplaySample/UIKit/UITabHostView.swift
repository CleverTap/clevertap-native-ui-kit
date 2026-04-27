import SwiftUI
import UIKit

/// UIViewControllerRepresentable that wraps RootTabBarController.
/// Used as the root view in ContentView to host the UIKit tab bar.
struct UITabHostView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UITabBarController {
        RootTabBarController()
    }

    func updateUIViewController(_ uiViewController: UITabBarController, context: Context) {}
}
