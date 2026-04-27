//
//  SceneDelegate.swift
//  NativeDisplayUiKit
//
//  Created by Lalitkumar Patil on 15/01/26.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        // Create window
        window = UIWindow(windowScene: windowScene)
        
        // Set root view controller
        let mainVC = MainViewController()
        let navigationController = UINavigationController(rootViewController: mainVC)
        
        // Configure navigation bar appearance
        configureNavigationBarAppearance(navigationController)
        
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
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
        navigationController.navigationBar.tintColor = UIColor(red: 1.0, green: 0.34, blue: 0.13, alpha: 1.0)
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
    }
}
