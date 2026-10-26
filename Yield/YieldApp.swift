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

