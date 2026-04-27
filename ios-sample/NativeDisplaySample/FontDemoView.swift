import SwiftUI
import CleverTapNativeDisplay

// MARK: - Font Demo View

/// Demonstrates the two SDK font customization environment values:
///   - \.nativeDisplayFontFamily  — client-provided font name (highest priority)
///   - \.nativeDisplayFontResolver — custom resolver for JSON fontFamily names
///
/// Uses standard system fonts (Georgia, Courier) as stand-ins; no custom font
/// files are required. iOS-specific note: SF Pro is the default system font,
/// which differs from Android's Roboto — this intentional difference is documented
/// here per the cross-platform divergence policy.
struct FontDemoView: View {
    @State private var config: ResolvedConfig?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                VStack {
                    ProgressView()
                    Text("Loading...")
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = errorMessage {
                ErrorView(message: error) {
                    loadConfig()
                }
            } else if let config = config {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {

                        // Section A: System default — San Francisco (SF Pro)
                        sectionHeader("System Default Font (San Francisco)")
                        NativeDisplayView(config: config)
                            .frame(maxWidth: .infinity)

                        Divider()

                        // Section B: Client font override via environment value
                        sectionHeader("Client Font — Georgia (via .nativeDisplayFontFamily)")
                        NativeDisplayView(config: config)
                            .environment(\.nativeDisplayFontFamily, "Georgia")
                            .frame(maxWidth: .infinity)

                        Divider()

                        // Section C: Custom resolver — maps JSON fontFamily names to
                        // concrete fonts. "mono" → Courier, anything else → Georgia.
                        sectionHeader("Resolver: 'mono' → Courier, others → Georgia")
                        NativeDisplayView(config: config)
                            .environment(\.nativeDisplayFontResolver, { name, size, weight in
                                if name.lowercased() == "mono" {
                                    return Font.custom("Courier", size: size).weight(weight)
                                }
                                return Font.custom("Georgia", size: size).weight(weight)
                            })
                            .frame(maxWidth: .infinity)
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Font Customization")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadConfig()
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.bottom, 4)
    }

    private func loadConfig() {
        isLoading = true
        errorMessage = nil

        // Prefer banner-09 (premium subscription); fall back to banner-01.
        if let loaded = JsonLoader.loadConfig(filename: "banner-09-premium-subscription", fromDirectory: "Banners") {
            config = loaded
            isLoading = false
        } else if let loaded = JsonLoader.loadConfig(filename: "banner-01-hero-summer-sale", fromDirectory: "Banners") {
            config = loaded
            isLoading = false
        } else {
            errorMessage = "Could not find a banner config in the Banners directory."
            isLoading = false
        }
    }
}

#Preview {
    NavigationView {
        FontDemoView()
    }
}
