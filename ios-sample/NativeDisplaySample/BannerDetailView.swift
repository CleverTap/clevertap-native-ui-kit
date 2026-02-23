import SwiftUI
import CleverTapNativeDisplay

// MARK: - Data Models

/// Source of banner configuration
///
/// This enum distinguishes between two different sources of banner JSON:
/// - `.bundle(filename:)` - Pre-packaged JSON files in the app bundle
///   Example: .bundle(filename: "banner-01-hero-summer-sale")
///   The filename is resolved to a URL by searching multiple bundle paths
///
/// - `.file(url:)` - JSON files with known file system location
///   Example: .file(url: selectedFileURL)
///   Used when user uploads custom JSON via document picker
enum ConfigSource {
    case bundle(filename: String)
    case file(url: URL)

    /// Resolves the config source to a URL
    func resolveURL() -> URL? {
        switch self {
        case .bundle(let filename):
            return Self.findBundleURL(for: filename)
        case .file(let url):
            return url
        }
    }

    /// Find a bundled resource by trying multiple possible paths
    private static func findBundleURL(for filename: String) -> URL? {
        let possiblePaths: [String?] = [
            Bundle.main.path(forResource: filename, ofType: "json", inDirectory: "Banners"),
            Bundle.main.path(forResource: filename, ofType: "json", inDirectory: "Resources/Banners"),
            Bundle.main.path(forResource: filename, ofType: "json")
        ]

        for path in possiblePaths {
            if let validPath = path {
                print("✅ Found \(filename).json at: \(validPath)")
                return URL(fileURLWithPath: validPath)
            }
        }

        print("❌ Could not find \(filename).json in bundle")
        return nil
    }
}

/// Represents a logged interaction event
struct InteractionLog: Identifiable {
    let id = UUID()
    let timestamp: Date
    let nodeId: String?
    let interactionType: InteractionType?
    let actionData: String

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: timestamp)
    }

    var interactionTypeString: String {
        guard let interactionType = interactionType else {
            return "ACTION"
        }

        switch interactionType {
        case .click:
            return "CLICK"
        case .longPress:
            return "LONG_PRESS"
        case .doubleTap:
            return "DOUBLE_TAP"
        }
    }

    var iconName: String {
        guard let interactionType = interactionType else {
            return "bolt.fill"
        }

        switch interactionType {
        case .click:
            return "hand.tap.fill"
        case .longPress:
            return "hand.point.up.left.fill"
        case .doubleTap:
            return "hand.draw.fill"
        }
    }

    var color: Color {
        nodeId != nil ? .blue : .green
    }
}

// MARK: - Banner Detail View

/// Detail view displaying a banner with interaction logging
struct BannerDetailView: View {
    let bannerTitle: String
    let configSource: ConfigSource
    
    @StateObject private var viewModel = BannerDetailViewModel()
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Banner Display Area (70% of available space)
                ZStack {
                    Color(.systemGroupedBackground)
                    
                    Group {
                        if viewModel.isLoading {
                            LoadingIndicator()
                        } else if let error = viewModel.errorMessage {
                            ErrorDisplay(message: error) {
                                viewModel.loadConfig(from: configSource)
                            }
                        } else if let config = viewModel.config {
                            ScrollView {
                                NativeDisplayView(
                                    config: config,
                                    actionListener: viewModel.actionListener,
                                    componentListener: viewModel.componentListener
                                )
                                .padding(16)
                            }
                        }
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height * 0.7)
                
                Divider()
                
                // Interaction Log Area (30% of available space)
                InteractionLogView(logs: viewModel.interactionLogs)
                    .frame(width: geometry.size.width, height: geometry.size.height * 0.3)
            }
        }
        .navigationTitle(bannerTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    // View JSON button
                    NavigationLink(destination: viewModel.jsonString.map { jsonString in
                        JSONViewerView(jsonString: jsonString, title: "Banner JSON")
                    }) {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.blue)
                    }
                    .disabled(viewModel.jsonString == nil)

                    // Clear logs button
                    Button(action: {
                        viewModel.clearLogs()
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .disabled(viewModel.interactionLogs.isEmpty)
                }
            }
        }
        .onAppear {
            viewModel.loadConfig(from: configSource)
        }
    }
}

