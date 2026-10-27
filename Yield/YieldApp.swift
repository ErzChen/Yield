import SwiftUI

@main
struct YieldApp: App {
    @State private var currentTab: String = "Today"
    var body: some Scene {
        WindowGroup {
            Spacer()
            NavBar(currentTab: $currentTab)
        }
        
    }
}

struct RootView: View {
    @State private var currentTab = "Today"

    var body: some View {
        Group() {
            TodayTab()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.background)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            NavBar(currentTab: $currentTab)
        }
    }
}

#Preview {
    RootView()
}
