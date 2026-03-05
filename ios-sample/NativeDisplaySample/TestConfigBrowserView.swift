import SwiftUI
import CleverTapNativeDisplay

// MARK: - Main View

/// Test Configuration Browser - Sequential navigation through all test JSON configs
struct TestConfigBrowserView: View {
    @State private var testFiles: [String] = []
    @State private var currentIndex: Int = 0
    @State private var config: ResolvedConfig? = nil
    @State private var errorMessage: String? = nil
    @State private var isLoading: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            titleBar
            Divider()

            // Navigation row with prev/next
            navRow
            Divider()

            // Scrollable chip strip
            chipStrip
            Divider()

            // Rendered content area
            contentArea
        }
        .onAppear {
            testFiles = discoverTestFiles()
            if !testFiles.isEmpty {
                loadConfig()
            }
        }
    }

    // MARK: - Title Bar

    private var titleBar: some View {
        HStack {
            Text("Test Browser")
                .font(.headline)
            Spacer()
            if !testFiles.isEmpty {
                Text("\(String(format: "%03d", currentIndex + 1)) / \(testFiles.count)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(UIColor.systemBackground))
    }

    // MARK: - Navigation Row

    private var navRow: some View {
        HStack(spacing: 0) {
            Button(action: goToPrev) {
                Image(systemName: "chevron.left")
                    .imageScale(.medium)
                    .frame(width: 44, height: 44)
            }
            .disabled(testFiles.isEmpty)

            Text(testFiles.isEmpty ? "" : testFiles[currentIndex])
                .font(.system(size: 13))
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)

            Button(action: goToNext) {
                Image(systemName: "chevron.right")
                    .imageScale(.medium)
                    .frame(width: 44, height: 44)
            }
            .disabled(testFiles.isEmpty)
        }
        .background(Color(UIColor.secondarySystemBackground))
    }

    // MARK: - Chip Strip

    private var chipStrip: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(testFiles.indices, id: \.self) { i in
                        let label = extractNumber(from: testFiles[i])
                        let isSelected = i == currentIndex
                        Text(label)
                            .font(.system(size: 11, weight: isSelected ? .semibold : .regular, design: .monospaced))
                            .foregroundColor(isSelected ? .white : .primary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(isSelected ? Color.blue : Color(UIColor.tertiarySystemBackground))
                            .cornerRadius(4)
                            .id(i)
                            .onTapGesture { jumpTo(i) }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            }
            .onChange(of: currentIndex) { newIndex in
                withAnimation {
                    proxy.scrollTo(max(0, newIndex - 4), anchor: .leading)
                }
            }
        }
    }

    // MARK: - Content Area

    private var contentArea: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)

            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            } else if let errorMessage = errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            } else if let config = config {
                GeometryReader { geometry in
                    ScrollView {
                        NativeDisplayView(config: config)
                            .environment(\.nativeDisplayParentSize, CGSize(
                                width: geometry.size.width - 32,
                                height: geometry.size.height
                            ))
                            .padding(16)
                            .accessibilityIdentifier("native-display-view")
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("No test files found in bundle")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Navigation

    private func goToPrev() {
        guard !testFiles.isEmpty else { return }
        currentIndex = currentIndex == 0 ? testFiles.count - 1 : currentIndex - 1
        loadConfig()
    }

    private func goToNext() {
        guard !testFiles.isEmpty else { return }
        currentIndex = currentIndex == testFiles.count - 1 ? 0 : currentIndex + 1
        loadConfig()
    }

    private func jumpTo(_ index: Int) {
        guard index >= 0, index < testFiles.count else { return }
        currentIndex = index
        loadConfig()
    }

    private func loadConfig() {
        guard !testFiles.isEmpty else { return }
        let filename = testFiles[currentIndex]
        isLoading = true
        errorMessage = nil
        config = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            if let loadedConfig = JsonLoader.loadTestConfig(filename: filename) {
                self.config = loadedConfig
            } else {
                self.errorMessage = "Failed to load: \(filename).json"
            }
            self.isLoading = false
        }
    }

    // MARK: - Helpers

    /// Discover all test-NNN-*.json files present in the TestConfigs bundle directory
    private func discoverTestFiles() -> [String] {
        guard let resourcePath = Bundle.main.resourcePath else { return [] }
        let testConfigsPath = (resourcePath as NSString).appendingPathComponent("TestConfigs")
        let fileManager = FileManager.default

        guard let files = try? fileManager.contentsOfDirectory(atPath: testConfigsPath) else {
            return []
        }

        return files
            .filter { $0.hasPrefix("test-") && $0.hasSuffix(".json") }
            .sorted()
            .map { $0.replacingOccurrences(of: ".json", with: "") }
    }

    /// Extract the numeric portion from a filename like "test-121-some-description" -> "121"
    private func extractNumber(from filename: String) -> String {
        let parts = filename.split(separator: "-")
        guard parts.count >= 2 else { return "???" }
        return String(parts[1])
    }
}

// MARK: - Preview

struct TestConfigBrowserView_Previews: PreviewProvider {
    static var previews: some View {
        TestConfigBrowserView()
    }
}
