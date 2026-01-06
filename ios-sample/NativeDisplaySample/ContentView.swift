import SwiftUI
import CleverTapNativeDisplay

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 0: Arrangement Demo
            ArrangementDemoView()
                .tabItem {
                    Label("📏 Arrangements", systemImage: "rectangle.3.group")
                }
                .tag(0)
            
            // Tab 1: Home Screen (Original)
            HomeScreenView()
                .tabItem {
                    Label("🏠 Home", systemImage: "house.fill")
                }
                .tag(1)
        }
    }
}

/// Tab 0: Arrangement Demo Screen
/// Demonstrates all 7 arrangement strategies with interactive buttons
struct ArrangementDemoView: View {
    @State private var config: ResolvedConfig?
    @State private var errorMessage: String?
    @State private var isLoading = true
    @State private var selectedStrategy: ArrangementStrategyOption = .spaced
    
    // Define available strategies
    let strategies: [(String, ArrangementStrategyOption)] = [
        ("SPACED", .spaced),
        ("BETWEEN", .spaceBetween),
        ("EVENLY", .spaceEvenly),
        ("AROUND", .spaceAround),
        ("START", .start),
        ("CENTER", .center),
        ("END", .end)
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Strategy Picker at the top
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(strategies, id: \.0) { name, strategy in
                            StrategyButton(
                                title: name,
                                isSelected: selectedStrategy == strategy,
                                action: {
                                    selectedStrategy = strategy
                                    updateArrangementStrategy(strategy)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .background(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
                
                // Main content
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
                            NativeDisplayView(config: config)
                                .frame(maxWidth: .infinity)
                        }
                        .background(Color(hex: "#F5F5F5"))
                    }
                }
            }
            .navigationTitle("📏 Arrangements")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadConfig()
            }
        }
    }
    
    private func loadConfig() {
        isLoading = true
        errorMessage = nil
        
        guard let url = Bundle.main.url(forResource: "arrangement_demo", withExtension: "json") else {
            errorMessage = "Could not find arrangement_demo.json in bundle"
            isLoading = false
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            config = try decoder.decode(ResolvedConfig.self, from: data)
            errorMessage = nil
            print("✅ Loaded arrangement demo config: \(String(describing: config?.root))")
        } catch {
            errorMessage = "Failed to decode JSON:\n\n\(error.localizedDescription)"
            print("❌ Decode error: \(error)")
        }
        
        isLoading = false
    }
    
    private func updateArrangementStrategy(_ strategy: ArrangementStrategyOption) {
        guard let currentConfig = config else { return }
        
        // Create new arrangement based on strategy
        let newArrangement = strategy.toChildArrangement()
        
        // Update the root container's arrangement
        if case .container(let container) = currentConfig.root {
            // Create new layout with updated arrangement
            let updatedLayout = Layout(
                width: container.layout?.width,
                height: container.layout?.height,
                offset: container.layout?.offset,
                padding: container.layout?.padding,
                arrangement: newArrangement  // Use new arrangement
            )
            
            // Create new container with updated layout
            let updatedContainer = NativeDisplayContainer(
                id: container.id,
                containerType: container.containerType,
                children: container.children,
                layout: updatedLayout,  // New layout
                style: container.style,
                styleClass: container.styleClass,
                visible: container.visible,
                actions: container.actions,
                animation: container.animation,
                galleryConfig: container.galleryConfig,
                dividerConfig: container.dividerConfig
            )
            
            // Create new config with updated root
            config = ResolvedConfig(
                theme: currentConfig.theme,
                styleClasses: currentConfig.styleClasses,
                variables: currentConfig.variables,
                root: .container(updatedContainer)
            )
            
            print("✅ Updated arrangement to: \(strategy)")
        }
    }
}

/// Custom button for strategy selection
struct StrategyButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.blue : Color(.systemGray5))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Enum to represent arrangement strategies
enum ArrangementStrategyOption: Equatable {
    case spaced
    case spaceBetween
    case spaceEvenly
    case spaceAround
    case start
    case center
    case end
    
