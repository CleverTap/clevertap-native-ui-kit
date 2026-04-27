//
//  AppDelegate.swift
//  NativeDisplayUiKit
//
//  Created by Lalitkumar Patil on 15/01/26.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Create window (for iOS 12 compatibility or when SceneDelegate is not used)
        window = UIWindow(frame: UIScreen.main.bounds)
        
        // Set root view controller
        let mainVC = MainViewController()
        let navigationController = UINavigationController(rootViewController: mainVC)
        
        // Configure navigation bar appearance
        configureNavigationBarAppearance(navigationController)
        
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
        
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
    
    // MARK: - Navigation Bar Configuration
    
    private func configureNavigationBarAppearance(_ navigationController: UINavigationController) {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]
        
        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
        navigationController.navigationBar.compactAppearance = appearance
        navigationController.navigationBar.tintColor = UIColor(red: 1.0, green: 0.34, blue: 0.13, alpha: 1.0) // #FF5722
    }
}
