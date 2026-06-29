import Flutter
import UIKit
import CleverTapSDK
import CleverTapNativeDisplay

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize CleverTap (reads credentials from Info.plist)
    CleverTap.setDebugLevel(2)
    CleverTap.autoIntegrate()

    // Bind NativeDisplayBridge to CleverTap and request display units
    let bridge = NativeDisplayBridge.shared
    if let ct = CleverTap.sharedInstance() {
      bridge.bind(ct)
      bridge.fetchNativeDisplays(ct)
      print("[AppDelegate] Bridge bound and fetch requested")
    } else {
      print("[AppDelegate] CleverTap not configured — check Info.plist credentials")
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
