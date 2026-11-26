#if DEBUG
import Foundation
import CoreLocation

func sampleSpecies(_ name: String) async -> SpeciesSummary? {
    let results = await SpeciesDatabase.shared.search(name, nil, 5, 0, nil)
    return results.first {
        $0.common_name.lowercased() == name.lowercased()
    }
}

func checkSample() async {
    let names = [
        "American Yellow Morel",
        "Golden Chanterelle",
        "Ostrich Fern",
        "Snowshoe Hare",
        "Largemouth Bass"
    ]
    
    for name in names {
        if let result = await sampleSpecies(name) {
            print(result.id, result.common_name, result.domain)
        } else {
            print("missing")
        }
    }
    print("sample visits:", sampleVisits.count)
}

let morel = "American Yellow Morel"
let chanterelle = "Golden Chanterelle"
let fern = "Ostrich Fern"
let hare = "Snowshoe Hare"
let bass = "Largemouth Bass"

struct SampleVisit {
    let year: Int
    let month: Int
    let day: Int
    let domains: String
    let finds: [(name: String, amount: Int)]
}

private func v(
    _ year: Int,
    _ month: Int,
    _ day: Int,
    _ domains: String,
    _ finds: (name: String, amount: Int)...
) -> SampleVisit {
    SampleVisit(year: year, month: month, day: day, domains: domains, finds: finds)
}

let sampleVisits: [SampleVisit] = [
    v(2023, 4, 29, "fungi", (morel, 3)),
    v(2023, 5, 6, "fungi", (morel, 5)),
    v(2023, 5, 20, "fungi"),
    v(2024, 4, 26, "fungi"),
    v(2024, 5, 3, "fungi", (morel, 4)),
    v(2024, 5, 11, "fungi"),
    v(2024, 5, 11, "fungi", (morel, 6)),
    v(2025, 4, 24, "fungi"),
    v(2025, 5, 2, "fungi,plant", (morel, 5), (fern, 8)),
    v(2025, 5, 14, "fungi", (morel, 2)),
    v(2026, 4, 27, "fungi", (morel, 4)),
    v(2026, 5, 8, "fungi,plant", (morel, 7), (fern, 10)),
    v(2026, 7, 12, "fungi"),

    v(2024, 7, 20, "fungi", (chanterelle, 2)),
    v(2024, 8, 10, "fungi"),
    v(2024, 8, 24, "fungi", (chanterelle, 5)),
    v(2025, 7, 26, "fungi", (chanterelle, 3)),
    v(2025, 8, 16, "fungi"),
    v(2025, 9, 6, "fungi"),
    v(2026, 7, 25, "fungi", (chanterelle, 4)),
    v(2026, 8, 15, "fungi", (chanterelle, 6)),
    v(2026, 9, 5, "fungi"),

    v(2025, 1, 18, "animal", (hare, 1)),
    v(2026, 1, 24, "animal"),
    v(2026, 2, 7, "animal", (hare, 2)),

    v(2024, 6, 8, "fish", (bass, 2)),
    v(2024, 6, 29, "fish"),
    v(2025, 6, 14, "fish", (bass, 3)),
    v(2025, 7, 5, "fish", (bass, 1)),
    v(2026, 6, 6, "fish"),
    v(2026, 6, 20, "fish", (bass, 4)),
]

func addSampleData(to store: SpotStore, at coordinate: CLLocationCoordinate2D) async {
    guard !store.spots.contains(where: { $0.name == "Sample spot" }) else {
        return
    }

    var species: [String: SpeciesSummary] = [:]
    for name in [morel, chanterelle, fern, hare, bass] {
        if let found = await sampleSpecies(name) {
            species[name] = found
        }
    }

    do {
        let spot = try await UserDatabase.shared.addSpot("Sample spot", coordinate)
        guard let spotId = spot.id else {
            return
        }

        for sampleVisit in sampleVisits {
            let date = Calendar.current.date(from: DateComponents(
                year: sampleVisit.year,
                month: sampleVisit.month,
                day: sampleVisit.day,
                hour: 9
            ))!
            
            let newFinds: [NewFind] = sampleVisit.finds.compactMap{
                guard let summary = species[$0.name] else {
                    return nil
                }
                
                return NewFind(
                    speciesId: summary.id,
                    speciesName: $0.name,
                    speciesDomain: summary.domain,
                    amount: $0.amount
                )
            }
            
            let _ = try await UserDatabase.shared.addVisit(
                spotId: spotId,
                domains: sampleVisit.domains,
                date: date,
                finds: newFinds
            )
        }

    } catch {
        print("Sample data error:", error)
    }

    await store.load()
}

#endif
