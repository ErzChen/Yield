import SwiftUI

struct DaysBar: View {
    let found: Int
    let total: Int

    private var fraction: Double {
        total > 0 ? min(Double(found) / Double(total), 1) : 0
    }

    var body: some View {
        Capsule()
            .fill(Color.border)
            .frame(height: Size.barHeight)
            .overlay(alignment: .leading) {
                GeometryReader {
                    proxy in

                    Capsule()
                        .fill(Color.accent)
                        .frame(width: proxy.size.width * fraction)
                }
            }
    }
}

struct DayDots: View {
    private let maxDots = 10
    
    let found: Int
    let total: Int

    var body: some View {
        if total > maxDots {
            DaysBar(found: found, total: total)
        } else {
            HStack(spacing: Size.extraSmall) {
                ForEach(0..<total, id: \.self) {
                    index in

                    Circle()
                        .fill(index < found ? Color.accent : Color.border)
                        .frame(width: Size.dayDot, height: Size.dayDot)
                }
            }
        }
    }
}

struct ScoreRing: View {
    let score: Double?

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.border, lineWidth: 4)
            if let score {
                Circle()
                    .trim(from: 0, to: score)
                    .stroke(Color.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            Text(score != nil ? "\(Int((score! * 100).rounded()))%" : "–")
                .font(.manropeBold(Font.caption))
                .monospacedDigit()
                .foregroundStyle(score == nil ? Color.textSecondary : Color.textPrimary)
        }
        .frame(width: Size.ringSize, height: Size.ringSize)
    }
}

struct SpeciesReliabilityRow: View {
    let row: SpeciesReliability

    var body: some View {
        HStack(alignment: .center, spacing: Size.medium) {
            VStack(alignment: .leading, spacing: Size.small) {
                Text(row.name)
                    .lineLimit(2)
                    .font(.besleyMedium(Font.body))
                    .foregroundStyle(Color.textPrimary)
                    .lineHeight(.normal)

                if let timing = row.timing, timing.years >= 2 {
                    Text("Usually \(dayLabel(timing.start)) – \(dayLabel(timing.end))")
                        .font(.manropeRegular(Font.label))
                        .foregroundStyle(Color.textSecondary)
                }

                HStack(spacing: Size.small) {
                    DayDots(found: row.reliability.found, total: row.reliability.total)
                    Text("\(row.reliability.found) of \(row.reliability.total) days")
                        .font(.manropeRegular(Font.label))
                        .foregroundStyle(Color.textSecondary)
                        .fixedSize()
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(row.typicalAmount.map { String($0) } ?? "–")
                .font(.manropeMedium(Font.body))
                .monospacedDigit()
                .foregroundStyle(row.typicalAmount == nil ? Color.textSecondary : Color.textPrimary)
                .frame(width: Size.amountColumn, alignment: .trailing)

            ScoreRing(score: row.reliability.hasEnoughData ? row.reliability.score : nil)
                .frame(width: Size.scoreColumn)
        }
        .padding(Size.small)
        .bordered(.background, Radius.tile)
    }
}

struct SpotPage: View {
    @Environment(SpotStore.self) private var store
    
    let spot: Spot
    
    var body: some View {
        let visits = store.visits(for: spot)
        let rows = store.reliabilities(for: spot)
        
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
                
                if !rows.isEmpty {
                    VStack(alignment: .leading, spacing: Size.small) {
                        Text("Reliability")
                            .font(.besleyMedium(Font.heading))
                            .foregroundStyle(Color.textPrimary)

                        if rows.contains(where: { !$0.reliability.hasEnoughData }) {
                            Text("Scores appear after \(Reliability.minimumDays) days at a spot")
                                .font(.manropeRegular(Font.bodySmall))
                                .foregroundStyle(Color.textSecondary)
                        }

                        HStack(spacing: Size.medium) {
                            Spacer()
                            Text("Usual")
                                .frame(width: Size.amountColumn, alignment: .trailing)
                            Text("Score")
                                .frame(width: Size.scoreColumn)
                        }
                        .font(.manropeRegular(Font.label))
                        .foregroundStyle(Color.textSecondary)
                        .padding(.horizontal, Size.small)

                        ForEach(rows) {
                            row in

                            SpeciesReliabilityRow(row: row)
                        }
                    }
                }
                
                if !visits.isEmpty {
                    VStack(alignment: .leading, spacing: Size.small) {
                        Text("History")
                            .font(.besleyMedium(Font.heading))
                            .foregroundStyle(Color.textPrimary)
                        
                        ForEach(visits) {
                            visit in
                            
                            VisitCard(visit: visit)
                        }
                    }
                }
            }
            .padding(.horizontal, Size.pagePadding)
            .padding(.bottom, Size.pagePadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.background)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            DismissButton()
        }
        .task(id: rows.map(\.speciesId).sorted()) {
            await store.loadPhenology(for: spot)
        }
    }
}
