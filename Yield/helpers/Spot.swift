import SwiftUI
import CoreLocation
import GRDB

struct Sighting: Identifiable, Codable, FetchableRecord, MutablePersistableRecord {
    var id: Int64?
    var spotId: Int64
    var speciesId: Int
    var speciesName: String
    var amount: Int
    var date: Date

    enum CodingKeys: String, CodingKey {
        case id, amount, date
        case spotId = "spot_id"
        case speciesId = "species_id"
        case speciesName = "species_name"
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

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

struct Find: Codable, FetchableRecord, MutablePersistableRecord {
    var id: Int64?
    var visitId: Int64
    var speciesId: Int
    var speciesName: String
    var amount: Int
    
    enum CodingKeys: String, CodingKey {
        case id, amount
        case visitId = "visit_id"
        case speciesId = "species_id"
        case speciesName = "species_name"
    }
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

@Observable final class SpotStore {
    var spots: [Spot] = []
    var sightings: [Sighting] = []
    var visits: [Visit] = []
    var finds: [Find] = []
    let shared = UserDatabase.shared

    func load() async {
        spots = (try? await shared.fetchSpots()) ?? []
        sightings = (try? await shared.fetchSightings()) ?? []
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

    func sightings(for spot: Spot) -> [Sighting] {
        guard let id = spot.id else {
            return []
        }
        return sightings.filter { $0.spotId == id }
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
        finds newFinds: [(speciesId: Int, speciesName: String, amount: Int)]
    ) async {
        guard let spotId = spot.id else {
            return
        }
        do {
            let new = try await shared.addVisit(
                spotId: spotId,
                domains: domains,
                date: .now,
                finds: newFinds
            )
            finds = try await shared.fetchFinds()
            visits.insert(new, at: 0)
        } catch {
            print("Error creating visit:", error)
        }
    }

    func addSighting(to spot: Spot, species: SpeciesSummary, amount: Int) async {
        guard let spotId = spot.id else {
            return
        }
        do {
            let new = try await shared.addSighting(
                spotId: spotId,
                speciesId: species.id,
                speciesName: species.common_name,
                amount: amount,
                date: .now
            )
            sightings.insert(new, at: 0)
        } catch {
            print("Error creating sighting:", error)
        }
    }
}
