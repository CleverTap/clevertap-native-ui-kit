import SwiftUI
import CleverTapNativeDisplay

// MARK: - CleverTap Integration Demo

/// Demonstrates how a real CleverTap Core SDK integration would work
/// with the Native Display SDK, including system event tracking.
///
/// Since the sample app has no real CleverTap Core SDK, this demo uses
/// `processDisplayUnits(_:)` with hardcoded JSON and implements
/// `NativeDisplayActionListener` to show how system events (Notification Viewed,
/// Notification Clicked) flow through the action handler.
struct CleverTapIntegrationView: View {
    @StateObject private var viewModel = CleverTapIntegrationViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Section 1: CleverTap Setup
                setupSection

                // Section 2: Fetch & Render
                fetchRenderSection

                // Section 3: System Events
                systemEventsSection

                // Section 4: Rendered Units
                renderedUnitsSection

                // Section 5: Event Log
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

    // MARK: - Setup Section

    private var setupSection: some View {
        SectionCard(title: "CleverTap Setup", icon: "gearshape.2") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Initialize CleverTap and bind the Native Display bridge in your AppDelegate or app startup.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                CodeSnippetView(
                    label: "Step 1: Initialize CleverTap",
                    code: """
                    // In AppDelegate
                    CleverTap.autoIntegrate()
                    let clevertap = CleverTap.sharedInstance()
                    """
                )

                CodeSnippetView(
                    label: "Step 2: Bind the bridge",
                    code: """
                    let bridge = NativeDisplayBridge.shared
                    bridge.addListener(self)
                    bridge.bind(clevertap)
                    """
                )

                CodeSnippetView(
                    label: "Step 3: Set action listener for events",
                    code: """
                    // In your ViewController or ViewModel
                    NativeDisplayView(
                        config: unit.config,
                        actionListener: self
                    )
                    """
                )
            }
        }
    }

    // MARK: - Fetch & Render Section

    private var fetchRenderSection: some View {
        SectionCard(title: "Fetch & Render", icon: "arrow.triangle.2.circlepath") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Simulate fetching Native Displays from the server via the bridge. Units arrive through the listener callback.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Button(action: { viewModel.fetchAndRender() }) {
                    Label("Fetch Native Displays", systemImage: "arrow.down.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button(action: { viewModel.clearAll() }) {
                    Label("Clear All", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
    }

    // MARK: - System Events Section

    private var systemEventsSection: some View {
        SectionCard(title: "System Events", icon: "bell.badge") {
            VStack(alignment: .leading, spacing: 12) {
                Text("When the SDK renders a unit, it fires system events via `NativeDisplayActionListener.onTrackEvent`. Tap a rendered unit's button to see \"Notification Clicked\" events in the log below.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                CodeSnippetView(
                    label: "Action listener receives system events",
                    code: """
                    func onTrackEvent(
                        eventName: String,
                        properties: [String: Any]?
                    ) {
                        // Forward to CleverTap
                        clevertap.recordEvent(
                            eventName,
                            withProps: properties
                        )
                    }
                    """
                )

                HStack(spacing: 8) {
                    Circle()
                        .fill(viewModel.displayUnits.isEmpty ? Color.gray : Color.green)
                        .frame(width: 8, height: 8)
                    Text(viewModel.displayUnits.isEmpty
                         ? "Fetch units first, then interact to see events"
                         : "Action listener active - interact with rendered units")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Rendered Units Section

    private var renderedUnitsSection: some View {
        SectionCard(title: "Rendered Units (\(viewModel.displayUnits.count))", icon: "rectangle.on.rectangle") {
            if viewModel.displayUnits.isEmpty {
                HStack {
                    Image(systemName: "tray")
                        .foregroundColor(.secondary)
                    Text("No units yet. Tap \"Fetch Native Displays\" above.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                VStack(spacing: 16) {
                    ForEach(viewModel.displayUnits, id: \.unitId) { unit in
                        VStack(alignment: .leading, spacing: 8) {
                            // Unit metadata header
                            HStack {
                                Label(unit.unitId, systemImage: "tag")
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundColor(.blue)
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

                            // Rendered NativeDisplayView with action listener
                            NativeDisplayView(
                                config: unit.config,
                                actionListener: viewModel
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: 380)
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

    // MARK: - Event Log Section

    private var eventLogSection: some View {
        SectionCard(title: "Event Log", icon: "doc.text") {
            VStack(alignment: .leading, spacing: 4) {
                if viewModel.eventLog.isEmpty {
                    Text("Events will appear here as you interact with units.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                } else {
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

/// Manages bridge interaction and action listener state for the CleverTap integration demo.
/// Implements both NativeDisplayBridgeListener (to receive units) and
/// NativeDisplayActionListener (to capture system events like Notification Viewed/Clicked).
class CleverTapIntegrationViewModel: NSObject, ObservableObject, NativeDisplayBridgeListener, NativeDisplayActionListener {
    @Published var displayUnits: [NativeDisplayUnit] = []
    @Published var eventLog: [String] = []

    private let bridge = NativeDisplayBridge.shared

    override init() {
        super.init()
        bridge.addListener(self)
        log("Bridge listener registered")
        log("Action listener ready for system events")
    }

    // MARK: - NativeDisplayBridgeListener

    func onNativeDisplaysLoaded(_ units: [NativeDisplayUnit]) {
        displayUnits = units
        log("onNativeDisplaysLoaded: received \(units.count) unit(s)")
        for unit in units {
            log("  - unitId: \(unit.unitId)")
        }
    }

    // MARK: - NativeDisplayActionListener

    @discardableResult
    func onOpenUrl(url: String, openInBrowser: Bool) -> Bool {
        log("ACTION onOpenUrl: \(url) (browser: \(openInBrowser))")
        // In a real app, you might open in SFSafariViewController or UIApplication.open
        return true // Consumed
    }

    func onCustomAction(key: String, value: Any?, metadata: [String: String]?) {
        let valueStr = value.map { "\($0)" } ?? "nil"
        let metaStr = metadata.map { "\($0)" } ?? "nil"
        log("ACTION onCustomAction: key=\(key), value=\(valueStr), meta=\(metaStr)")
    }

    func onNavigate(destination: String, params: [String: String]?) {
        let paramsStr = params.map { "\($0)" } ?? "nil"
        log("ACTION onNavigate: destination=\(destination), params=\(paramsStr)")
    }

    func onTrackEvent(eventName: String, properties: [String: Any]?) {
        let propsStr = properties.map { dict in
            dict.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
        } ?? "none"
        log("EVENT \(eventName): [\(propsStr)]")
        // In a real app: CleverTap.sharedInstance()?.recordEvent(eventName, withProps: properties)
    }

    func onActionError(action: Action, error: Error) {
        log("ERROR action failed: \(error.localizedDescription)")
    }

    // MARK: - Actions

    func fetchAndRender() {
        log("Simulating fetch from CleverTap server...")
        bridge.processDisplayUnits([
            CTMockDisplayUnits.productCard,
            CTMockDisplayUnits.notification
        ])
    }

    func clearAll() {
        bridge.clear()
        displayUnits = []
        log("Cleared all units. Re-registering listener...")
        bridge.addListener(self)
    }

    // MARK: - Teardown

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

// MARK: - Mock Display Unit JSON (CleverTap format)

/// Hardcoded display unit JSON strings matching the CleverTap server format.
/// Reuses the same structure as BridgeIntegrationView's mocks.
private enum CTMockDisplayUnits {

    static let productCard: String = """
    {
      "wzrk_id": "ct_campaign_1",
      "type": "native_display",
      "native_display_config": {
        "theme": {
          "id": "product-card",
          "defaultStyle": {
            "textColor": "#1F2937",
            "fontSize": 14,
            "lineHeight": 20
          }
        },
        "root": {
          "type": "container",
          "id": "card",
          "containerType": "vertical",
          "layout": {
            "width": { "value": 100, "unit": "percent" },
            "height": { "value": -2, "unit": "dp" },
            "padding": { "all": 16 },
            "arrangement": { "type": "spaced", "spacing": 8 }
          },
          "style": {
            "backgroundColor": "#FFFFFF",
            "borderRadius": 16,
            "shadowRadius": 8,
            "shadowColor": "#000000",
            "shadowOpacity": 0.1,
            "shadowOffsetY": 4
          },
          "children": [
            {
              "type": "element",
              "id": "product-image",
              "elementType": "image",
              "bindings": {
                "url": "https://yavuzceliker.github.io/sample-images/image-83.jpg"
              },
              "layout": {
                "width": { "value": 100, "unit": "percent" },
                "height": { "value": 180, "unit": "dp" }
              },
              "style": { "borderRadius": 12 }
            },
            {
              "type": "element",
              "id": "product-name",
              "elementType": "text",
              "bindings": { "text": "Premium Wireless Headphones" },
              "layout": {
                "width": { "value": 100, "unit": "percent" },
                "height": { "value": -2, "unit": "dp" }
              },
              "style": {
                "fontSize": 18,
                "fontWeight": "bold",
                "textColor": "#111827",
                "lineHeight": 24
              }
            },
            {
              "type": "element",
              "id": "product-price",
              "elementType": "text",
              "bindings": { "text": "$299.99" },
              "layout": {
                "width": { "value": 100, "unit": "percent" },
                "height": { "value": -2, "unit": "dp" }
              },
              "style": {
                "fontSize": 22,
                "fontWeight": "bold",
                "textColor": "#10B981",
                "lineHeight": 30
              }
            },
            {
              "type": "element",
              "id": "buy-button",
              "elementType": "button",
              "bindings": { "text": "Add to Cart" },
              "layout": {
                "width": { "value": 100, "unit": "percent" },
                "height": { "value": 48, "unit": "dp" }
              },
              "style": {
                "backgroundColor": "#3B82F6",
                "borderRadius": 12,
                "textColor": "#FFFFFF",
                "fontSize": 16,
                "fontWeight": "bold",
                "lineHeight": 22
              },
              "actions": {
                "onClick": {
                  "type": "custom",
                  "key": "add_to_cart",
                  "value": "headphones_001"
                }
              }
            }
          ]
        },
        "styleClasses": [],
        "variables": {}
      },
      "custom_kv": {
        "campaign": "summer_sale",
        "category": "electronics"
      }
    }
    """

    static let notification: String = """
    {
      "wzrk_id": "ct_campaign_2",
      "type": "native_display",
      "native_display_config": {
        "theme": {
          "id": "notification",
          "defaultStyle": {
            "textColor": "#1F2937",
            "fontSize": 14,
            "lineHeight": 20
          }
        },
        "root": {
          "type": "container",
          "id": "notif-card",
          "containerType": "horizontal",
          "layout": {
            "width": { "value": 100, "unit": "percent" },
            "height": { "value": -2, "unit": "dp" },
            "padding": { "all": 16 },
            "arrangement": { "type": "spaced", "spacing": 12 }
          },
          "style": {
            "backgroundColor": "#EFF6FF",
            "borderRadius": 12,
            "borderWidth": 1,
            "borderColor": "#BFDBFE"
          },
          "children": [
            {
              "type": "element",
              "id": "notif-icon",
              "elementType": "image",
              "bindings": {
                "url": "https://yavuzceliker.github.io/sample-images/image-10.jpg"
              },
              "layout": {
                "width": { "value": 48, "unit": "dp" },
                "height": { "value": 48, "unit": "dp" }
              },
              "style": { "borderRadius": 24 }
            },
            {
              "type": "container",
              "id": "notif-text-group",
              "containerType": "vertical",
              "layout": {
                "width": { "value": -1, "unit": "dp" },
                "height": { "value": -2, "unit": "dp" },
                "arrangement": { "type": "spaced", "spacing": 4 }
              },
              "children": [
                {
                  "type": "element",
                  "id": "notif-title",
                  "elementType": "text",
                  "bindings": { "text": "New offer available!" },
                  "layout": {
                    "width": { "value": 100, "unit": "percent" },
                    "height": { "value": -2, "unit": "dp" }
                  },
                  "style": {
                    "fontSize": 16,
                    "fontWeight": "semibold",
                    "textColor": "#1E40AF",
                    "lineHeight": 22
                  }
                },
                {
                  "type": "element",
                  "id": "notif-body",
                  "elementType": "text",
                  "bindings": { "text": "Get 20% off your next purchase. Limited time only." },
                  "layout": {
                    "width": { "value": 100, "unit": "percent" },
                    "height": { "value": -2, "unit": "dp" }
                  },
                  "style": {
                    "fontSize": 14,
                    "textColor": "#3B82F6",
                    "lineHeight": 20
                  }
                }
              ]
            }
          ]
        },
        "styleClasses": [],
        "variables": {}
      },
      "custom_kv": {
        "campaign": "retention_offer",
        "discount": "20"
      }
    }
    """
}

// MARK: - Supporting Views (reuse SectionCard and CodeSnippetView from BridgeIntegrationView)
// Note: SectionCard and CodeSnippetView are defined as private in BridgeIntegrationView.swift,
// so we redefine them here with the same appearance. If these were shared across multiple screens,
// they should be extracted to a shared file.

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

private struct CodeSnippetView: View {
    let label: String
    let code: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.blue)

            Text(code)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.primary)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        CleverTapIntegrationView()
    }
}
