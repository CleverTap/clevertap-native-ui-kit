import Flutter
import UIKit
import CleverTapSDK

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Standard clevertap_plugin integration. autoIntegrate reads credentials
    // from Info.plist (CleverTapAccountID / CleverTapToken / CleverTapRegion).
    // Native Display units are delivered to Flutter through the plugin's
    // display-unit delegate — no native bridge required here.
    CleverTap.setDebugLevel(2)
    CleverTap.autoIntegrate()

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
