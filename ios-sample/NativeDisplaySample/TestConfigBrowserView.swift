import SwiftUI
import CleverTapNativeDisplay

// MARK: - Data Models

/// Represents a test configuration item
struct TestConfigItem: Identifiable {
    let id: String
    let filename: String
    let displayName: String
    let category: String
}

// MARK: - Main View

/// Test Configuration Browser - Displays and renders test JSON configurations
struct TestConfigBrowserView: View {
    @State private var selectedTestConfig: String? = nil
    @State private var config: ResolvedConfig? = nil
    @State private var errorMessage: String? = nil
    @State private var isLoading = false

    /// List of available test configurations
    /// Start with 1 test, designed to scale to 30+
    private let testConfigs = [
        TestConfigItem(
            id: "test-091",
            filename: "test-091-offset-percent-box-basic",
            displayName: "091: Offset % - Box Basic",
            category: "Offset"
        ),
        // MARK: - Percentage BOX Container Test Suite (test-121 to test-155)
        TestConfigItem(id: "test-121", filename: "test-121-16x9-ar-image-text-button", displayName: "121: 16:9 AR - Image+Text+Button", category: "Percentage BOX"),
        TestConfigItem(id: "test-122", filename: "test-122-1x1-ar-image-badge-rounded", displayName: "122: 1:1 AR - Image+Badge+Rounded", category: "Percentage BOX"),
        TestConfigItem(id: "test-123", filename: "test-123-9x16-ar-video-caption", displayName: "123: 9:16 AR - Video+Caption", category: "Percentage BOX"),
        TestConfigItem(id: "test-124", filename: "test-124-4x3-ar-text-weights", displayName: "124: 4:3 AR - Text Weights", category: "Percentage BOX"),
        TestConfigItem(id: "test-125", filename: "test-125-2x1-ar-image-split-button", displayName: "125: 2:1 AR - Image Split+Button", category: "Percentage BOX"),
        TestConfigItem(id: "test-126", filename: "test-126-text-font-weights", displayName: "126: Text - Font Weights", category: "Percentage BOX"),
        TestConfigItem(id: "test-127", filename: "test-127-text-font-sizes", displayName: "127: Text - Font Sizes", category: "Percentage BOX"),
        TestConfigItem(id: "test-128", filename: "test-128-text-alignment", displayName: "128: Text - Alignment", category: "Percentage BOX"),
        TestConfigItem(id: "test-129", filename: "test-129-text-decoration-italic", displayName: "129: Text - Decoration+Italic", category: "Percentage BOX"),
        TestConfigItem(id: "test-130", filename: "test-130-text-maxlines-overflow", displayName: "130: Text - MaxLines+Overflow", category: "Percentage BOX"),
        TestConfigItem(id: "test-131", filename: "test-131-text-gradient", displayName: "131: Text - Gradient", category: "Percentage BOX"),
        TestConfigItem(id: "test-132", filename: "test-132-image-fit-crop-contain", displayName: "132: Image - Fit Crop vs Contain", category: "Percentage BOX"),
        TestConfigItem(id: "test-133", filename: "test-133-image-gif-rounded", displayName: "133: Image - GIF+Rounded", category: "Percentage BOX"),
        TestConfigItem(id: "test-134", filename: "test-134-image-border-radius", displayName: "134: Image - Border Radius", category: "Percentage BOX"),
        TestConfigItem(id: "test-135", filename: "test-135-images-z-order", displayName: "135: Images - Z-Order", category: "Percentage BOX"),
        TestConfigItem(id: "test-136", filename: "test-136-video-autoplay-muted", displayName: "136: Video - AutoPlay+Muted", category: "Percentage BOX"),
        TestConfigItem(id: "test-137", filename: "test-137-video-with-controls", displayName: "137: Video - With Controls", category: "Percentage BOX"),
        TestConfigItem(id: "test-138", filename: "test-138-9x16-video-button", displayName: "138: Video - 9:16+Button", category: "Percentage BOX"),
        TestConfigItem(id: "test-139", filename: "test-139-button-centered", displayName: "139: Button - Centered", category: "Percentage BOX"),
        TestConfigItem(id: "test-140", filename: "test-140-button-primary-secondary", displayName: "140: Button - Primary+Secondary", category: "Percentage BOX"),
        TestConfigItem(id: "test-141", filename: "test-141-button-size-variants", displayName: "141: Button - Size Variants", category: "Percentage BOX"),
        TestConfigItem(id: "test-142", filename: "test-142-cta-card", displayName: "142: CTA Card", category: "Percentage BOX"),
        TestConfigItem(id: "test-143", filename: "test-143-button-rounded-text", displayName: "143: Button - Rounded+Text", category: "Percentage BOX"),
        TestConfigItem(id: "test-144", filename: "test-144-rounded-box-text", displayName: "144: Rounded Box - Text", category: "Percentage BOX"),
        TestConfigItem(id: "test-145", filename: "test-145-nested-rounded-boxes", displayName: "145: Nested Rounded Boxes", category: "Percentage BOX"),
        TestConfigItem(id: "test-146", filename: "test-146-image-overlay-rounded", displayName: "146: Image + Overlay Rounded", category: "Percentage BOX"),
        TestConfigItem(id: "test-147", filename: "test-147-hero-banner-complex", displayName: "147: Hero Banner Complex", category: "Percentage BOX"),
        TestConfigItem(id: "test-148", filename: "test-148-product-card-complex", displayName: "148: Product Card Complex", category: "Percentage BOX"),
        TestConfigItem(id: "test-149", filename: "test-149-notification-card", displayName: "149: Notification Card", category: "Percentage BOX"),
        TestConfigItem(id: "test-150", filename: "test-150-dashboard-widget", displayName: "150: Dashboard Widget", category: "Percentage BOX"),
        TestConfigItem(id: "test-151", filename: "test-151-video-player-card", displayName: "151: Video Player Card", category: "Percentage BOX"),
        TestConfigItem(id: "test-152", filename: "test-152-text-corners", displayName: "152: Text Corners (Edge)", category: "Percentage BOX"),
        TestConfigItem(id: "test-153", filename: "test-153-image-clipped", displayName: "153: Image Clipped (Edge)", category: "Percentage BOX"),
        TestConfigItem(id: "test-154", filename: "test-154-nested-box-deep", displayName: "154: Nested BOX Deep (Edge)", category: "Percentage BOX"),
        TestConfigItem(id: "test-155", filename: "test-155-all-element-types", displayName: "155: All Element Types", category: "Percentage BOX"),
        TestConfigItem(id: "test-156", filename: "test-156-button-backgrounds", displayName: "156: Button Backgrounds", category: "Percentage BOX"),
    ]

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Top: Test config selector (30% of screen)
                    TestConfigListView(
                        testConfigs: testConfigs,
                        selectedConfig: $selectedTestConfig,
                        onConfigSelected: loadConfig
                    )
                    .frame(height: geometry.size.height * 0.3)

