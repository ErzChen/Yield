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

struct TodayTab: View {
    // Placeholder for testing
    var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 43.5448, longitude: -80.2482)
    
    @State private var conditions: Conditions?
    @State private var errorMessage: String?
    @State private var isLoading = true
    
    var body: some View {
        VStack(alignment: .leading) {
            conditionsCard
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            await loadWeatherData()
        }
    }
    
    private var conditionsCard: some View {
        Group {
            if let conditions {
                let trendSymbol: String = conditions.pressureTrend > 1
                    ? "arrow.up"
                    : (conditions.pressureTrend < -1
                       ? "arrow.down"
                       : "arrow.right"
                    )
                let trendColor: Color = conditions.pressureTrend > 1
                    ? Color.Palette.green
                    : (conditions.pressureTrend < -1
                       ? Color.Palette.brown
                       : Color.Palette.darkBrown.opacity(0.6)
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
                let moonName = [
                    "New",
                    "Crescent",
                    "Quarter",
                    "Gibbous",
                    "Full",
                    "Gibbous",
                    "Quarter",
                    "Crescent"
                ][moonIndex]
                let moonDirection = [
                    "Moon",
                    "Waxing",
                    "Waxing",
                    "Waxing",
                    "Moon",
                    "Waning",
                    "Waning",
                    "Waning"
                ][moonIndex]
                
                
                HStack(alignment: .top, spacing: 8) {
                    conditionsDisplay(
                        symbol: "thermometer.medium",
                        value: String(format: "%.0f°", conditions.temperature),
                        label: "Temp"
                    )
                    conditionsDisplay(
                        symbol: "cloud.rain",
                        value: String(format: "%.0f mm", conditions.rain72h),
                        label: "Rain (3 days)"
                    )
                    conditionsDisplay(
                        symbol: "gauge.with.dots.needle.33percent",
                        value: String(format: "%.0f", conditions.pressure),
                        label: "hPa",
                        trendSymbol: trendSymbol,
                        trendColor: trendColor
                    )
                    conditionsDisplay(
                        symbol: moonSymbol,
                        value: moonName,
                        label: moonDirection,
                    )
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(8)
                .frame(maxWidth: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.Palette.lightBrown.opacity(0.4), lineWidth: 1)
                        )
                        .shadow(color: Color.Palette.darkBrown.opacity(0.1), radius: 8, y: 3)
                }
                .padding(.horizontal, 12)
            } else if isLoading {
                // Add custom loading
            } else {
                VStack {
                    Image(systemName: "icloud.slash")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.Palette.darkBrown.opacity(0.6))
                    Text(errorMessage == "" ? "Conditions unavailable" : errorMessage ?? "Conditions unavailable")
                        .font(.manropeBold(size: 16))
                        .foregroundStyle(Color.Palette.darkBrown.opacity(0.6))
                }
                .frame(maxWidth: .infinity, minHeight: 80)
                .padding(8)
                .frame(maxWidth: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.Palette.lightBrown.opacity(0.35), lineWidth: 1)
                        )
                        .shadow(color: Color.Palette.darkBrown.opacity(0.08), radius: 8, y: 3)
                }
                .padding(.horizontal, 12)
            }
        }
    }
    
    private func conditionsDisplay(
        symbol: String,
        value: String,
        label: String,
        trendSymbol: String? = nil,
        trendColor: Color = Color.Palette.darkBrown,
    ) -> some View {
        VStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 24))
                .foregroundStyle(Color.Palette.green)
                .frame(height: 28)
            HStack(spacing: 0) {
                Text(value)
                    .font(.besleyBold(size: Font.display))
                    .foregroundStyle(Color.Palette.darkBrown)
                    .lineLimit(1)
                if let trendSymbol {
                    Image(systemName: trendSymbol)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(trendColor)
                }
            }
            .frame(height: 32)
            Text(label)
                .font(.manropeRegular(size: Font.label))
                .foregroundStyle(Color.Palette.darkBrown.opacity(0.6))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(6)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.background.opacity(0.55))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.Palette.lightBrown.opacity(0.25), lineWidth: 1)
                )
        }
    }
    
    private func loadWeatherData() async {
        do {
            isLoading = true
            conditions = try await fetchConditions(coord: coordinate)
            errorMessage = ""
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    private func fetchConditions(coord: CLLocationCoordinate2D) async throws -> Conditions {
        guard var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast") else {
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
        
        let (data, response) = try await URLSession.shared.data(from: url)
        let meteoResponse = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
        
        let nowIndex = 72 + Calendar.current.component(.hour, from: .now)
        let rain = meteoResponse.hourly.precipitation[max(0, nowIndex - 72)..<nowIndex]
            .compactMap { $0 }.reduce(0, +)
        let pressure = meteoResponse.hourly.pressure_msl
        let trend = (pressure[nowIndex] ?? meteoResponse.current.pressure_msl) - (pressure[nowIndex - 3] ?? meteoResponse.current.pressure_msl)
        
        return Conditions(temperature: meteoResponse.current.temperature_2m, pressure: meteoResponse.current.pressure_msl, pressureTrend: trend, rain72h: rain, moonPhase: moonPhase(date: .now))
    }
    
    func moonPhase(date: Date) -> Double {
        let reference = Date(timeIntervalSince1970: 947182440)
        let synodic = 29.530588853 * 86400
        let time = date.timeIntervalSince(reference).truncatingRemainder(dividingBy: synodic)
        return (time < 0 ? time + synodic : time) / synodic
    }
}
