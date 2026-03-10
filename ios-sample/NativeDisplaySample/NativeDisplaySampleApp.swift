import SwiftUI
import CleverTapNativeDisplay

@main
struct NativeDisplaySampleApp: App {
    @StateObject private var preloader = ImagePreloader()

    private var preloadImages: Bool {
        ProcessInfo.processInfo.environment["PRELOAD_IMAGES"] == "1"
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .overlay(preloadBadge)
                .task {
                    guard preloadImages else { return }
                    await preloader.preloadAll()
                }
        }
    }

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
}
