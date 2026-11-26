import Foundation
import CoreLocation
import GRDB

struct Spot: Identifiable, Codable, Hashable, FetchableRecord, MutablePersistableRecord {
    var id: Int64?
    var name: String
    var latitude: Double
    var longitude: Double
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, latitude, longitude
        case createdAt = "created_at"
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

struct Visit: Identifiable, Codable, FetchableRecord, MutablePersistableRecord {
    var id: Int64?
    var spotId: Int64
    var date: Date
    var domains: String
    
    enum CodingKeys: String, CodingKey {
        case id, date, domains
        case spotId = "spot_id"
    }
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

typealias NewFind = (
    speciesId: Int,
    speciesName: String,
    speciesDomain: String,
    amount: Int
)

struct Find: Codable, FetchableRecord, MutablePersistableRecord {
    var id: Int64?
    var visitId: Int64
    var speciesId: Int
    var speciesName: String
    var speciesDomain: String
    var amount: Int
    
    enum CodingKeys: String, CodingKey {
        case id, amount
        case visitId = "visit_id"
        case speciesId = "species_id"
        case speciesName = "species_name"
        case speciesDomain = "species_domain"
    }
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

@Observable final class SpotStore {
    var spots: [Spot] = []
    var visits: [Visit] = []
    var finds: [Find] = []
    var phenology: [Int64: [Int: [Int: Double]]] = [:]
    let shared = UserDatabase.shared

    func load() async {
        spots = (try? await shared.fetchSpots()) ?? []
        visits = (try? await shared.fetchVisits()) ?? []
        finds = (try? await shared.fetchFinds()) ?? []
    }

    func add(_ name: String, _ coordinate: CLLocationCoordinate2D) async {
        do {
            let newSpot = try await shared.addSpot(name, coordinate)
            spots.append(newSpot)
        } catch {
            print("Error creating new spot:", error)
        }
    }
    
    func visits(for spot: Spot) -> [Visit] {
        guard let id = spot.id else {
            return []
        }
        return visits.filter { $0.spotId == id }
    }
    
    func finds(for visit: Visit) -> [Find] {
        guard let id = visit.id else {
            return []
        }
        return finds.filter { $0.visitId == id }
    }
    
    func addVisit(
        to spot: Spot,
        domains: String,
        date: Date = .now,
        finds newFinds: [NewFind]
    ) async {
        guard let spotId = spot.id else {
            return
        }
        do {
            let new = try await shared.addVisit(
                spotId: spotId,
                domains: domains,
                date: date,
                finds: newFinds
            )
            finds = try await shared.fetchFinds()
            visits.insert(new, at: 0)
        } catch {
            print("Error creating visit:", error)
        }
    }
    
    func reliabilities(for spot: Spot) -> [SpeciesReliability] {
        guard let id = spot.id else {
            return []
        }
        return speciesReliabilities(
            visits: visits(for: spot),
            finds: finds,
            phenology: phenology[id] ?? [:]
        )
    }
    
    func loadPhenology(for spot: Spot) async {
        guard let spotId = spot.id else {
            return
        }
        
        var loaded: [Int: [Int: Double]] = [:]
        
        for id in reliabilities(for: spot).map(\.speciesId) {
            let curve = await SpeciesDatabase.shared.seasonCurve(id, spot.coordinate)
            
            if curve.totalObs >= 10 {
                loaded[id] = Dictionary(uniqueKeysWithValues: curve.levels.map {
                    ($0.week, $0.phenology)
                })
            }
        }
        
        phenology[spotId] = loaded
    }
}
