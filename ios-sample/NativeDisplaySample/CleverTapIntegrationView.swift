import SwiftUI
import CleverTapNativeDisplay
import CleverTapSDK

// MARK: - CleverTap Integration

/// Real CleverTap integration screen. Binds the Native Display bridge to a live
/// CleverTap instance and renders server-driven units as they arrive.
struct CleverTapIntegrationView: View {
    @StateObject private var viewModel = CleverTapIntegrationViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                fireEventSection
                displayCanvasSection
                eventLogSection
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("CleverTap Integration")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            viewModel.tearDown()
        }
    }

    // MARK: - Fire Event

    private var fireEventSection: some View {
        SectionCard(title: "Fire Event", icon: "paperplane") {
            HStack(spacing: 12) {
                TextField("Enter event name", text: $viewModel.eventName)
                    .textFieldStyle(.roundedBorder)

                Button("Send Event") {
                    viewModel.sendEvent()
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.eventName.trimmingCharacters(in: .whitespaces).isEmpty
                          || !viewModel.cleverTapAvailable)
            }
        }
    }

    // MARK: - Display Canvas

    private var displayCanvasSection: some View {
        SectionCard(title: "Native Displays (\(viewModel.displayUnits.count))", icon: "rectangle.on.rectangle") {
            if viewModel.displayUnits.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "tray")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("Waiting for Native Display response...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 32)
            } else {
                VStack(spacing: 16) {
                    ForEach(viewModel.displayUnits, id: \.unitId) { unit in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label(unit.unitId, systemImage: "tag")
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundColor(.blue)
                                    .lineLimit(1)
                                Spacer()
                                if !unit.customExtras.isEmpty {
                                    Text("\(unit.customExtras.count) extras")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color(.systemGray5))
                                        .cornerRadius(4)
                                }
                            }

                            NativeDisplayView(
                                config: unit.config,
                                actionListener: viewModel
                            )
                            .frame(maxWidth: .infinity)
                            .cornerRadius(12)
                            .clipped()
                        }
                        .padding(12)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }
                }
            }
        }
    }

    // MARK: - Event Log

    private var eventLogSection: some View {
        SectionCard(title: "Event Log", icon: "doc.text") {
            if viewModel.eventLog.isEmpty {
                Text("Events will appear here.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(viewModel.eventLog.indices, id: \.self) { index in
                        Text(viewModel.eventLog[index])
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
}

// MARK: - View Model

class CleverTapIntegrationViewModel: NSObject, ObservableObject, NativeDisplayBridgeListener, NativeDisplayActionListener {
    @Published var displayUnits: [NativeDisplayUnit] = []
    @Published var eventLog: [String] = []
    @Published var eventName: String = ""
    @Published private(set) var cleverTapAvailable = false
    @Published private(set) var bridgeBound = false
    
    private let bridge = NativeDisplayBridge.shared
    private var cleverTapInstance: CleverTap?
    
    override init() {
        super.init()
        
        // Get CleverTap shared instance
        cleverTapInstance = CleverTap.sharedInstance()
        cleverTapAvailable = cleverTapInstance != nil
        
        if cleverTapAvailable {
            log("CleverTap instance found")
        } else {
            log("CleverTap not configured — check Info.plist credentials")
        }
        
        // Register bridge listener
        bridge.addListener(self)
        log("Bridge listener registered")
        
        // Bind bridge to CleverTap
        if let ct = cleverTapInstance {
            let didBind = bridge.bind(ct)
            bridgeBound = didBind
            log(didBind ? "Bridge bound to CleverTap" : "Bridge bind failed")
            
            // Fetch Native Displays from server
            let didFetch = bridge.fetchNativeDisplays(ct)
            log(didFetch ? "Fetch request sent" : "Fetch request failed")
        }
    }
    
    // MARK: - NativeDisplayBridgeListener
    
    func onNativeDisplaysLoaded(_ units: [NativeDisplayUnit]) {
        displayUnits = units
        log("Received \(units.count) display unit(s)")
        for unit in units {
            log("  unit: \(unit.unitId)")
        }
    }
    
    // MARK: - NativeDisplayActionListener
    
    @discardableResult
    func onOpenUrl(url: String, openInBrowser: Bool) -> Bool {
        log("ACTION openUrl: \(url)")
        if let parsedUrl = URL(string: url) {
            UIApplication.shared.open(parsedUrl)
        }
        return true
    }
    
    func onCustomAction(key: String, value: Any?, metadata: [String: String]?) {
        let valueStr = value.map { "\($0)" } ?? "nil"
        log("ACTION custom: \(key) = \(valueStr)")
    }
    
    func onNavigate(destination: String, params: [String: String]?) {
        log("ACTION navigate: \(destination)")
    }
    
    func onTrackEvent(eventName: String, properties: [String: Any]?) {
        let propsStr = properties.map { dict in
            dict.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
        } ?? ""
        log("EVENT \(eventName)\(propsStr.isEmpty ? "" : " [\(propsStr)]")")
        
        // Forward system events to CleverTap
        cleverTapInstance?.recordEvent(eventName, withProps: properties ?? [:])
        
        
        func onActionError(action: Action, error: Error) {
            log("ERROR: \(error.localizedDescription)")
        }
        
        // MARK: - Actions
        
        func sendEvent() {
            let name = eventName.trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty else { return }
            cleverTapInstance?.recordEvent(name)
            log("Sent event: \(name)")
            eventName = ""
        }
        
        func tearDown() {
            bridge.removeListener(self)
            log("Listener removed")
        }
        
        // MARK: - Private
        
        private func log(_ message: String) {
            let timestamp = Self.timeFormatter.string(from: Date())
            let entry = "[\(timestamp)] \(message)"
            if Thread.isMainThread {
                eventLog.insert(entry, at: 0)
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.eventLog.insert(entry, at: 0)
                }
            }
        }
        
        private static let timeFormatter: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "HH:mm:ss.SSS"
            return f
        }()
    }
    
    // MARK: - Supporting Views
    
    private struct SectionCard<Content: View>: View {
        let title: String
        let icon: String
        @ViewBuilder let content: Content
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .foregroundColor(.blue)
                        .font(.system(size: 16, weight: .semibold))
                    Text(title)
                        .font(.headline)
                }
                content
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Preview
    
    #Preview {
        NavigationView {
            CleverTapIntegrationView()
        }
    }
}