// MARK: - View Model

/// View model managing banner state and interaction logging
class BannerDetailViewModel: ObservableObject {
    @Published var config: ResolvedConfig?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var interactionLogs: [InteractionLog] = []
    @Published var jsonString: String?

    lazy var componentListener: BannerComponentListener = {
        BannerComponentListener { [weak self] log in
            self?.addLog(log)
        }
    }()

    lazy var actionListener: BannerActionListener = {
        BannerActionListener { [weak self] log in
            self?.addLog(log)
        }
    }()

    /// Load configuration from the given source
    func loadConfig(from source: ConfigSource) {
        isLoading = true
        errorMessage = nil
        config = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Resolve the source to a URL (works for both bundle and file)
            guard let url = source.resolveURL() else {
                self.config = nil
                self.errorMessage = "Failed to locate configuration file"
                self.isLoading = false
                return
            }

            // Load from the resolved URL
            self.loadFromURL(url)
        }
    }

    /// Unified method to load configuration from any URL.
    /// Handles security-scoped resources (e.g., files picked from the Files app)
    /// by acquiring access before reading and releasing it afterward.
    private func loadFromURL(_ url: URL) {
        // For files outside the app sandbox (e.g., from document picker),
        // we must re-acquire the security scope before reading.
        let needsSecurityScope = url.startAccessingSecurityScopedResource()
        defer {
            if needsSecurityScope {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let data = try Data(contentsOf: url)

            // Store JSON string for viewer
            if let jsonString = String(data: data, encoding: .utf8) {
                self.jsonString = jsonString
            }

            // Decode configuration
            let decoder = JSONDecoder()
            let loadedConfig = try decoder.decode(ResolvedConfig.self, from: data)
            self.config = loadedConfig
            self.errorMessage = nil
            print("✅ Successfully loaded config from: \(url.lastPathComponent)")
        } catch {
            self.config = nil
            self.errorMessage = "Failed to decode configuration:\n\n\(error.localizedDescription)"
            print("❌ Failed to decode config from \(url.lastPathComponent): \(error)")
        }

        self.isLoading = false
    }

    /// Add an interaction log
    func addLog(_ log: InteractionLog) {
        DispatchQueue.main.async {
            self.interactionLogs.insert(log, at: 0)
            print("📱 Banner Interaction: \(log.nodeId ?? "ERROR_ID") | \(log.interactionTypeString)")
        }
    }

    /// Clear all logs
    func clearLogs() {
        interactionLogs.removeAll()
    }
}

// MARK: - Component Listener

/// Component listener that logs ALL component interactions
class BannerComponentListener: NativeDisplayComponentListener {
    private let onLog: (InteractionLog) -> Void

    init(onLog: @escaping (InteractionLog) -> Void) {
        self.onLog = onLog
    }

    /// Listen to ALL components by returning nil
    func getInterestedNodeIds() -> Set<String>? {
        return nil
    }

    /// Log every interaction
    func onComponentInteraction(
        nodeId: String,
        interactionType: InteractionType,
        hasServerAction: Bool
    ) -> Bool {
        // Create log entry
        let actionText = hasServerAction ? "Has Server Action" : "No Server Action"
        let log = InteractionLog(
            timestamp: Date(),
            nodeId: nodeId,
            interactionType: interactionType,
            actionData: actionText
        )

        // Send to view model
        onLog(log)

        // Don't consume - let server actions proceed
        return false
    }
}

// MARK: - Action Listener

/// Action listener that logs ALL action executions
class BannerActionListener: NativeDisplayActionListener {
    private let onLog: (InteractionLog) -> Void

    init(onLog: @escaping (InteractionLog) -> Void) {
        self.onLog = onLog
    }

