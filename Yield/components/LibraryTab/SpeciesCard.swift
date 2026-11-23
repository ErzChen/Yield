import SwiftUI
import Charts

struct SpeciesPhoto: View {
    let urlString: String?

    var body: some View {
        Color.clear
            .overlay {
                AsyncImage(url: urlString.flatMap(URL.init), transaction: Transaction(animation: Motion.fade)) {
                    phase in

                    if let image = phase.image {
                        image.resizable().scaledToFill().transition(.opacity)
                    } else {
                        Color.background
                            .overlay {
                                Image(systemName: "photo")
                                    .foregroundStyle(Color.textSecondary)
                            }
                    }
                }
            }
            .clipped()
    }
}

struct SpeciesCard: View {
    let urlString: String?
    let commonName: String
    let sciName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SpeciesPhoto(urlString: urlString)
                .aspectRatio(16 / 9, contentMode: .fit)

            VStack(alignment: .leading) {
                Text(commonName)
                    .font(.besleyBold(Font.label))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                Text(sciName)
                    .font(.manropeRegular(Font.caption))
                    .italic()
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)
            }
            .padding(.vertical, Size.small)
            .padding(.horizontal, Size.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .bordered(.surface, Radius.card)
    }
}

struct SpeciesDetailView: View {
    @Environment(LocationManager.self) private var location

    @State private var images: [SpeciesImage] = []
    @State private var info: SpeciesInfo?
    @State private var season = SeasonCurve(levels: [], radius: 0, totalObs: 0)
    @State private var loaded = false
    @State private var selectedLookalike: SpeciesSummary?
    
