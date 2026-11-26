import Foundation

struct Reliability {
    static let minimumDays = 3
    
    let found: Int
    let total: Int
    let foundWeight: Double
    let totalWeight: Double
    
    var hasEnoughData: Bool {
        total >= Reliability.minimumDays
    }
    var score: Double {
        Double(foundWeight + 1) / Double(totalWeight + 2)
    }
    var interval: (low: Double, high: Double) {
        wilsonInterval(successes: foundWeight, trials: totalWeight)
    }
}

struct SpeciesReliability: Identifiable {
    let speciesId: Int
    let name: String
    let domain: String
    let reliability: Reliability
    let typicalAmount: Int?
    let timing: TimingWindow?
    
    var id: Int { speciesId }
}

func reliability(
    speciesId: Int,
    domain: String,
    visits: [Visit],
    finds: [Find],
    phenology: [Int: Double]? = nil,
    minPhenology: Double = 0.2
) -> Reliability {
    let relevant = visits.filter {
        $0.domains.split(separator: ",").map(String.init).contains(domain)
    }
    
    let foundVisitIds = Set(
        finds
            .filter { $0.speciesId == speciesId }
            .map { $0.visitId }
    )
    
    let days = Dictionary(grouping: relevant) {
        Calendar.current.startOfDay(for: $0.date)
    }
    
    var found = 0
    var total = 0
    var foundWeight = 0.0
    var totalWeight = 0.0
    
    for dayVisits in days.values {
        let hasFind = dayVisits.contains {
            visit in
            
            guard let id = visit.id else {
                return false
            }
            return foundVisitIds.contains(id)
        }
        
        if hasFind {
            found += 1
            total += 1
            foundWeight += 1
            totalWeight += 1
            continue
        }
        
        var weight = 1.0
        if let phenology {
            weight = dayVisits.map { phenology[currentWeek($0.date)] ?? 0 }.max() ?? 0
        }
        if weight < minPhenology {
            continue
        }
        
        total += 1
        totalWeight += weight
    }
    
    return Reliability(
        found: found,
        total: total,
        foundWeight: foundWeight,
        totalWeight: totalWeight
    )
}

func speciesReliabilities(
    visits: [Visit],
    finds: [Find],
    phenology: [Int: [Int: Double]] = [:]
) -> [SpeciesReliability] {
    let visitIds = Set(visits.compactMap { $0.id })
    let spotFinds = finds.filter { visitIds.contains($0.visitId) }
    let bySpecies = Dictionary(grouping: spotFinds) { $0.speciesId }
    
    return bySpecies.compactMap {
        (speciesId, group) in
        
        guard let first = group.first else {
            return nil
        }
        
        let amount = typicalAmount(
            speciesId: speciesId,
            visits: visits,
            finds: spotFinds
        )
        
        let timing = timingWindow(
            speciesId: speciesId,
            visits: visits,
            finds: spotFinds
        )
        
        let stats = reliability(
            speciesId: speciesId,
            domain: first.speciesDomain,
            visits: visits,
            finds: spotFinds,
            phenology: phenology[speciesId]
        )
        
        return SpeciesReliability(
            speciesId: speciesId,
            name: first.speciesName,
            domain: first.speciesDomain,
            reliability: stats,
            typicalAmount: amount,
            timing: timing
        )
    }
    .sorted {
        first, second in

        if first.reliability.score != second.reliability.score {
            return first.reliability.score > second.reliability.score
        }
        if first.reliability.total != second.reliability.total {
            return first.reliability.total > second.reliability.total
        }
        return first.name < second.name
    }
}

func typicalAmount(
    speciesId: Int,
    visits: [Visit],
    finds: [Find]
) -> Int? {
    let days = Dictionary(grouping: visits) {
        Calendar.current.startOfDay(for: $0.date)
    }
    
    let perDay: [Int] = days.values.compactMap {
        dayVisits in
        
        let ids = Set(dayVisits.compactMap { $0.id })
        let total = finds.filter {
            $0.speciesId == speciesId && ids.contains($0.visitId)
        }.map {
            $0.amount
        }.reduce(0, +)
        
        return total > 0 ? total : nil
    }
    
    return perDay.isEmpty ? nil : perDay.sorted()[perDay.count / 2]
}

struct TimingWindow {
    let start: Int
    let end: Int
    let years: Int
}

func dayOfYear(_ date: Date) -> Int {
    return Calendar.current.ordinality(
        of: .day,
        in: .year,
        for: date
    ) ?? 1
}

func dayLabel(_ day: Int) -> String {
    let start = Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 1))!
    let date = Calendar.current.date(byAdding: .day, value: day - 1, to: start)!
    return date.formatted(.dateTime.month(.abbreviated).day())
}

