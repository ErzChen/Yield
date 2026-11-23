import SwiftUI

struct TodayTab: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Size.large) {
                ConditionsCard()
                LikelyToday()
            }
            .padding(.vertical, Size.pagePadding)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