    let species: SpeciesSummary

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Size.extraLarge) {
                gallery
                VStack(alignment: .leading, spacing: 2) {
                    Text(species.common_name)
                        .font(.besleyBold(Font.display))
                        .foregroundStyle(Color.textPrimary)
                    Text(species.sci_name)
                        .font(.manropeRegular(Font.body))
                        .italic()
                        .foregroundStyle(Color.textSecondary)
                    if info?.isInvasive == true {
                        HStack(spacing: Size.extraSmall) {
                            Image(systemName: "exclamationmark.octagon.fill")
                            Text("Invasive")
                        }
                        .font(.manropeBold(Font.body))
                        .foregroundStyle(Color.failure)
                        .padding(.horizontal, Size.small)
                        .padding(.vertical, Size.extraSmall)
                        .background(Color.failure.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: Radius.card))
                    }
                }
                seasonChart
                infoSection
            }
            .padding(.horizontal, Size.pagePadding)
            .padding(.bottom, Size.pagePadding)
        }
        .background(Color.background)
        .navigationBarBackButtonHidden(true)
        .navigationDestination(item: $selectedLookalike) {
            species in
            
            SpeciesDetailView(species: species)
        }
        .toolbar {
            DismissButton()
        }
        .task {
            images = await SpeciesDatabase.shared.images(species.id)
            info = await SpeciesDatabase.shared.info(species.id)
            if let coord = location.coordinate {
                season = await SpeciesDatabase.shared.seasonCurve(species.id, coord)
            }
            loaded = true
        }
    }
    
    private var infoSection: some View {
        return Group {
            if loaded {
                if info == nil {
                    HStack(alignment: .top, spacing: Size.medium) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: Size.iconFeature))
                            .foregroundStyle(Color.failure)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("No notes written for this species yet.")
                                .font(.manropeMedium(Font.body))
                                .foregroundStyle(Color.textSecondary)
                            Text("Never assume a species is safe to eat.")
                                .font(.manropeMedium(Font.body))
                                .foregroundStyle(Color.textPrimary)
                        }
                    }
                    .padding(Size.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .bordered(.surface, Radius.card)
                } else {
                    VStack(alignment: .leading, spacing: Size.medium) {
                        edibilitySection
                        lookalikesSection
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Description")
                                .font(.manropeMedium(Font.heading))
                                .foregroundStyle(Color.accent)
                            Text(info?.description ?? "Not written yet")
                                .font(.manropeRegular(Font.body))
                                .foregroundStyle(info?.description == nil ? Color.textSecondary : Color.textPrimary)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Habitat")
                                .font(.manropeMedium(Font.heading))
                                .foregroundStyle(Color.accent)
                            Text(info?.habitat ?? "Not written yet")
                                .font(.manropeRegular(Font.body))
                                .foregroundStyle(info?.habitat == nil ? Color.textSecondary : Color.textPrimary)
                        }
                    }
                }
            }
        }
    }

    private var edibilitySection: some View {
        let category: EdibilityCategory? = info?.edibility?.category
        let tint: Color = category?.color ?? Color.failure
        let symbol: String = category?.symbol ?? "questionmark.circle.fill"
        let headline: String = category?.rawValue ?? "Not written yet"
        let detail: String = info?.edibility?.sentence ?? "Never assume a species is safe to eat."
        let isFilled: Bool = category == .deadly

        return VStack(alignment: .leading, spacing: Size.small) {
            Text("Edibility")
                .font(.manropeMedium(Font.heading))
                .foregroundStyle(Color.accent)
            HStack(spacing: Size.small) {
                Image(systemName: symbol)
                Text(headline)
            }
            .font(.besleyBold(Font.subtitle))
            .foregroundStyle(isFilled ? Color.surface : tint)
            .padding(.horizontal, Size.medium)
            .padding(.vertical, Size.small)
            .background(
                isFilled ? tint : tint.opacity(0.12),
                in: RoundedRectangle(cornerRadius: Radius.tile)
            )
            Text(detail)
                .font(.manropeRegular(Font.body))
                .foregroundStyle(Color.textPrimary)
        }
    }

    private var lookalikesSection: some View {
        let all: [Lookalike] = info?.lookalikes ?? []
        let dangerous: [Lookalike] = all.filter { $0.isDangerous }
        let others: [Lookalike] = all.filter { !$0.isDangerous }
        let sorted: [Lookalike] = dangerous + others

        return VStack(alignment: .leading, spacing: Size.small) {
            Text("Lookalikes")
                .font(.manropeMedium(Font.heading))
                .foregroundStyle(Color.accent)
            if sorted.isEmpty {
                Text("Not written yet")
                    .font(.manropeRegular(Font.body))
                    .foregroundStyle(Color.textSecondary)
            } else {
                ForEach(sorted) {
                    lookalike in

                    if let linked = lookalike.summary {
                        Button {
                            selectedLookalike = linked
                        } label: {
                            lookalikeCard(lookalike, linked: true)
                        }
                    } else {
                        lookalikeCard(lookalike, linked: false)
                    }
                }
            }
        }
    }

    private func lookalikeCard(_ lookalike: Lookalike, linked: Bool) -> some View {
        return HStack(alignment: .top) {
            if linked {
                SpeciesPhoto(urlString: lookalike.summary?.url)
                    .frame(width: Size.lookalikeThumb, height: Size.lookalikeThumb)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.tile))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(lookalike.commonName)
                    .font(.besleyMedium(Font.body))
                    .foregroundStyle(Color.textPrimary)
                    .lineHeight(.normal)
                Text(lookalike.sciName)
                    .font(.manropeRegular(Font.label))
                    .italic()
                    .foregroundStyle(Color.textSecondary)
                    .lineHeight(.normal)
                if lookalike.isDangerous {
                    Spacer()
                    HStack(spacing: Size.extraSmall) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("Toxic")
                    }
                    .font(.manropeBold(Font.caption))
                    .foregroundStyle(Color.failure)
                    .padding(.horizontal, Size.small)
                    .padding(.vertical, Size.extraSmall)
                    .background(Color.failure.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: Radius.card))
                }
            }
            .padding(.horizontal, 2)
            Spacer()
            if linked {
                Image(systemName: "chevron.right")
                    .font(.system(size: Size.iconInline))
                    .foregroundStyle(Color.textSecondary)
                    .frame(height: Size.lookalikeThumb)
            }
        }
        .padding(Size.small)
        .frame(maxWidth: .infinity, alignment: .leading)
        .bordered(.surface, Radius.card)
    }
    
    private var seasonChart: some View {
        VStack(alignment: .leading, spacing: Size.small) {
            Text("When it's in season here")
                .font(.besleyMedium(Font.heading))
                .foregroundStyle(Color.textPrimary)
            if !loaded {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: Size.chart)
            } else if season.levels.isEmpty {
                Text("No sightings recorded near you for this species.")
                    .font(.manropeRegular(Font.bodySmall))
                    .foregroundStyle(Color.textSecondary)
            } else {
                let now = currentWeek()
                Chart(season.levels) {
                    level in
                    
                    BarMark(
                        x: .value("Week", level.week),
                        y: .value("Level", level.phenology)
                    )
                    .foregroundStyle(
                        level.week == now
                        ? Color.accent
                        : Color.chartBar
                    )
                    RuleMark(x: .value("Current Week", now))
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .foregroundStyle(Color.accent)
                        .annotation(position: .top, alignment: .center) {
                            Text("Now")
                                .font(.manropeBold(Font.caption))
                                .foregroundStyle(Color.accent)
                        }
                }
                .chartYScale(domain: 0...1)
                .chartYAxis {
                    AxisMarks(position: .leading, values: [0.0, 1.0]) {
                        value in
                        
                        AxisGridLine().foregroundStyle(Color.gridLine)
                        AxisValueLabel {
                            if let level = value.as(Double.self) {
                                Text(level >= 1 ? "Peak" : "Low")
                            }
                        }
                        .font(.manropeRegular(Font.caption))
                        .foregroundStyle(Color.textSecondary)
                    }
                }
                .chartXScale(domain: 1...52)
                .chartXAxis {
                    AxisMarks(values: [1, 13, 26, 39]) {
                        value in
                        
                        AxisValueLabel {
                            if let week = value.as(Int.self) {
                                switch week {
                                case 1: Text("Winter")
                                case 13: Text("Spring")
                                case 26: Text("Summer")
                                case 39: Text("Autumn")
                                default: Text("")
                                }
                            }
                        }
                        .font(.manropeRegular(Font.caption))
                        .foregroundStyle(Color.textSecondary)
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
                            .foregroundStyle(Color.gridLineStrong)
                        AxisTick(stroke: StrokeStyle(lineWidth: 1))
                            .foregroundStyle(Color.gridLineStrong)
                    }
                }
                .frame(height: Size.chart)

                Text(rangeNote)
                    .font(.manropeRegular(Font.bodySmall))
                    .foregroundStyle(Color.textSecondary)
            }
        }
    }
    
    private var rangeNote: String {
        var note = season.radius == 0
            ? "Based on sightings in your area"
            : "Based on sightings within roughly \(season.radius * 50)–\(season.radius * 50 + 50) km"
        if season.totalObs < 10 {
            note += " (only \(season.totalObs) so far)"
        }
        return note
    }

    private var gallery: some View {
        Group {
            if images.isEmpty {
                Color.surface
                    .overlay {
                        Image(systemName: "photo").foregroundStyle(Color.textSecondary)
                    }
            } else {
                TabView {
                    ForEach(images) {
                        img in
                        
                        Color.clear.overlay {
                            AsyncImage(url: URL(string: img.url), transaction: Transaction(animation: Motion.fade)) {
                                phase in
                                
                                if let image = phase.image {
                                    image.resizable().scaledToFill().transition(.opacity)
                                } else {
                                    Color.surface
                                        .overlay {
                                            Image(systemName: "photo").foregroundStyle(Color.textSecondary)
                                        }
                                }
                            }
                        }
                        .overlay(alignment: .bottomLeading) {
                            if let credit = img.attribution {
                                Text(credit)
                                    .font(.manropeRegular(Font.caption))
                                    .foregroundStyle(Color.surface)
                                    .padding(Size.small)
                                    .background(Color.overlay)
                            }
                        }
                    }
                }
                .tabViewStyle(.page)
            }
        }
        .frame(height: Size.detailImage)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card))
    }
}
