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

@Observable final class SpotStore {
    var spots: [Spot] = []
    var sightings: [Sighting] = []
    let shared = UserDatabase.shared

    func load() async {
        spots = (try? await shared.fetchSpots()) ?? []
        sightings = (try? await shared.fetchSightings()) ?? []
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
