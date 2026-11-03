import GRDB
import CoreLocation

final class UserDatabase {
    static let shared = UserDatabase()
    private let queue: DatabaseQueue
    
    private init() {
        let supportDir = try! FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        
        let dbURL = supportDir.appendingPathComponent("user.sqlite")
        queue = try! DatabaseQueue(path: dbURL.path)
        
        var migrator = DatabaseMigrator()
        #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
        #endif
        migrator.registerMigration("v1") { db in
            try db.create(table: "spot") { table in
                table.autoIncrementedPrimaryKey("id")
                table.column("name", .text).notNull()
                table.column("latitude", .double).notNull()
                table.column("longitude", .double).notNull()
                table.column("created_at", .datetime).notNull()
            }
        }
        try! migrator.migrate(queue)
    }
}

// Spots
extension UserDatabase {
    func fetchSpots() async throws -> [Spot] {
        return try await queue.read {
            db in try Spot.fetchAll(db)
        }
    }
    
    func addSpot(
        _ name: String,
        _ coordinate: CLLocationCoordinate2D
    ) async throws -> Spot {
        try await queue.write { db in
            var spot = Spot(
                id: nil,
                name: name,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                createdAt: .now
            )
            try spot.insert(db)
            return spot
        }
    }
}
