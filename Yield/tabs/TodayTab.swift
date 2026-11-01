import SwiftUI

struct TodayTab: View {
    var body: some View {
        VStack(alignment: .leading) {
            ConditionsCard()
            LikelyToday()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    
}
