import SwiftUI

/// More tab: navigation list for screens that are not primary tabs.
struct MoreMenuView: View {
    var body: some View {
        List {
            NavigationLink("🔗 Bridge Integration") {
                BridgeIntegrationView()
            }
            NavigationLink("🖼️ Banner Showcase") {
                BannerShowcaseView()
            }
            NavigationLink("📏 Arrangements") {
                ArrangementDemoView()
            }
            NavigationLink("🎬 Animations") {
                AnimationDemoView()
            }
            NavigationLink("🔤 Font Customization") {
                FontDemoView()
            }
            NavigationLink("🏠 Home Screen") {
                HomeScreenView()
            }
        }
        .navigationTitle("More")
    }
}
