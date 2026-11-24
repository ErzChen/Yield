import SwiftUI

struct SpotPage: View {
    @Environment(SpotStore.self) private var store
    
    let spot: Spot
    
    var body: some View {
        let visits = store.visits(for: spot)
        
        ScrollView {
            VStack(alignment: .leading, spacing: Size.extraLarge) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(spot.name)
                        .font(.besleyBold(Font.title))
                        .foregroundStyle(Color.textPrimary)
                    Text(visits.isEmpty ? "No visits yet" : "\(visits.count) \(visits.count > 1 ? "visits" : "visit")")
                        .font(.manropeRegular(Font.body))
                        .foregroundStyle(Color.textSecondary)
                }
                .padding(.horizontal, Size.pagePadding)
                .padding(.bottom, Size.pagePadding)
                
                if !visits.isEmpty {
                    VStack(spacing: Size.small) {
                        ForEach(visits) {
                            visit in
                            
                            VisitCard(visit: visit)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.background)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            DismissButton()
        }
    }
}
