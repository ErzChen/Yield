import SwiftUI
import CoreLocation

struct Conditions {
    let temperature: Double
    let pressure: Double
    let pressureTrend: Double
    let rain72h: Double
    let moonPhase: Double
}

private struct OpenMeteoResponse: Decodable {
    struct Current: Decodable {
        let temperature_2m: Double
        let pressure_msl: Double
    }
    struct Hourly: Decodable {
        let time: [String]
        let precipitation: [Double?]
        let pressure_msl: [Double?]
    }
    let current: Current
    let hourly: Hourly
}

private struct ConditionTile: Identifiable {
    let id: String
    let symbol: String
    let value: String
    let label: String
    var trendSymbol: String? = nil
}

struct ConditionsCard: View {
    @Environment(LocationManager.self) private var location
    
    
    @State private var conditions: Conditions?
    @State private var errorMessage: String?
    @State private var isLoading = true
    
    var body: some View {
        content
            .cardStyle()
            .task(id: location.coordinate.map { "\($0.latitude),\($0.longitude)" } ?? "none") {
                await loadWeatherData()
            }
    }
    
    private var content: some View {
        Group {
            if location.status == .denied {
                errorView("Location access is off. Enable it in Settings")
            } else if location.status == .restricted {
                errorView("Location is restricted on this device")
            } else if let conditions {
                loadedView(conditions)
            } else if isLoading {
                loadingView()
            } else {
                errorView(errorMessage ?? "Conditions unavailable")
            }
        }
    }
    
    private func loadingView() -> some View {
        return ProgressView()
            .frame(maxWidth: .infinity, minHeight: Size.conditionsMinHeight)
    }
    
    private func errorView(_ message: String) -> some View {
        return VStack(spacing: Size.small) {
            Image(systemName: "icloud.slash")
                .font(.system(size: Size.iconFeature))
            Text(message)
                .font(.manropeMedium(Font.body))
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(Color.textSecondary)
        .frame(maxWidth: .infinity, minHeight: Size.conditionsMinHeight)
    }
    
    private func loadedView(_ conditions: Conditions) -> some View {
        let trendSymbol: String = conditions.pressureTrend > 1
            ? "arrow.up"
            : (conditions.pressureTrend < -1
               ? "arrow.down"
               : "arrow.right"
            )
        
        let moonIndex: Int = Int((conditions.moonPhase * 8).rounded()) % 8
        let moonSymbol: String = [
            "moonphase.new.moon",
            "moonphase.waxing.crescent",
            "moonphase.first.quarter",
            "moonphase.waxing.gibbous",
            "moonphase.full.moon",
            "moonphase.waning.gibbous",
            "moonphase.last.quarter",
            "moonphase.waning.crescent"
        ][moonIndex]
        let moonDirection = [
            "New",
            "Waxing",
            "Waxing",
            "Waxing",
            "Full",
            "Waning",
            "Waning",
            "Waning"
        ][moonIndex]
        let moonName = [
            "Moon",
            "Crescent",
            "Quarter",
            "Gibbous",
            "Moon",
            "Gibbous",
            "Quarter",
            "Crescent"
        ][moonIndex]
        
        let tiles: [ConditionTile] = [
            ConditionTile(
                id: "temp",
                symbol: "thermometer.medium",
                value: String(format: "%.0f°C", conditions.temperature),
                label: "Temp"
            ),
            ConditionTile(
                id: "rain",
                symbol: "cloud.rain",
                value: String(format: "%.0f mm", conditions.rain72h),
                label: "3-day rain"
            ),
            ConditionTile(
                id: "pressure",
                symbol: "gauge.with.dots.needle.33percent",
                value: String(format: "%.0f\nhPa", conditions.pressure),
                label: "Pressure",
                trendSymbol: trendSymbol
            ),
            ConditionTile(
                id: "moon",
                symbol: moonSymbol,
                value: "\(moonDirection)\n\(moonName)",
                label: "Moon"
            )
        ]
        
        return HStack(alignment: .top, spacing: Size.small) {
            ForEach(tiles) {
                tile in
                
                conditionsDisplay(tile)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
    
    private func conditionsDisplay(_ tile: ConditionTile) -> some View {
        VStack(spacing: Size.small) {
            Image(systemName: tile.symbol)
                .font(.system(size: Size.iconFeature))
                .foregroundStyle(Color.accent)
                .frame(height: Size.iconBox)
            HStack(spacing: 0) {
                Text(tile.value)
                    .font(.besleyMedium(Font.bodySmall))
                    .monospacedDigit()
                    .multilineTextAlignment(.center)
                    .lineHeight(.normal)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                if let trendSymbol = tile.trendSymbol {
                    Image(systemName: trendSymbol)
                        .font(.system(size: Size.iconInline))
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .frame(minHeight: Size.conditionsValueMinHeight)
            Text(tile.label)
                .font(.manropeRegular(Font.label))
                .foregroundStyle(Color.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, Size.small)
    }

    private func loadWeatherData() async {
        guard let coordinate = location.coordinate else {
            return
        }
        isLoading = true
        do {
            conditions = try await fetchConditions(coordinate)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func fetchConditions(_ coord: CLLocationCoordinate2D) async throws -> Conditions {
        guard var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")
        else {
            throw URLError(.badURL)
        }
        
        components.queryItems = [
            URLQueryItem(name: "latitude", value: "\(coord.latitude)"),
            URLQueryItem(name: "longitude", value: "\(coord.longitude)"),
            URLQueryItem(name: "current", value: "temperature_2m,pressure_msl"),
            URLQueryItem(name: "hourly", value: "precipitation,pressure_msl"),
            URLQueryItem(name: "past_days", value: "3"),
            URLQueryItem(name: "forecast_days", value: "1"),
            URLQueryItem(name: "timezone", value: "auto")
        ]
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let meteoResponse = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
        
        let nowIndex = 72 + Calendar.current.component(.hour, from: .now)
        let rain = meteoResponse.hourly.precipitation[max(0, nowIndex - 72)..<nowIndex]
            .compactMap { $0 }.reduce(0, +)
        let pressure = meteoResponse.hourly.pressure_msl
        let trend = (pressure[nowIndex] ?? meteoResponse.current.pressure_msl) - (pressure[nowIndex - 3] ?? meteoResponse.current.pressure_msl)
        
        return Conditions(temperature: meteoResponse.current.temperature_2m, pressure: meteoResponse.current.pressure_msl, pressureTrend: trend, rain72h: rain, moonPhase: moonPhase(.now))
    }

    private func moonPhase(_ date: Date) -> Double {
        let reference = Date(timeIntervalSince1970: 947182440)
        let synodic = 29.530588853 * 86400
        let time = date.timeIntervalSince(reference).truncatingRemainder(dividingBy: synodic)
        return (time < 0 ? time + synodic : time) / synodic
    }

}
