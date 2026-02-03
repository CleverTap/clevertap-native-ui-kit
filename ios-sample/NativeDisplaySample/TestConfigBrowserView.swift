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
        )
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Top: Test config selector
                TestConfigListView(
                    testConfigs: testConfigs,
                    selectedConfig: $selectedTestConfig,
                    onConfigSelected: loadConfig
                )

                Divider()

                // Bottom: Render area
                ConfigRenderView(
                    config: config,
                    isLoading: isLoading,
                    errorMessage: errorMessage
                )
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
        .frame(height: 150)
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

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(.systemGroupedBackground)
                .edgesIgnoringSafeArea(.all)

            if isLoading {
                LoadingView()
            } else if let errorMessage = errorMessage {
                ErrorVieww(message: errorMessage)
            } else if let config = config {
                ScrollView {
                    NativeDisplayView(config: config)
                        .padding()
                        // Accessibility identifier for XCUITest
                        .accessibilityIdentifier("native-display-view")
                }
            } else {
                PlaceholderView()
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