    func toChildArrangement() -> ChildArrangement {
        switch self {
        case .spaced:
            return ChildArrangement(spacing: 16, spacingUnit: .dp, strategy: .spaced)
        case .spaceBetween:
            return ChildArrangement(spacing: nil, spacingUnit: .dp, strategy: .spaceBetween)
        case .spaceEvenly:
            return ChildArrangement(spacing: nil, spacingUnit: .dp, strategy: .spaceEvenly)
        case .spaceAround:
            return ChildArrangement(spacing: nil, spacingUnit: .dp, strategy: .spaceAround)
        case .start:
            return ChildArrangement(spacing: nil, spacingUnit: .dp, strategy: .start)
        case .center:
            return ChildArrangement(spacing: nil, spacingUnit: .dp, strategy: .center)
        case .end:
            return ChildArrangement(spacing: nil, spacingUnit: .dp, strategy: .end)
        }
    }
}

/// Tab 1: Home Screen (WITH COMPONENT LISTENER)
struct HomeScreenView: View {
    @State private var config: ResolvedConfig?
    @State private var errorMessage: String?
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    VStack {
                        ProgressView()
                        Text("Loading...")
                            .foregroundColor(.gray)
                    }
                } else if let error = errorMessage {
                    ErrorView(message: error) {
                        loadConfig()
                    }
                } else if let config = config {
                    ScrollView {
                        NativeDisplayView(
                            config: config,
                            componentListener: HomeScreenComponentListener()
                        )
                    }
                    .background(Color(hex: "#F8F9FE"))
                }
            }
            .navigationTitle("🏠 Home")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadConfig()
            }
        }
    }
    
    private func loadConfig() {
        isLoading = true
        errorMessage = nil
        
        guard let url = Bundle.main.url(forResource: "home_screen", withExtension: "json") else {
            errorMessage = "Could not find home_screen.json in bundle"
            isLoading = false
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            print("✅ Loaded JSON data: \(data.count) bytes")
            
            let decoder = JSONDecoder()
            config = try decoder.decode(ResolvedConfig.self, from: data)
            errorMessage = nil
            
            if let config = config {
                print("✅ Decoded config successfully")
                print("   - Theme: \(config.theme.id)")
                print("   - Total nodes: \(countNodes(config.root))")
            }
        } catch {
            errorMessage = "Failed to decode JSON:\n\n\(error.localizedDescription)"
            print("❌ Decode error: \(error)")
        }
        
        isLoading = false
    }
    
    private func countNodes(_ node: NativeDisplayNode) -> Int {
        switch node {
        case .container(let container):
            return 1 + container.children.reduce(0) { $0 + countNodes($1) }
        case .element:
            return 1
        }
    }
}

/// Component Listener for Home Screen
/// Logs all component interactions
class HomeScreenComponentListener: NativeDisplayComponentListener {
    
    init() {
        print("Init HomeScreenComponentListener")
    }
    
    /// Listen to ALL components by returning nil
    func getInterestedNodeIds() -> Set<String>? {
        print("HomeScreenComponentListener - getInterestedNodeIds()")
        return nil
    }
    
    /// Log every interaction
    func onComponentInteraction(
        nodeId: String,
        interactionType: InteractionType,
        hasServerAction: Bool
    ) -> Bool {
        // Log to console
        print("📱 HomeScreen_Click: Component: \(nodeId) | Type: \(interactionType) | HasServerAction: \(hasServerAction)")
        
        // Don't consume, let server actions proceed
        return false
    }
}

/// Reusable error view
struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            Text("Error Loading Config")
                .font(.headline)
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            Button("Retry", action: onRetry)
                .padding(.top)
        }
        .padding()
    }
}

// Helper extension for hex colors
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        if hexSanitized.count == 6 {
            self.init(
                red: Double((rgb & 0xFF0000) >> 16) / 255.0,
                green: Double((rgb & 0x00FF00) >> 8) / 255.0,
                blue: Double(rgb & 0x0000FF) / 255.0
            )
        } else if hexSanitized.count == 8 {
            self.init(
                red: Double((rgb & 0xFF000000) >> 24) / 255.0,
                green: Double((rgb & 0x00FF0000) >> 16) / 255.0,
                blue: Double((rgb & 0x0000FF00) >> 8) / 255.0,
                opacity: Double(rgb & 0x000000FF) / 255.0
            )
        } else {
            return nil
        }
    }
}

#Preview {
    ContentView()
}
