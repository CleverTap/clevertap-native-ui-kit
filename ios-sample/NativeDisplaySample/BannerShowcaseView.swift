import SwiftUI
import UniformTypeIdentifiers
import CleverTapNativeDisplay

// MARK: - Data Models

/// Represents a pre-defined banner in the showcase
struct BannerItem: Identifiable {
    let id: String
    let emoji: String
    let title: String
    let description: String
    let filename: String

    var displayTitle: String {
        "\(emoji) \(title)"
    }
}

// MARK: - Banner Showcase View

/// Main screen displaying 10 pre-defined banners with option to upload custom JSON
struct BannerShowcaseView: View {
    @State private var showingFilePicker = false
    @State private var uploadError: String?
    @State private var showingUploadError = false
    @State private var customConfigURL: URL?
    @State private var showingCustomBanner = false

    /// List of 10 pre-defined banners
    private let banners: [BannerItem] = [
        BannerItem(
            id: "banner-01",
            emoji: "🌞",
            title: "Summer Sale",
            description: "Hero banner with gradient",
            filename: "banner-01-hero-summer-sale"
        ),
        BannerItem(
            id: "banner-02",
            emoji: "📱",
            title: "iPhone 15 Pro",
            description: "Product showcase",
            filename: "banner-02-product-iphone"
        ),
        BannerItem(
            id: "banner-03",
            emoji: "🎉",
            title: "New Features",
            description: "App update announcement",
            filename: "banner-03-announcement-update"
        ),
        BannerItem(
            id: "banner-04",
            emoji: "✈️",
            title: "Travel Deals",
            description: "Multi-button travel banner",
            filename: "banner-04-travel-deals"
        ),
        BannerItem(
            id: "banner-05",
            emoji: "👗",
            title: "Fashion Collection",
            description: "Image banner",
            filename: "banner-05-fashion-collection"
        ),
        BannerItem(
            id: "banner-06",
            emoji: "💳",
            title: "Cashback Offer",
            description: "Credit card with GIF",
            filename: "banner-06-credit-card-offer"
        ),
        BannerItem(
            id: "banner-07",
            emoji: "⭐",
            title: "App Rating",
            description: "Social proof",
            filename: "banner-07-app-rating"
        ),
        BannerItem(
            id: "banner-08",
            emoji: "⚡",
            title: "Flash Sale",
            description: "Urgency banner",
            filename: "banner-08-flash-sale"
        ),
        BannerItem(
            id: "banner-09",
            emoji: "💎",
            title: "Go Premium",
            description: "Typography showcase",
            filename: "banner-09-premium-subscription"
        ),
        BannerItem(
            id: "banner-10",
            emoji: "👋",
            title: "Welcome",
            description: "Onboarding banner",
            filename: "banner-10-welcome-onboarding"
        )
    ]

    var body: some View {
        NavigationView {
            List {
                // Upload Custom JSON button at top
                Section {
                    Button(action: {
                        showingFilePicker = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.up.doc.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 20))

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Upload Custom JSON")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Text("Load and test your own banner configuration")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.system(size: 14))
                        }
                        .padding(.vertical, 8)
                    }
                }

                // Pre-defined banners
                Section(header: Text("Pre-defined Banners")) {
                    ForEach(banners) { banner in
                        NavigationLink(destination: BannerDetailView(
                            bannerTitle: banner.displayTitle,
                            configSource: .file(filename: banner.filename)
                        )) {
                            BannerRowView(banner: banner)
                        }
                    }
                }
            }
            .navigationTitle("Banner Showcase")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingFilePicker) {
                DocumentPicker(
                    onDocumentPicked: { url in
                        handleCustomJSON(url: url)
                    },
                    onError: { error in
                        uploadError = error
                        showingUploadError = true
                    }
                )
            }
            .alert("Upload Error", isPresented: $showingUploadError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(uploadError ?? "Unknown error")
            }
            .background(
                NavigationLink(
                    destination: customConfigURL.map { url in
                        BannerDetailView(
                            bannerTitle: "📄 Custom JSON",
                            configSource: .file(url: url)
                        )
                    },
                    isActive: $showingCustomBanner
                ) {
                    EmptyView()
                }
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    /// Handle custom JSON file selection
    private func handleCustomJSON(url: URL) {
        // Validate JSON
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            _ = try decoder.decode(ResolvedConfig.self, from: data)

            // Valid JSON - navigate to detail view
            print("✅ Valid JSON loaded from: \(url.lastPathComponent)")
            customConfigURL = url
            showingCustomBanner = true

        } catch {
            uploadError = "Invalid JSON format:\n\n\(error.localizedDescription)"
            showingUploadError = true
            print("❌ Invalid JSON: \(error)")
        }
    }
}

// MARK: - Banner Row View

/// Individual row for a banner item
struct BannerRowView: View {
    let banner: BannerItem

    var body: some View {
        HStack(spacing: 12) {
            // Emoji icon
            Text(banner.emoji)
                .font(.system(size: 32))
                .frame(width: 50, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray6))
                )

            // Title and description
            VStack(alignment: .leading, spacing: 4) {
                Text(banner.title)
                    .font(.headline)

                Text(banner.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Document Picker

/// SwiftUI wrapper for UIDocumentPickerViewController
struct DocumentPicker: UIViewControllerRepresentable {
    let onDocumentPicked: (URL) -> Void
    let onError: (String) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.json])
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        // No updates needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onDocumentPicked: onDocumentPicked, onError: onError)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onDocumentPicked: (URL) -> Void
        let onError: (String) -> Void

        init(onDocumentPicked: @escaping (URL) -> Void, onError: @escaping (String) -> Void) {
            self.onDocumentPicked = onDocumentPicked
            self.onError = onError
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else {
                onError("No file selected")
                return
            }

            // Start accessing security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                onError("Cannot access file")
                return
            }

            defer {
                url.stopAccessingSecurityScopedResource()
            }

            onDocumentPicked(url)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            // User cancelled - no action needed
        }
    }
}

// MARK: - Preview

struct BannerShowcaseView_Previews: PreviewProvider {
    static var previews: some View {
        BannerShowcaseView()
    }
}
