import SwiftUI
import CleverTapNativeDisplay
import CleverTapSDK

@main
struct NativeDisplaySampleApp: App {
#if DEBUG
    @StateObject private var preloader = ImagePreloader()

    private var preloadImages: Bool {
        ProcessInfo.processInfo.environment["PRELOAD_IMAGES"] == "1"
    }
#endif

    init() {
        // Initialize NativeDisplayBridge and bind to CleverTap at app launch
        let bridge = NativeDisplayBridge.shared
        if let ct = CleverTap.sharedInstance() {
            bridge.bind(ct)
            bridge.fetchNativeDisplays(ct)
            print("[NativeDisplaySampleApp] Bridge bound and fetch requested")
        } else {
            print("[NativeDisplaySampleApp] CleverTap not configured — check Info.plist credentials")
        }
    }

    var body: some Scene {
        WindowGroup {
#if DEBUG
            ContentView()
                .overlay(preloadBadge)
                .task {
                    guard preloadImages else { return }
                    await preloader.preloadAll()
                }
#else
            ContentView()
#endif
        }
    }

#if DEBUG
    /// Zero-size view that exposes "images-preloaded" accessibility identifier
    /// once preloading completes. XCUITest waits on this before starting the screenshot loop.
    @ViewBuilder
    private var preloadBadge: some View {
        if preloadImages && preloader.isComplete {
            Color.clear
                .frame(width: 0, height: 0)
                .accessibilityIdentifier("images-preloaded")
        }
    }
#endif
}
