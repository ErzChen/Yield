import SwiftUI
import CoreLocation
import GRDB

func cellId(_ coord: CLLocationCoordinate2D) -> String {
    let y = Int(floor(coord.latitude * 2))
    let x = Int(floor(coord.longitude * 2))
    return "\(y)_\(x)"
}

// Setup
final class SpeciesDatabase {
    static let shared = SpeciesDatabase()
    static let maxRadius = 2
    
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

// Today Tab
struct LikelySpecies: Identifiable, FetchableRecord, Decodable {
    let id: Int
    let common_name: String
    let sci_name: String
    let domain: String
    let phenology: Double
    let share: Double
    let n_obs: Int
}

extension SpeciesDatabase {
    func fetchLikely(_ coordinate: CLLocationCoordinate2D, _ date: Date, _
                     minObs: Int = 5) async -> [LikelySpecies] {
        guard let queue = queue else {
            return []
        }
        
        let targetCell = cellId(coordinate)
        let targetWeek = Calendar.current.component(.weekOfYear, from: date)
        
        do {
            return try await queue.read {
                db in
                
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

// Library Tab

struct SpeciesSummary: Identifiable, FetchableRecord, Decodable, Hashable {
    let id: Int
    let common_name: String
    let sci_name: String
    let domain: String
    let url: String?
}

struct SpeciesImage: Identifiable, FetchableRecord, Decodable {
    var id: String { url }
    let url: String
    let attribution: String?
    let license: String?
}

struct Edibility {
    
}

struct SpeciesInfo: FetchableRecord, Decodable {
    let description: String?
    let habitat: String?
    let lookalikes: String?
    let edibility: String?
    let is_invasive: Bool?
}

struct WeekLevel: Identifiable, FetchableRecord, Decodable {
    var id: Int { week }
    let week: Int
    let phenology: Double
    let observations: Int
}

struct SeasonCurve {
    let levels: [WeekLevel]
    let radius: Int
    let totalObs: Int
}

func cellIds(_ coord: CLLocationCoordinate2D, _ radius: Int) -> [String] {
    let y = Int(floor(coord.latitude * 2))
    let x = Int(floor(coord.longitude * 2))
    
    var ids: [String] = []
    for dy in -radius...radius {
        for dx in -radius...radius {
            ids.append("\(y + dy)_\(x + dx)")
        }
    }
    return ids
}

extension SpeciesDatabase {
    func search(
        _ text: String,
        _ domain: String? = nil,
        _ limit: Int = 10,
        _ offset: Int = 0,
        _ nearCells: [String]? = nil
    ) async -> [SpeciesSummary] {
        guard let queue else {
            return []
        }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            return try await queue.read {
                db in
                
                var statement = """
                    SELECT s.id, s.common_name, s.sci_name, s.domain, i.url
                    FROM species s
                    LEFT JOIN species_image i ON i.species_id = s.id AND i.position = 0
                """
                var args: [any DatabaseValueConvertible] = []
                var clauses: [String] = []
                if !trimmed.isEmpty {
                    guard let pattern = FTS5Pattern(matchingAllPrefixesIn: trimmed) else {
                        return []
                    }
                    statement += " JOIN species_fts ON species_fts.rowid = s.id"
                    clauses.append("species_fts MATCH ?")
                    args.append(pattern)
                }
                if let domain {
                    clauses.append("s.domain = ?")
                    args.append(domain)
                }
                if let nearCells, !nearCells.isEmpty {
                    clauses.append("""
                        EXISTS (SELECT 1 FROM seasonality se
                                WHERE se.species_id = s.id
                                AND se.cell_id IN (\(databaseQuestionMarks(count: nearCells.count))))
                        """)
                    for cell in nearCells {
                        args.append(cell)
                    }
                }
                if !clauses.isEmpty {
                    statement += " WHERE " + clauses.joined(separator: " AND ")
                }
                statement += trimmed.isEmpty
                    ? " ORDER BY s.common_name COLLATE NOCASE, s.id"
                    : " ORDER BY rank"
                statement += " LIMIT ? OFFSET ?"
                args.append(limit)
                args.append(offset)
                
                return try SpeciesSummary.fetchAll(db, sql: statement, arguments: StatementArguments(args))
            }
        } catch {
            print("Search error:", error)
            return []
        }
    }
    
    func images(_ speciesId: Int) async -> [SpeciesImage] {
        guard let queue else {
            return []
        }
        do {
            return (try await queue.read {
                db in
                
                try SpeciesImage.fetchAll(db, sql: """
                    SELECT url, attribution, license 
                    FROM species_image 
                    WHERE species_id = ? ORDER BY position LIMIT 5
                """, arguments: [speciesId])
            })
        } catch {
            print("Image fetch error:", error)
            return []
        }
    }
    
    func info(_ speciesId: Int) async -> SpeciesInfo? {
        guard let queue else {
            return nil
        }
        do {
            return try await queue.read {
                db in
                
                try SpeciesInfo.fetchOne(db, sql: """
                        SELECT description, habitat, lookalikes, edibility, is_invasive
                        FROM curated 
                        WHERE species_id = ?
                    """, arguments: [speciesId])
            }
        } catch {
            print("Info fetch error:", error)
            return nil
        }
    }
    
    func seasonCurve(
        _ speciesID: Int,
        _ coordinate: CLLocationCoordinate2D,
        _ minObs: Int = 10,
        _ maxRadius: Int = 2
    ) async -> SeasonCurve {
        guard let queue else {
            return SeasonCurve(levels: [], radius: 0, totalObs: 0)
        }
        
        var best = SeasonCurve(levels: [], radius: 0, totalObs: 0)

        for radius in 0...maxRadius {
            let cells = cellIds(coordinate, radius)
            do {
                let rows = try await queue.read {
                    db in
                    
                    try WeekLevel.fetchAll(db, sql: """
                        SELECT week,
                               SUM(phenology * n_obs) / SUM(n_obs) AS phenology,
                               SUM(n_obs) AS observations
                        FROM seasonality
                        WHERE species_id = ?
                          AND cell_id IN (\(databaseQuestionMarks(count: cells.count)))
                        GROUP BY week
                        HAVING SUM(n_obs) > 0
                        ORDER BY week
                    """, arguments: StatementArguments([speciesID] + cells))
                }
                var total = 0
                for row in rows {
                    total += row.observations
                }
                best = SeasonCurve(levels: rows, radius: radius, totalObs: total)
                if total >= minObs {
                    return best
                }
            } catch {
                print("seasonCurve error:", error)
                return best
            }
        }
        return best
    }
}