func median(_ num: [Int]) -> Int? {
    guard !num.isEmpty else {
        return nil
    }
    return num.sorted()[num.count / 2]
}

func timingWindow(
    speciesId: Int,
    visits: [Visit],
    finds: [Find]
) -> TimingWindow? {
    let foundVisitIds = Set(
        finds.filter {
            $0.speciesId == speciesId
        }.map {
            $0.visitId
        }
    )
    
    let dates = visits.filter {
        visit in
        
        guard let id = visit.id else {
            return false
        }
        return foundVisitIds.contains(id)
    }.map { $0.date }
    
    let byYear = Dictionary(grouping: dates) {
        Calendar.current.component(.year, from: $0)
    }
    
    let starts = byYear.values.compactMap { $0.min() }.map(dayOfYear)
    let ends = byYear.values.compactMap { $0.max() }.map(dayOfYear)

    guard let start = median(starts), let end = median(ends) else {
        return nil
    }

    return TimingWindow(start: start, end: end, years: byYear.count)
}

func wilsonInterval(
    successes: Double,
    trials: Double,
    zScore: Double = 1.96
) -> (low: Double, high: Double) {
    guard trials > 0 else {
        return (0, 1)
    }
    
    let probability = successes / trials
    let zSqrd = zScore * zScore
    let denominator = 1 + zSqrd / trials
    let center = (probability + zSqrd / (2 * trials)) / denominator
    let margin = zScore * sqrt(probability * (1 - probability) / trials + zSqrd / (4 * trials * trials)) / denominator
    
    return (max(0, center - margin), min (1, center + margin))
}

#if DEBUG
func daysAgo(_ n: Int) -> Date {
    return Calendar.current.date(byAdding: .day, value: -n, to: .now)!
}

func checkReliability() {
    let visits = [
        Visit(id: 1, spotId: 1, date: daysAgo(10), domains: "fungi"),
        Visit(id: 2, spotId: 1, date: daysAgo(7), domains: "fungi"),
        Visit(id: 3, spotId: 1, date: daysAgo(5), domains: "fish"),
        Visit(id: 4, spotId: 1, date: daysAgo(3), domains: "fungi,plant"),
        Visit(id: 5, spotId: 1, date: daysAgo(3), domains: "fungi"),
    ]
    
    let finds = [
        Find(
            id: 1,
            visitId: 1,
            speciesId: 100,
            speciesName: "Morel",
            speciesDomain: "fungi",
            amount: 1
        ),
        Find(
            id: 2,
            visitId: 4,
            speciesId: 100,
            speciesName: "Morel",
            speciesDomain: "fungi",
            amount: 1
        ),
        Find(
            id: 3,
            visitId: 5,
            speciesId: 200,
            speciesName: "Chanterelle",
            speciesDomain: "fungi",
            amount: 1
        ),
        Find(
            id: 4,
            visitId: 99,
            speciesId: 100,
            speciesName: "Morel",
            speciesDomain: "fungi",
            amount: 1
        ),
    ]
    
    let morel = reliability(speciesId: 100, domain: "fungi", visits: visits, finds: finds)
    let chanterelle = reliability(speciesId: 200, domain: "fungi", visits: visits, finds: finds)
    print("morel", morel.found, morel.total)
    print("chanterelle", chanterelle.found, chanterelle.total)
    for row in speciesReliabilities(visits: visits, finds: finds) {
        print(row.name, row.reliability.found, row.reliability.total)
    }
    let half = Dictionary(uniqueKeysWithValues: (1...52).map { ($0, 0.5) })

    let a = reliability(speciesId: 100, domain: "fungi", visits: visits, finds: finds)
    let b = reliability(speciesId: 100, domain: "fungi", visits: visits, finds: finds, phenology: [:])
    let c = reliability(speciesId: 100, domain: "fungi", visits: visits, finds: finds, phenology: half)

    print(a.found, a.total, a.score)
    print(b.found, b.total, b.score)
    print(c.found, c.total, c.score)
    for row in speciesReliabilities(visits: visits, finds: finds, phenology: [100: half]) {
        print(row.name, row.reliability.found, row.reliability.total, row.reliability.score)
    }
    print("morel amount", typicalAmount(speciesId: 100, visits: visits, finds: finds) as Any)
    print(wilsonInterval(successes: 3, trials: 3))
    print(wilsonInterval(successes: 9, trials: 9))
    print(wilsonInterval(successes: 2, trials: 4))
    print(wilsonInterval(successes: 0, trials: 0))
}
#endif
