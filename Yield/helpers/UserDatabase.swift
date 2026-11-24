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
        migrator.registerMigration("v1") {
            db in

            try db.create(table: "spot") {
                table in

                table.autoIncrementedPrimaryKey("id")
                table.column("name", .text).notNull()
                table.column("latitude", .double).notNull()
                table.column("longitude", .double).notNull()
                table.column("created_at", .datetime).notNull()
            }
            
            try db.create(table: "visit") {
                table in

                table.autoIncrementedPrimaryKey("id")
                table.column("spot_id", .integer)
                    .notNull()
                    .indexed()
                    .references("spot", onDelete: .cascade)
                table.column("date", .datetime).notNull()
                table.column("domains", .text).notNull()
            }
            
            try db.create(table: "find") {
                table in

                table.autoIncrementedPrimaryKey("id")
                table.column("visit_id", .integer)
                    .notNull()
                    .indexed()
                    .references("visit", onDelete: .cascade)
                table.column("species_id", .integer).notNull()
                table.column("species_name", .text).notNull()
                table.column("amount", .integer).notNull()
            }
        }
        try! migrator.migrate(queue)
    }
}

// Spots
extension UserDatabase {
    func fetchSpots() async throws -> [Spot] {
        return try await queue.read {
            db in

            try Spot.fetchAll(db)
        }
    }

    func addSpot(
        _ name: String,
        _ coordinate: CLLocationCoordinate2D
    ) async throws -> Spot {
        try await queue.write {
            db in

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

// Visits
extension UserDatabase {
    func fetchVisits() async throws -> [Visit] {
        try await queue.read {
            db in
            
            try Visit
                .order(Column("date").desc)
                .fetchAll(db)
        }
    }
    
    func fetchFinds() async throws -> [Find] {
        try await queue.read {
            db in
            
            try Find
                .fetchAll(db)
        }
    }
    
    func addVisit(
        spotId: Int64,
        domains: String,
        date: Date,
        finds: [(speciesId: Int, speciesName: String, amount: Int)]
    ) async throws -> Visit {
        try await queue.write {
            db in
            
            var visit = Visit(
                id: nil,
                spotId: spotId,
                date: date,
                domains: domains
            )
            try visit.insert(db)
            
            guard let visitId = visit.id else {
                throw DatabaseError(message: "Visit has no id after insert")
            }
            
            for item in finds {
                var find = Find(
                    visitId: visitId,
                    speciesId: item.speciesId,
                    speciesName: item.speciesName,
                    amount: item.amount
                )
                
                try find.insert(db)
            }
            
            return visit
        }
    }
}
