import SwiftUI

@main
struct YieldApp: App {
    @State private var location = LocationManager()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(location)
        }
    }
}

struct RootView: View {
    @Environment(LocationManager.self) private var location
    @State private var currentTab = "Today"
    let shared = Database.shared

    var body: some View {
//        Group() {
//            TodayTab()
//        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .background(Color.background)
//        .safeAreaInset(edge: .bottom, spacing: 0) {
//            NavBar(currentTab: $currentTab)
//        }
        Group {
            MapScreen()
        }
        .task {
            location.start()
        }
    }
}

#Preview {
    RootView()
        .environment(LocationManager())
}
