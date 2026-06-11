import SwiftUI
import CleverTapNativeDisplay
import CleverTapSDK

// MARK: - Data Models

enum SlotDemoItem: Identifiable {
    case appContent(AppContentItem)
    case slot(slotId: String)

    var id: String {
        switch self {
        case .appContent(let item): return "app_\(item.id)"
        case .slot(let slotId): return "slot_\(slotId)"
        }
    }
}

struct AppContentItem: Identifiable {
    let id: Int
    let title: String
    let subtitle: String
    let imageUrl: String
}

// MARK: - Slot Demo View

/// Demonstrates NativeDisplaySlot views mixed into a scrollable content feed.
/// Four slots are placed at fixed positions among 15 hardcoded app items.
/// A toolbar button fires a CleverTap event to fetch real server data for the slots.
struct SlotDemoView: View {

    private let items: [SlotDemoItem] = {
        let appItems: [AppContentItem] = [
            AppContentItem(id: 1, title: "Morning Yoga Flow", subtitle: "30 min \u{00B7} Beginner friendly", imageUrl: "https://yavuzceliker.github.io/sample-images/image-1.jpg"),
            AppContentItem(id: 2, title: "Mediterranean Salad", subtitle: "Quick & healthy lunch recipe", imageUrl: "https://yavuzceliker.github.io/sample-images/image-5.jpg"),
            AppContentItem(id: 3, title: "Productivity Hacks", subtitle: "5 tips for focused work", imageUrl: "https://yavuzceliker.github.io/sample-images/image-10.jpg"),
            AppContentItem(id: 4, title: "Trail Running Guide", subtitle: "Best routes near you", imageUrl: "https://yavuzceliker.github.io/sample-images/image-15.jpg"),
            AppContentItem(id: 5, title: "Indoor Plants 101", subtitle: "Low-maintenance greenery", imageUrl: "https://yavuzceliker.github.io/sample-images/image-20.jpg"),
            AppContentItem(id: 6, title: "Weekend Getaways", subtitle: "Top 10 road trip destinations", imageUrl: "https://yavuzceliker.github.io/sample-images/image-25.jpg"),
            AppContentItem(id: 7, title: "Budget Meal Prep", subtitle: "Save time and money", imageUrl: "https://yavuzceliker.github.io/sample-images/image-30.jpg"),
            AppContentItem(id: 8, title: "Home Workout", subtitle: "No equipment needed", imageUrl: "https://yavuzceliker.github.io/sample-images/image-35.jpg"),
            AppContentItem(id: 9, title: "Coffee Brewing", subtitle: "Perfect pour-over technique", imageUrl: "https://yavuzceliker.github.io/sample-images/image-40.jpg"),
            AppContentItem(id: 10, title: "Sleep Better", subtitle: "Science-backed tips", imageUrl: "https://yavuzceliker.github.io/sample-images/image-45.jpg"),
            AppContentItem(id: 11, title: "Digital Detox", subtitle: "Unplug and recharge", imageUrl: "https://yavuzceliker.github.io/sample-images/image-50.jpg"),
            AppContentItem(id: 12, title: "Book Club Picks", subtitle: "This month's top reads", imageUrl: "https://yavuzceliker.github.io/sample-images/image-55.jpg"),
            AppContentItem(id: 13, title: "Smoothie Recipes", subtitle: "Fuel your morning", imageUrl: "https://yavuzceliker.github.io/sample-images/image-60.jpg"),
            AppContentItem(id: 14, title: "Desk Stretches", subtitle: "Relieve tension in 5 min", imageUrl: "https://yavuzceliker.github.io/sample-images/image-65.jpg"),
            AppContentItem(id: 15, title: "Mindful Breathing", subtitle: "Calm in 3 minutes", imageUrl: "https://yavuzceliker.github.io/sample-images/image-70.jpg"),
        ]

        // Build the 19-item list: slots interleaved with app content
        var list: [SlotDemoItem] = []
        list.append(.slot(slotId: "slot_top"))        // index 0
        list.append(.appContent(appItems[0]))          // index 1
        list.append(.appContent(appItems[1]))          // index 2
        list.append(.appContent(appItems[2]))          // index 3
        list.append(.slot(slotId: "slot_feed_1"))      // index 4
        list.append(.appContent(appItems[3]))          // index 5
        list.append(.appContent(appItems[4]))          // index 6
        list.append(.appContent(appItems[5]))          // index 7
        list.append(.slot(slotId: "slot_feed_2"))      // index 8
        list.append(.appContent(appItems[6]))          // index 9
        list.append(.appContent(appItems[7]))          // index 10
        list.append(.appContent(appItems[8]))          // index 11
        list.append(.appContent(appItems[9]))          // index 12
        list.append(.appContent(appItems[10]))         // index 13
        list.append(.appContent(appItems[11]))         // index 14
        list.append(.appContent(appItems[12]))         // index 15
        list.append(.appContent(appItems[13]))         // index 16
        list.append(.appContent(appItems[14]))         // index 17
        list.append(.slot(slotId: "slot_bottom"))      // index 18
        return list
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Slot Demo")
                    .font(.title3)
                    .fontWeight(.bold)
                    .padding(.bottom, 4)
                
                Text("This feed contains 4 NativeDisplaySlot views at fixed positions. Tap the button below to fire a CleverTap event that fetches real server data for the slots.")
                    .font(.body)
                    .foregroundColor(Color(red: 0x66/255, green: 0x66/255, blue: 0x66/255))
                    .padding(.bottom, 12)
                
                Button(action: {
                    if let cleverTap = CleverTap.sharedInstance() {
                        cleverTap.recordEvent("asd")
                        cleverTap.recordEvent("Footer5")
                        cleverTap.recordEvent("Header1")
                        cleverTap.recordEvent("Header2")
                        cleverTap.recordEvent("Header4")
                        cleverTap.recordEvent("lalit")
                    }
                }) {
                    Text("Fetch Slot Data")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.all, 4)
            
            LazyVStack(spacing: 12) {
                ForEach(items) { item in
                    switch item {
                    case .slot(let slotId):
                        NativeDisplaySlot(slotId: slotId) {
                            SlotPlaceholderView()
                        }

                    case .appContent(let appItem):
                        AppContentCardView(item: appItem)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Slot Demo")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    let ct = CleverTap.sharedInstance()
                    ct?.recordEvent("Footer1")
                    ct?.recordEvent("Footer5")
                    ct?.recordEvent("Header1")
                    ct?.recordEvent("Header2")
                    ct?.recordEvent("Header4")
                } label: {
                    Text("Fetch Slot Data")
                        .font(.system(size: 14, weight: .medium))
                }
            }
        }
    }
}

// MARK: - Slot Placeholder View

/// Placeholder shown inside a NativeDisplaySlot before server data arrives.
/// Subtle gray background with a dashed border and centered "Ad" label.
struct SlotPlaceholderView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))

            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                .foregroundColor(Color(.systemGray4))

            Text("Ad")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(.systemGray2))
        }
        .frame(height: 80)
    }
}

// MARK: - App Content Card View

/// Card-like view for a hardcoded app content item.
/// AsyncImage on top, title and subtitle below, white background with shadow.
struct AppContentCardView: View {
    let item: AppContentItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AsyncImage(url: URL(string: item.imageUrl)) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .overlay(ProgressView())
                        .frame(height: 180)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, minHeight: 180, maxHeight: 180)
                        .clipped()
                case .failure:
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.secondary)
                        )
                        .frame(height: 180)
                @unknown default:
                    EmptyView()
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(item.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(12)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        SlotDemoView()
    }
}
