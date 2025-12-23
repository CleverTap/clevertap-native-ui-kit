import SwiftUI
import CleverTapNativeDisplay

struct ContentView: View {
    @State private var config: ResolvedConfig?
    @State private var errorMessage: String?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                VStack {
                    ProgressView()
                    Text("Loading...")
                        .foregroundColor(.gray)
                }
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    Text("Error Loading Config")
                        .font(.headline)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    
                    Button("Retry") {
                        loadConfig()
                    }
                    .padding(.top)
                }
            } else if let config = config {
                ScrollView {
                    NativeDisplayView(config: config)
                }
                .background(Color(hex: "#F8F9FE"))
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .onAppear {
            loadConfig()
        }
    }
    
    private func loadConfig() {
        isLoading = true
        errorMessage = nil
        
        // Load JSON from bundle
        guard let url = Bundle.main.url(forResource: "home_screen", withExtension: "json") else {
            errorMessage = "Could not find home_screen.json in bundle.\n\nMake sure the file is added to the target."
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
                print("   - Style classes: \(config.styleClasses.count)")
                print("   - Variables: \(config.variables.count)")
                print("   - Root type: \(type(of: config.root))")
                
                // Count nodes
                let nodeCount = countNodes(config.root)
                print("   - Total nodes: \(nodeCount)")
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