    func onCustomAction(key: String, value: Any?, metadata: [String: String]?) {
        let actionData = "Custom Action: \(key)\nValue: \(value ?? "nil")"
        let log = InteractionLog(
            timestamp: Date(),
            nodeId: nil,
            interactionType: nil,
            actionData: actionData
        )
        onLog(log)
        print("📱 Custom Action: key=\(key), value=\(value ?? "nil")")
    }

    func onNavigate(destination: String, params: [String: String]?) {
        let actionData = "Navigate: \(destination)\nParams: \(params ?? [:])"
        let log = InteractionLog(
            timestamp: Date(),
            nodeId: nil,
            interactionType: nil,
            actionData: actionData
        )
        onLog(log)
        print("📱 Navigate: destination=\(destination), params=\(params ?? [:])")
    }

    func onTrackEvent(eventName: String, properties: [String: Any]?) {
        let actionData = "Track Event: \(eventName)\nProperties: \(properties ?? [:])"
        let log = InteractionLog(
            timestamp: Date(),
            nodeId: nil,
            interactionType: nil,
            actionData: actionData
        )
        onLog(log)
        print("📱 Track Event: event=\(eventName), properties=\(properties ?? [:])")
    }

    func onOpenUrl(url: String, openInBrowser: Bool) -> Bool {
        let actionData = "Open URL: \(url)\nIn Browser: \(openInBrowser)"
        let log = InteractionLog(
            timestamp: Date(),
            nodeId: nil,
            interactionType: nil,
            actionData: actionData
        )
        onLog(log)
        print("📱 Open URL: url=\(url), openInBrowser=\(openInBrowser)")
        return false // Use default behavior
    }

    func onActionError(action: Action, error: Error) {
        let actionData = "Action Error: \(error.localizedDescription)\nAction: \(action)"
        let log = InteractionLog(
            timestamp: Date(),
            nodeId: nil,
            interactionType: nil,
            actionData: actionData
        )
        onLog(log)
        print("❌ Action Error: \(error.localizedDescription)")
    }
}

// MARK: - Interaction Log View

/// View displaying the list of interaction logs
struct InteractionLogView: View {
    let logs: [InteractionLog]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "list.bullet.rectangle")
                    .foregroundColor(.blue)
                Text("Interaction Log")
                    .font(.headline)
                Spacer()
                Text("\(logs.count) events")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))

            Divider()

            // Log list
            if logs.isEmpty {
                EmptyLogView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(logs) { log in
                            LogRowView(log: log)
                            if log.id != logs.last?.id {
                                Divider()
                                    .padding(.leading, 60)
                            }
                        }
                    }
                }
            }
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Log Row View

/// Individual row for an interaction log entry
struct LogRowView: View {
    let log: InteractionLog

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            Image(systemName: log.iconName)
                .foregroundColor(log.color)
                .frame(width: 24, height: 24)
                .padding(8)
                .background(
                    Circle()
                        .fill(log.color.opacity(0.1))
                )

            // Details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(log.interactionTypeString)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)

                    if log.nodeId == nil {
                        Text("ACTION EXECUTED")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.green)
                            )
                    }
                }

                if let nodeId = log.nodeId {
                    Text("Node: \(nodeId)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                // Action details
                Text(log.actionData)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(3)

                Text(log.formattedTime)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Empty Log View

/// View displayed when no logs are available
struct EmptyLogView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "hand.tap")
                .font(.system(size: 36))
                .foregroundColor(.gray)

            Text("No Interactions Yet")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Tap on banner components to see interaction logs appear here")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Loading Indicator

/// Loading indicator view
struct LoadingIndicator: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading banner...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Error Display

/// Error display view
struct ErrorDisplay: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.red)

            Text("Error Loading Banner")
                .font(.headline)

            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("Retry", action: onRetry)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue)
                )
                .foregroundColor(.white)
        }
        .padding()
    }
}

// MARK: - Preview

struct BannerDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BannerDetailView(
                bannerTitle: "🌞 Summer Sale",
                configSource: .bundle(filename: "banner-01-hero-summer-sale")
            )
        }
    }
}
