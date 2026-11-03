import SwiftUI
import CoreLocation
import GRDB

func cellID(_ coord: CLLocationCoordinate2D) -> String {
    let y = Int(floor(coord.latitude * 2))
    let x = Int(floor(coord.longitude * 2))
    return "\(y)_\(x)"
}

func seasonWeek(_ date: Date) -> Int {
    let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
    return min(52, (dayOfYear - 1) / 7 + 1)
}

// Setup
final class SpeciesDatabase {
    static let shared = SpeciesDatabase()
    
    private let queue: DatabaseQueue?
    
    private init() {
        guard let path = Bundle.main.path(forResource: "reference", ofType: "sqlite") else {
            print("reference.sqlite is not in the bundle")
            queue = nil
            return
        }
        var config = Configuration()
        config.readonly = true
        queue = try? DatabaseQueue(path: path, configuration: config)
    }
}

struct LikelySpecies: Identifiable, FetchableRecord, Decodable {
    let id: Int
    let common_name: String
    let sci_name: String
    let domain: String
    let phenology: Double
    let share: Double
    let n_obs: Int
}
 
// Today Tab
extension SpeciesDatabase {
    func fetchLikely(_ coordinate: CLLocationCoordinate2D, _ date: Date, _
                     minObs: Int = 5) async -> [LikelySpecies] {
        guard let queue = queue else {
            return []
        }
        
        let targetCell = cellID(coordinate)
        let targetWeek = seasonWeek(date)
        
        do {
            return try await queue.read { db in
                try LikelySpecies.fetchAll(db, sql: """
                    SELECT * FROM (
                        SELECT s.id, s.common_name, s.sci_name, s.domain, se.phenology, se.share, se.n_obs,
                               ROW_NUMBER() OVER (
                                   PARTITION BY s.domain
                                   ORDER BY se.phenology * se.share * (se.n_obs * 1.0 / (se.n_obs + 10)) DESC
                               ) AS rank
                        FROM seasonality se
                        JOIN species s ON s.id = se.species_id
                        WHERE se.cell_id = ? AND se.week = ? AND se.n_obs >= ?
                    )
                    WHERE rank <= 3
                    ORDER BY phenology DESC
                """, arguments: [targetCell, targetWeek, minObs])
            }
        } catch {
            print("Database read error:", error)
            return []
        }
        
        
    }
}
