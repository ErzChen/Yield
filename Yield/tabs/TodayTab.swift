import SwiftUI

struct TodayTab: View {
    var body: some View {
        VStack(alignment: .leading) {
            ConditionsCard()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    
}
