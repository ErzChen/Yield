import SwiftUI

@main
struct YieldApp: App {
    @State private var location = LocationManager()
    @State private var spots = SpotStore()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(location)
                .environment(spots)
        }
    }
}

struct RootView: View {
    @Environment(LocationManager.self) private var location
    @Environment(SpotStore.self) private var spots
    
    @State private var currentTab = "Library"

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch currentTab {
                case "Today": TodayTab()
                case "Library": LibraryTab()
                case "Spots": MapTab()
                default: TodayTab()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            NavBar(currentTab: $currentTab, onAction: {
                _ in
                
                currentTab = "Spots"
            })
        }
        .background(Color.background)
        .task {
            location.start()
            await spots.load()
        }
    }
}

#Preview {
    RootView()
        .environment(LocationManager())
        .environment(SpotStore())
}
