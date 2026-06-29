import UIKit
import CleverTapSDK
import CleverTapNativeDisplay

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // 1. Initialize CleverTap (reads credentials from Info.plist)
        registerForPush()
        CleverTap.setDebugLevel(2)
        CleverTap.autoIntegrate()
        NativeDisplayBridge.setLogLevel(.debug)
        // 2. Bind NativeDisplayBridge to CleverTap and request display units
        let bridge = NativeDisplayBridge.shared
        if let ct = CleverTap.sharedInstance() {
            bridge.bind(ct)
            bridge.fetchNativeDisplays(ct)
            print("[AppDelegate] Bridge bound and fetch requested")
        } else {
            print("[AppDelegate] CleverTap not configured — check Info.plist credentials")
        }
        
        return true
    }
    
    func registerForPush() {
        // Register for Push notifications
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.sound, .badge, .alert], completionHandler: {granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        })
    }
}
