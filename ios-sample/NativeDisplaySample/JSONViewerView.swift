import SwiftUI
import CleverTapNativeDisplay

// MARK: - JSON Viewer View

/// View for displaying and copying JSON configuration
struct JSONViewerView: View {
    let jsonString: String
    let title: String

    @State private var showingCopyConfirmation = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 0) {
            // JSON Display Area
            ScrollView([.horizontal, .vertical]) {
                Text(jsonString)
                    .font(.system(size: 12, design: .monospaced))
                    .padding(16)
            }
            .background(Color(hex: "#1E1E1E"))
            .foregroundColor(Color(hex: "#D4D4D4"))

            Divider()

            // Copy Button
            Button(action: {
                copyToClipboard()
            }) {
                HStack {
                    Image(systemName: "doc.on.doc.fill")
                        .font(.system(size: 18))
                    Text("Copy to Clipboard")
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.blue)
                .foregroundColor(.white)
            }
            .alert("Copied!", isPresented: $showingCopyConfirmation) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("JSON has been copied to clipboard")
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func copyToClipboard() {
        UIPasteboard.general.string = jsonString
        showingCopyConfirmation = true
    }
}

// MARK: - Preview

struct JSONViewerView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            JSONViewerView(
                jsonString: """
                {
                  "theme": {
                    "id": "example"
                  },
                  "root": {
                    "type": "container",
                    "id": "root"
                  }
                }
                """,
                title: "Example JSON"
            )
        }
    }
}
