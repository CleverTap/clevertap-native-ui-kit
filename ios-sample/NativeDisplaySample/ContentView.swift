import SwiftUI
import CleverTapNativeDisplay

struct ContentView: View {
    @State private var showingDemoMenu = false

    var body: some View {
        NavigationView {
            BannerShowcaseView()
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingDemoMenu = true
                        }) {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 20))
                        }
                    }
                }
                .sheet(isPresented: $showingDemoMenu) {
                    DemoMenuView()
                }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Demo Menu View

/// Menu to access other demo screens
struct DemoMenuView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Demo Screens")) {
                    NavigationLink(destination: ArrangementDemoView()) {
                        DemoMenuItem(
                            icon: "rectangle.3.group",
                            title: "Arrangements",
                            description: "Explore all 7 arrangement strategies"
                        )
                    }

                    NavigationLink(destination: AnimationDemoView()) {
                        DemoMenuItem(
                            icon: "wand.and.stars",
                            title: "Animations",
                            description: "Container and element animations"
                        )
                    }

                    NavigationLink(destination: TestConfigBrowserView()) {
                        DemoMenuItem(
                            icon: "testtube.2",
                            title: "Test Configs",
                            description: "Browse and test configurations"
                        )
                    }

                    NavigationLink(destination: HomeScreenView()) {
                        DemoMenuItem(
                            icon: "house.fill",
                            title: "Home Screen",
                            description: "Example home screen layout"
                        )
                    }
                }
            }
            .navigationTitle("Other Demos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Demo Menu Item

/// Individual menu item for demo screens
struct DemoMenuItem: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.system(size: 24))
                .frame(width: 40, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct MyView: View {
    // just for testing
    var body: some View {
        ZStack() {
            //Text("I am legend!")
            ZStack {
                Text("I am legend!")
            }
                .frame(width: 40, height: 16)
                .background(Color.red)
                .offset(x: 20, y: 20)
            //Text("I am legend 2!")
            ZStack {
                Text("I am legend 2!")
            }
                .frame(width: 40, height: 16)
                .background(Color.blue)
                .offset(x: 40, y: 40)
            
            ZStack {
                Image(systemName: "star.fill")
            }
                .frame(width: 50, height: 50)
                .background(Color.gray)
                .offset(x: 250, y: 250)
        }.frame(width: 300, height: 300, alignment: .topLeading)
            .background(Color.green.opacity(0.3))
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
                        GeometryReader { geometry in
                            ZStack {
                                Color(hex: "#F5F5F5")
                                    .edgesIgnoringSafeArea(.all)
                                ScrollView {
                                    NativeDisplayView(config: config)
                                        .environment(\.nativeDisplayParentSize, CGSize(
                                            width: geometry.size.width - 32,
                                            height: geometry.size.height
                                        ))
                                        .frame(maxWidth: .infinity)
                                        .padding(16)
                                }
                            }
                        }
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
                    GeometryReader { geometry in
                        ZStack {
                            Color(hex: "#F8F9FE")
                                .edgesIgnoringSafeArea(.all)

                            ScrollView {
                                NativeDisplayView(
                                    config: config,
                                    componentListener: HomeScreenComponentListener()
                                )
                                .environment(\.nativeDisplayParentSize, CGSize(
                                    width: geometry.size.width - 32,
                                    height: geometry.size.height
                                ))
                                .padding(16)
                            }
                        }
                    }
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
    
    func onComponentInteraction(nodeId: String, interactionType: InteractionType, hasServerAction: Bool, action: Action?) -> Bool {
        return false
    }
    
    
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

/// Tab 1: Animation Demo Screen (NEW)
/// Demonstrates three animation patterns with interactive selection
struct AnimationDemoView: View {
    @State private var config: ResolvedConfig?
    @State private var errorMessage: String?
    @State private var isLoading = true
    @State private var selectedDemo = 0
    
    // Define available demos
    let demos: [(String, String)] = [
        ("Container Fade", "animation_container_fade"),
        ("Staggered Children", "animation_staggered_children"),
        ("Container + Children", "animation_container_and_children")
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Demo Selector at the top
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(demos.indices, id: \.self) { index in
                            DemoButton(
                                title: demos[index].0,
                                isSelected: selectedDemo == index,
                                action: {
                                    selectedDemo = index
                                    loadConfig()
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .background(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
                
                // Info Card
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(Color(hex: "#E65100"))
                        Text(infoText)
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#E65100"))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(16)
                .background(Color(hex: "#FFF3E0"))
                .cornerRadius(8)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
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
                        GeometryReader { geometry in
                            ZStack {
                                Color(hex: "#F5F5F5")
                                    .edgesIgnoringSafeArea(.all)

                                ScrollView {
                                    NativeDisplayView(config: config)
                                        .environment(\.nativeDisplayParentSize, CGSize(
                                            width: geometry.size.width - 32,
                                            height: geometry.size.height
                                        ))
                                        .frame(maxWidth: .infinity)
                                        .padding(16)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("🎬 Animations")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadConfig()
            }
        }
    }
    
    private var infoText: String {
        switch selectedDemo {
        case 0:
            return "💡 Entire container fades in (500ms). All children appear together."
        case 1:
            return "💡 Each child slides in from left with 100ms stagger delay (0ms, 100ms, 200ms, 300ms, 400ms)."
        case 2:
            return "💡 Container fades in first (0ms), then image scales (400ms delay), text slides (600ms, 800ms delay), features fade-scale (1000-1200ms delay), button springs (1400ms)."
        default:
            return ""
        }
    }
    
    private func loadConfig() {
        isLoading = true
        errorMessage = nil
        
        let jsonFileName = demos[selectedDemo].1
        
        guard let url = Bundle.main.url(forResource: jsonFileName, withExtension: "json") else {
            errorMessage = "Could not find \(jsonFileName).json in bundle"
            isLoading = false
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            config = try decoder.decode(ResolvedConfig.self, from: data)
            errorMessage = nil
            print("✅ Loaded animation demo: \(jsonFileName)")
        } catch {
            errorMessage = "Failed to decode JSON:\n\n\(error.localizedDescription)"
            print("❌ Decode error: \(error)")
        }
        
        isLoading = false
    }
}

/// Custom button for demo selection
struct DemoButton: View {
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
