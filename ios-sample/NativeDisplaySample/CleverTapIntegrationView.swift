import SwiftUI
import CleverTapNativeDisplay
import CleverTapSDK

// MARK: - CleverTap Integration

/// Real CleverTap integration screen. Binds the Native Display bridge to a live
/// CleverTap instance and renders server-driven units as they arrive.
struct CleverTapIntegrationView: View {
    @StateObject private var viewModel = CleverTapIntegrationViewModel()
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var eventLogVisible = true
    @FocusState private var eventInputFocused: Bool

    var body: some View {
        Group {
            if verticalSizeClass == .compact {
                landscapeLayout
            } else {
                portraitLayout
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("CleverTap Integration")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.setUp()
        }
        .onDisappear {
            viewModel.tearDown()
        }
    }

    // MARK: - Layout Variants

    private var portraitLayout: some View {
        VStack(spacing: 0) {
            fireEventSection
            Divider()
            displayCanvasSection
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Divider()
            eventLogSection
        }
    }

    private var landscapeLayout: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                // Left panel (33%): event input + event log
                VStack(spacing: 0) {
                    fireEventSection
                    Divider()
                    eventLogSection
                }
                .frame(width: geo.size.width * 0.33, height: geo.size.height)

                Divider()

                // Right panel (67%): canvas at full height.
                // nativeDisplayParentSize is set once here so the SDK skips its
                // internal GeometryReader — prevents each unit from sizing itself
                // to the full panel height and appearing to overlap.
                displayCanvasSection
                    .environment(\.nativeDisplayParentSize, CGSize(
                        width: geo.size.width * 0.67,
                        height: geo.size.height
                    ))
                    .frame(width: geo.size.width * 0.67, height: geo.size.height)
                    .clipped()
            }
        }
    }

    // MARK: - Fire Event

    private var fireEventSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                TextField("Enter event name", text: $viewModel.eventName)
                    .textFieldStyle(.roundedBorder)
                    .focused($eventInputFocused)
                    .submitLabel(.send)
                    .onSubmit { sendEventAndDismissKeyboard() }
                    .accessibilityIdentifier("ct-event-input")

                Button("Send Event") {
                    sendEventAndDismissKeyboard()
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.eventName.trimmingCharacters(in: .whitespaces).isEmpty
                          || !viewModel.cleverTapAvailable)
                .accessibilityIdentifier("ct-send-event-btn")
            }

            if verticalSizeClass != .compact {
                Text("Native Display Canvas")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
        }
        .padding(10)
    }

    // MARK: - Display Canvas

    private var displayCanvasSection: some View {
        Group {
            if viewModel.displayUnits.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("Waiting for Native Display response...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityIdentifier("ct-waiting-canvas")
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(viewModel.displayUnits, id: \.unitId) { unit in
                            NativeDisplayView(
                                unit: unit,
                                actionListener: viewModel
                            )
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 10)
                }
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("ct-display-canvas")
            }
        }
    }

    // MARK: - Event Log

    private var eventLogSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "doc.text")
                        .foregroundColor(.blue)
                        .font(.system(size: 14, weight: .semibold))
                    Text("Event Log")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                Spacer()
                if eventLogVisible && !viewModel.eventLog.isEmpty {
                    Button("Clear") {
                        viewModel.eventLog.removeAll()
                    }
                    .font(.system(size: 12))
                }
                Button {
                    eventLogVisible.toggle()
                } label: {
                    Image(systemName: eventLogVisible ? "eye.slash" : "eye")
                        .font(.system(size: 14, weight: .semibold))
                }
                .accessibilityIdentifier("event-log-toggle")
            }

            if eventLogVisible {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 2) {
                            if viewModel.eventLog.isEmpty {
                                Text("No events yet")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(Color(.systemGray))
                            } else {
                                ForEach(viewModel.eventLog.indices, id: \.self) { index in
                                    Text(viewModel.eventLog[index])
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(logColor(for: viewModel.eventLog[index]))
                                        .id(index)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                    }
                    .onChange(of: viewModel.eventLog.count) { _ in
                        if let last = viewModel.eventLog.indices.last {
                            proxy.scrollTo(last)
                        }
                    }
                }
                .frame(minHeight: 80, maxHeight: verticalSizeClass == .compact ? .infinity : 160)
                .background(Color(red: 0.15, green: 0.19, blue: 0.22))
                .cornerRadius(8)
                .accessibilityIdentifier("event-log-content")
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    /// Fires the event via the view model and immediately resigns first
    /// responder on the text field. Tied to both the Send button tap and
    /// the keyboard return key (`.submitLabel(.send)`).
    private func sendEventAndDismissKeyboard() {
        viewModel.sendEvent()
        eventInputFocused = false
    }

    private func logColor(for message: String) -> Color {
        if message.contains("EVENT") { return Color(red: 1, green: 0.84, blue: 0.31) }
        if message.contains("ACTION") { return Color(red: 0.51, green: 0.83, blue: 0.98) }
        if message.contains("ERROR") { return Color(red: 0.94, green: 0.6, blue: 0.6) }
        if message.contains("Received") { return Color(red: 0.65, green: 0.84, blue: 0.65) }
        return Color(red: 0.5, green: 0.8, blue: 0.77)
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

        // Bridge is initialized, bound, and fetch requested in NativeDisplaySampleApp.
        // This view model only registers its listener to observe display units.
        cleverTapInstance = CleverTap.sharedInstance()
        cleverTapAvailable = cleverTapInstance != nil

        if cleverTapAvailable {
            log("CleverTap instance found")
        } else {
            log("CleverTap not configured — check Info.plist credentials")
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
    }

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

    func setUp() {
        bridge.addListener(self)
        log("Bridge listener registered")
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

// MARK: - Preview

#Preview {
    NavigationView {
        CleverTapIntegrationView()
    }
}
