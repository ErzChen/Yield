import SwiftUI
import Charts

struct SpeciesCard: View {
    let urlString: String?
    let commonName: String
    let sciName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.clear
                .aspectRatio(16 / 9, contentMode: .fit)
                .overlay {
                    AsyncImage(url: urlString.flatMap(URL.init)) {
                        phase in
                        
                        if let image = phase.image {
                            image.resizable().scaledToFill()
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
        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .strokeBorder(Color.border, lineWidth: 1)
        }
        .appShadow()
    
    }
}

struct SpeciesDetailView: View {
    @Environment(LocationManager.self) private var location

    @State private var images: [SpeciesImage] = []
    @State private var info: SpeciesInfo?
    @State private var season = SeasonCurve(levels: [], radius: 0, totalObs: 0)
    @State private var loaded = false
    
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
            }
            .padding(.horizontal, Size.regPadding)
        }
        .background(Color.background)
        .navigationBarBackButtonHidden(true)
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
                            AsyncImage(url: URL(string: img.url)) {
                                phase in
                                
                                if let image = phase.image {
                                    image.resizable().scaledToFill()
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
                                    .background(Color.black.opacity(0.5))
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

    private var seasonChart: some View {
        VStack(alignment: .leading, spacing: Size.smallSpacing) {
            Text("When it's in season here")
                .font(.besleyBold(Font.chartTitle))
                .foregroundStyle(Color.textPrimary)
            if season.levels.isEmpty {
                Text("No sightings recorded near you for this species.")
                    .font(.manropeRegular(Font.chartSubtitle))
                    .foregroundStyle(Color.textSecondary)
            } else {
                let now = Calendar.current.component(.weekOfYear, from: .now)
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
                .chartYAxis {
                    AxisMarks(position: .leading) {
                        value in
                        AxisGridLine().foregroundStyle(Color.textSecondary.opacity(0.2))
                        AxisTick().foregroundStyle(Color.textSecondary)
                        AxisValueLabel().foregroundStyle(Color.textSecondary)
                    }
                }
                .chartYAxisLabel(position: .top, alignment: .leading) {
                    Text("Species Abundance")
                        .font(.manropeRegular(Font.chartLabel))
                        .foregroundColor(Color.textSecondary)
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
}