                    Divider()

                    // Bottom: Render area (70% of screen)
                    ConfigRenderView(
                        config: config,
                        isLoading: isLoading,
                        errorMessage: errorMessage,
                        availableHeight: geometry.size.height * 0.7
                    )
                }
            }
            .navigationTitle("🧪 Test Configs")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    /// Load the selected test configuration
    private func loadConfig(configId: String) {
        guard let testConfig = testConfigs.first(where: { $0.id == configId }) else {
            errorMessage = "Configuration not found: \(configId)"
            return
        }

        isLoading = true
        errorMessage = nil
        config = nil

        // Simulate async loading (in case of future network loading)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let loadedConfig = JsonLoader.loadTestConfig(filename: testConfig.filename) {
                self.config = loadedConfig
                self.errorMessage = nil
            } else {
                self.config = nil
                self.errorMessage = "Failed to load configuration: \(testConfig.filename)"
            }
            self.isLoading = false
        }
    }
}

// MARK: - Test Config List

/// Displays the list of test configurations
struct TestConfigListView: View {
    let testConfigs: [TestConfigItem]
    @Binding var selectedConfig: String?
    let onConfigSelected: (String) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Select a test configuration to render:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 8)

                ForEach(testConfigs) { config in
                    TestConfigButton(
                        config: config,
                        isSelected: selectedConfig == config.id,
                        onTap: {
                            selectedConfig = config.id
                            onConfigSelected(config.id)
                        }
                    )
                }
            }
            .padding(.bottom, 8)
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Test Config Button

/// Button for selecting a test configuration
struct TestConfigButton: View {
    let config: TestConfigItem
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(config.displayName)
                        .font(.body)
                        .foregroundColor(.primary)

                    Text(config.category)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
            .cornerRadius(8)
        }
        .padding(.horizontal)
        // Accessibility identifier for XCUITest
        .accessibilityIdentifier("test-config-\(config.id)")
    }
}

// MARK: - Config Render View

/// Displays the rendered configuration or loading/error states
struct ConfigRenderView: View {
    let config: ResolvedConfig?
    let isLoading: Bool
    let errorMessage: String?
    let availableHeight: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(.systemGroupedBackground)

            if isLoading {
                LoadingView()
                    .frame(height: availableHeight)
            } else if let errorMessage = errorMessage {
                ErrorVieww(message: errorMessage)
                    .frame(height: availableHeight)
            } else if let config = config {
                GeometryReader { geometry in
                    ScrollView {
                        NativeDisplayView(config: config)
                            .environment(\.nativeDisplayParentSize, CGSize(
                                width: geometry.size.width - 32,
                                height: geometry.size.height
                            ))
                            .padding(16)
                            // Accessibility identifier for XCUITest
                            .accessibilityIdentifier("native-display-view")
                    }
                }
                .frame(height: availableHeight)
            } else {
                PlaceholderView()
                    .frame(height: availableHeight)
            }
        }
    }
}

// MARK: - Supporting Views

/// Loading indicator view
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading configuration...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

/// Error display view
struct ErrorVieww: View {
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.red)

            Text("Error Loading Config")
                .font(.headline)

            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

/// Placeholder view when no config is selected
struct PlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.gray)

            Text("No Configuration Selected")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Select a test configuration from the list above to view its rendered output.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding()
    }
}

// MARK: - Preview

struct TestConfigBrowserView_Previews: PreviewProvider {
    static var previews: some View {
        TestConfigBrowserView()
    }
}
