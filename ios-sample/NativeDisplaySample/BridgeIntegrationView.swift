import SwiftUI
import CleverTapNativeDisplay

// MARK: - Bridge Integration Demo

/// Demonstrates how clients integrate with NativeDisplayBridge.
///
/// Since the sample app has no real CleverTap Core SDK, this demo uses
/// `processDisplayUnits(_:)` with hardcoded JSON to simulate the bridge flow.
/// It covers:
/// - Bridge initialization (bind vs manual)
/// - Listener registration via NativeDisplayBridgeListener
/// - Rendering received NativeDisplayUnit configs
/// - Pull API (getAllNativeDisplays / getNativeDisplayForId)
struct BridgeIntegrationView: View {
    @StateObject private var viewModel = BridgeIntegrationViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Section 1: Integration Mode
                integrationModeSection

                // Section 2: Simulate Server Response
                simulateSection

                // Section 3: Pull API
                pullAPISection

                // Section 4: Rendered Units
                renderedUnitsSection

                // Section 5: Event Log
                eventLogSection
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Bridge Integration")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            viewModel.tearDown()
        }
    }

    // MARK: - Integration Mode Section

    private var integrationModeSection: some View {
        SectionCard(title: "Integration Mode", icon: "link") {
            VStack(alignment: .leading, spacing: 12) {
                Text("In a real app, choose one approach:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                CodeSnippetView(
                    label: "Option 1: bind() (recommended)",
                    code: """
                    let bridge = NativeDisplayBridge.shared
                    bridge.addListener(self)
                    bridge.bind(CleverTap.sharedInstance())
                    """
                )

                CodeSnippetView(
                    label: "Option 2: Auto-detect",
                    code: """
                    NativeDisplayBridge.shared.initialize()
                    NativeDisplayBridge.shared.addListener(self)
                    """
                )

                CodeSnippetView(
                    label: "Option 3: Manual JSON (used in this demo)",
                    code: """
                    let bridge = NativeDisplayBridge.shared
                    bridge.addListener(self)
                    bridge.processDisplayUnits(jsonStrings)
                    """
                )
            }
        }
    }

    // MARK: - Simulate Section

    private var simulateSection: some View {
        SectionCard(title: "Simulate Server Response", icon: "arrow.down.circle") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Tap a button to feed mock display unit JSON into the bridge, simulating what the CleverTap Core SDK would deliver.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(spacing: 12) {
                    Button(action: { viewModel.simulateSingleUnit() }) {
                        Label("1 Unit", systemImage: "square")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button(action: { viewModel.simulateMultipleUnits() }) {
                        Label("3 Units", systemImage: "square.stack.3d.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }

                Button(action: { viewModel.clearBridge() }) {
                    Label("Clear All", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
    }

    // MARK: - Pull API Section

    private var pullAPISection: some View {
        SectionCard(title: "Pull API", icon: "arrow.down.doc") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Fetch cached units on demand, without waiting for listener callbacks.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(spacing: 12) {
                    Button(action: { viewModel.fetchAllUnits() }) {
                        Label("getAllNativeDisplays()", systemImage: "list.bullet")
                            .font(.system(size: 13, design: .monospaced))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                HStack(spacing: 12) {
                    TextField("Unit ID", text: $viewModel.lookupUnitId)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 14, design: .monospaced))

                    Button(action: { viewModel.fetchUnitById() }) {
                        Label("Get", systemImage: "magnifyingglass")
                    }
                    .buttonStyle(.bordered)
                }

                if let pullResult = viewModel.pullAPIResult {
                    Text(pullResult)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.secondary)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(6)
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
                    Text("No units yet. Tap \"Simulate\" above.")
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

                            // Custom extras
                            if !unit.customExtras.isEmpty {
                                VStack(alignment: .leading, spacing: 2) {
                                    ForEach(unit.customExtras.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                        Text("\(key): \(value)")
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }

                            // Rendered NativeDisplayView
                            NativeDisplayView(config: unit.config)
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
                    Text("Events will appear here as the bridge processes units.")
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

/// Manages bridge interaction and state for the demo.
/// Implements NativeDisplayBridgeListener to receive push updates.
class BridgeIntegrationViewModel: ObservableObject, NativeDisplayBridgeListener {
    @Published var displayUnits: [NativeDisplayUnit] = []
    @Published var eventLog: [String] = []
    @Published var pullAPIResult: String?
    @Published var lookupUnitId: String = "demo_unit_1"

    private let bridge = NativeDisplayBridge.shared

    init() {
        bridge.addListener(self)
        log("Listener registered on NativeDisplayBridge.shared")
    }

    // MARK: - NativeDisplayBridgeListener

    func onNativeDisplaysLoaded(_ units: [NativeDisplayUnit]) {
        displayUnits = units
        log("onNativeDisplaysLoaded: received \(units.count) unit(s)")
        for unit in units {
            log("  - unitId: \(unit.unitId), extras: \(unit.customExtras)")
        }
    }

    // MARK: - Simulate Actions

    func simulateSingleUnit() {
        log("Calling processDisplayUnits with 1 mock unit...")
        bridge.processDisplayUnits([MockDisplayUnits.productCard])
    }

    func simulateMultipleUnits() {
        log("Calling processDisplayUnits with 3 mock units...")
        bridge.processDisplayUnits([
            MockDisplayUnits.productCard,
            MockDisplayUnits.notification,
            MockDisplayUnits.statsCard
        ])
    }

    func clearBridge() {
        bridge.clear()
        displayUnits = []
        pullAPIResult = nil
        log("Bridge cleared. Re-registering listener...")
        bridge.addListener(self)
    }

    // MARK: - Pull API Actions

    func fetchAllUnits() {
        let units = bridge.getAllNativeDisplays()
        pullAPIResult = "getAllNativeDisplays() returned \(units.count) unit(s): [\(units.map { $0.unitId }.joined(separator: ", "))]"
        log("Pull API: \(pullAPIResult ?? "")")
    }

    func fetchUnitById() {
        let id = lookupUnitId.trimmingCharacters(in: .whitespaces)
        if let unit = bridge.getNativeDisplayForId(id) {
            pullAPIResult = "Found unit '\(unit.unitId)' with \(unit.customExtras.count) custom extras"
        } else {
            pullAPIResult = "No unit found for id '\(id)'"
        }
        log("Pull API: \(pullAPIResult ?? "")")
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
        // Ensure main-thread update since bridge calls back on main
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

// MARK: - Mock Display Unit JSON

/// Hardcoded display unit JSON strings that wrap ResolvedConfig inside
/// the `native_display_config` envelope, matching the server format.
private enum MockDisplayUnits {

    static let productCard: String = """
    {
      "wzrk_id": "demo_unit_1",
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
      "wzrk_id": "demo_unit_2",
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

    static let statsCard: String = """
    {
      "wzrk_id": "demo_unit_3",
      "type": "native_display",
      "native_display_config": {
        "theme": {
          "id": "stats",
          "defaultStyle": {
            "textColor": "#1F2937",
            "fontSize": 14,
            "lineHeight": 20
          }
        },
        "root": {
          "type": "container",
          "id": "stats-card",
          "containerType": "vertical",
          "layout": {
            "width": { "value": 100, "unit": "percent" },
            "height": { "value": -2, "unit": "dp" },
            "padding": { "all": 20 },
            "arrangement": { "type": "spaced", "spacing": 12 }
          },
          "style": {
            "backgroundColor": "#F0FDF4",
            "borderRadius": 16,
            "borderWidth": 1,
            "borderColor": "#BBF7D0"
          },
          "children": [
            {
              "type": "element",
              "id": "stats-title",
              "elementType": "text",
              "bindings": { "text": "Your Weekly Stats" },
              "layout": {
                "width": { "value": 100, "unit": "percent" },
                "height": { "value": -2, "unit": "dp" }
              },
              "style": {
                "fontSize": 18,
                "fontWeight": "bold",
                "textColor": "#166534",
                "lineHeight": 24
              }
            },
            {
              "type": "container",
              "id": "stats-row",
              "containerType": "horizontal",
              "layout": {
                "width": { "value": 100, "unit": "percent" },
                "height": { "value": -2, "unit": "dp" },
                "arrangement": { "type": "space_between" }
              },
              "children": [
                {
                  "type": "element",
                  "id": "stat-visits",
                  "elementType": "text",
                  "bindings": { "text": "Visits: 142" },
                  "layout": {
                    "width": { "value": -2, "unit": "dp" },
                    "height": { "value": -2, "unit": "dp" }
                  },
                  "style": {
                    "fontSize": 14,
                    "fontWeight": "medium",
                    "textColor": "#15803D",
                    "lineHeight": 20
                  }
                },
                {
                  "type": "element",
                  "id": "stat-orders",
                  "elementType": "text",
                  "bindings": { "text": "Orders: 8" },
                  "layout": {
                    "width": { "value": -2, "unit": "dp" },
                    "height": { "value": -2, "unit": "dp" }
                  },
                  "style": {
                    "fontSize": 14,
                    "fontWeight": "medium",
                    "textColor": "#15803D",
                    "lineHeight": 20
                  }
                },
                {
                  "type": "element",
                  "id": "stat-saved",
                  "elementType": "text",
                  "bindings": { "text": "Saved: $47" },
                  "layout": {
                    "width": { "value": -2, "unit": "dp" },
                    "height": { "value": -2, "unit": "dp" }
                  },
                  "style": {
                    "fontSize": 14,
                    "fontWeight": "medium",
                    "textColor": "#15803D",
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
        "campaign": "engagement_stats",
        "period": "weekly"
      }
    }
    """
}

// MARK: - Supporting Views

/// A card section with a title, icon, and content.
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

/// Displays a labeled code snippet.
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
        BridgeIntegrationView()
    }
}
