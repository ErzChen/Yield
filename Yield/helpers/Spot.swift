import SwiftUI
import CoreLocation
import GRDB

struct Spot: Identifiable, Codable, FetchableRecord, MutablePersistableRecord {
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
    let shared = UserDatabase.shared
    
    func load() async {
        spots = (try? await shared.fetchSpots()) ?? []
    }
    
    func add(_ name: String, _ coordinate: CLLocationCoordinate2D) async {
        do {
            let newSpot = try await shared.addSpot(name, coordinate)
            spots.append(newSpot)
        } catch {
            print("Error creating new spot:", error)
        }
    }
}
