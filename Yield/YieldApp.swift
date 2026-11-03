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
    
    @State private var currentTab = "Today"
    
    let speciesDb = SpeciesDatabase.shared

    var body: some View {
        Group() {
            switch currentTab {
            case "Today": TodayTab()
            case "Spots": MapTab()
            default: TodayTab()
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            NavBar(currentTab: $currentTab, onAction: { name in
                currentTab = "Spots"
            })
        }
        .task {
            location.start()
            await spots.load()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.background)
        
    }
}

#Preview {
    RootView()
        .environment(LocationManager())
        .environment(SpotStore())
}
