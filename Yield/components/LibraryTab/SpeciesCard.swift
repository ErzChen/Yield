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
                    .font(.besleyBold(Font.searchCommon))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                Text(sciName)
                    .font(.manropeRegular(Font.searchSci))
                    .italic()
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)
            }
            .padding(.vertical, Size.smallPadding)
            .padding(.horizontal, Size.regPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.card)
                .strokeBorder(Color.border, lineWidth: 1)
        }
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
            VStack(alignment: .leading, spacing: Size.largePadding) {
                gallery
                VStack(alignment: .leading, spacing: 2) {
                    Text(species.common_name)
                        .font(.besleyBold(Font.detailTitle))
                        .foregroundStyle(Color.textPrimary)
                    Text(species.sci_name)
                        .font(.manropeRegular(Font.spotText))
                        .italic()
                        .foregroundStyle(Color.textSecondary)
                }
                seasonChart
                infoSection
            }
            .padding(.horizontal, Size.pagePadding)
            .padding(.bottom, Size.largePadding)
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
                    HStack(alignment: .top, spacing: Size.regPadding) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: Size.iconFeature))
                            .foregroundStyle(Color.failure)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("No notes written for this species yet.")
                                .font(.manropeMedium(Font.infoText))
                                .foregroundStyle(Color.textSecondary)
                            Text("Never assume a species is safe to eat.")
                                .font(.manropeMedium(Font.infoText))
                                .foregroundStyle(Color.textPrimary)
                        }
                    }
                    .padding(Size.regPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.card))
                    .overlay {
                        RoundedRectangle(cornerRadius: Radius.card)
                            .strokeBorder(Color.border, lineWidth: 1)
                    }
                } else {
                    VStack(alignment: .leading, spacing: Size.regPadding) {
                        edibilitySection
                        lookalikesSection
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Description")
                                .font(.manropeMedium(Font.infoTitle))
                                .foregroundStyle(Color.accent)
                            Text(info?.description ?? "Not written yet")
                                .font(.manropeRegular(Font.infoText))
                                .foregroundStyle(info?.description == nil ? Color.textSecondary : Color.textPrimary)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Habitat")
                                .font(.manropeMedium(Font.infoTitle))
                                .foregroundStyle(Color.accent)
                            Text(info?.habitat ?? "Not written yet")
                                .font(.manropeRegular(Font.infoText))
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

        return VStack(alignment: .leading, spacing: Size.smallPadding) {
            Text("Edibility")
                .font(.manropeMedium(Font.infoTitle))
                .foregroundStyle(Color.accent)
            HStack(spacing: Size.smallSpacing) {
                Image(systemName: symbol)
                Text(headline)
            }
            .font(.besleyBold(Font.edibilityTitle))
            .foregroundStyle(isFilled ? Color.surface : tint)
            .padding(.horizontal, Size.regPadding)
            .padding(.vertical, Size.smallPadding)
            .background(
                isFilled ? tint : tint.opacity(0.12),
                in: RoundedRectangle(cornerRadius: Radius.tile)
            )
            Text(detail)
                .font(.manropeRegular(Font.infoText))
                .foregroundStyle(Color.textPrimary)
        }
    }

    private var lookalikesSection: some View {
        let all: [Lookalike] = info?.lookalikes ?? []
        let dangerous: [Lookalike] = all.filter { $0.isDangerous }
        let others: [Lookalike] = all.filter { !$0.isDangerous }
        let sorted: [Lookalike] = dangerous + others

        return VStack(alignment: .leading, spacing: Size.smallPadding) {
            Text("Lookalikes")
                .font(.manropeMedium(Font.infoTitle))
                .foregroundStyle(Color.accent)
            if sorted.isEmpty {
                Text("Not written yet")
                    .font(.manropeRegular(Font.infoText))
                    .foregroundStyle(Color.textSecondary)
            } else {
                ForEach(sorted) {
                    lookalike in

                    lookalikeRow(lookalike)
                }
            }
        }
    }

    @ViewBuilder
    private func lookalikeRow(_ lookalike: Lookalike) -> some View {
        if let linked = lookalike.summary {
            Button {
                selectedLookalike = linked
            } label: {
                lookalikeCard(lookalike, linked: true)
            }
            .buttonStyle(.plain)
        } else {
            lookalikeCard(lookalike, linked: false)
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
                    .font(.besleyMedium(Font.lookalikeName))
                    .foregroundStyle(Color.textPrimary)
                Text(lookalike.sciName)
                    .font(.manropeRegular(Font.lookalikeSci))
                    .italic()
                    .foregroundStyle(Color.textSecondary)
                Spacer()
                if lookalike.isDangerous {
                    dangerTag
                }
            }
            .padding(.horizontal, 2)
            .frame(minHeight: Size.lookalikeThumb)
            Spacer()
            if linked {
                Image(systemName: "chevron.right")
                    .font(.system(size: Size.iconInline))
                    .foregroundStyle(Color.textSecondary)
                    .frame(height: Size.lookalikeThumb)
            }
        }
        .padding(Size.smallPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.card)
                .strokeBorder(Color.border, lineWidth: 1)
        }
    }

    private var dangerTag: some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text("Toxic")
        }
        .font(.manropeBold(Font.searchSci))
        .foregroundStyle(Color.failure)
        .padding(.horizontal, Size.smallPadding)
        .padding(.vertical, 4)
        .background(Color.failure.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: Radius.card))
    }
    
    private var seasonChart: some View {
        VStack(alignment: .leading, spacing: Size.smallSpacing) {
            Text("When it's in season here")
                .font(.besleyMedium(Font.chartTitle))
                .foregroundStyle(Color.textPrimary)
            if !loaded {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: Size.chart)
            } else if season.levels.isEmpty {
                Text("No sightings recorded near you for this species.")
                    .font(.manropeRegular(Font.chartSubtitle))
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
                        : Color.surfaceAccent
                    )
                    RuleMark(x: .value("Current Week", now))
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .foregroundStyle(Color.accent)
                        .annotation(position: .top, alignment: .center) {
                            Text("Now")
                                .font(.manropeBold(Font.chartLabel))
                                .foregroundStyle(Color.accent)
                        }
                }
                .chartYScale(domain: 0...1)
                .chartYAxis {
                    AxisMarks(position: .leading, values: [0.0, 1.0]) {
                        value in
                        
                        AxisGridLine().foregroundStyle(Color.textSecondary.opacity(0.2))
                        AxisValueLabel {
                            if let level = value.as(Double.self) {
                                Text(level >= 1 ? "Peak" : "Low")
                            }
                        }
                        .font(.manropeRegular(Font.chartLabel))
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
                        .font(.manropeRegular(Font.chartLabel))
                        .foregroundStyle(Color.textSecondary)
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
                            .foregroundStyle(Color.textSecondary.opacity(0.5))
                        AxisTick(stroke: StrokeStyle(lineWidth: 1))
                            .foregroundStyle(Color.textSecondary.opacity(0.5))
                    }
                }
                .frame(height: Size.chart)

                Text(rangeNote)
                    .font(.manropeRegular(Font.chartSubtitle))
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
                                    .font(.manropeRegular(Font.imageAttribution))
                                    .foregroundStyle(Color.surface)
                                    .padding(Size.smallPadding)
                                    .background(Color.Palette.black.opacity(0.5))
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
