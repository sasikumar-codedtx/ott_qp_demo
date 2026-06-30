import Foundation

struct ScorecardData: Codable {
    let matchId: String
    let team1: ScorecardTeam
    let team2: ScorecardTeam
    let liveOver: Double
    let currentBowler: ScorecardCurrentBowler
    let atCreaseBatters: [ScorecardAtCreaseBatter]
    let innings: [ScorecardInnings]
    let overSnapshots: [ScorecardOverSnapshot]
}

struct ScorecardTeam: Codable {
    let code: String
    let flag: String
    let score: String
    let overs: String
    let isBatting: Bool
}

struct ScorecardCurrentBowler: Codable {
    let name: String
    let figures: String
    let ballHistory: [ScorecardBall]
}

struct ScorecardBall: Codable {
    let label: String
    let type: String  // "wicket" | "boundary" | "dot" | "runs" | "extra"
}

struct ScorecardAtCreaseBatter: Codable, Identifiable {
    let name: String
    let runs: Int
    let balls: Int
    var id: String { name }
}

struct ScorecardInnings: Codable {
    let team: String
    let batters: [ScorecardBatterEntry]
    let bowlers: [ScorecardBowlerEntry]
    let extras: ScorecardExtras
    let fallOfWickets: [ScorecardFOW]
    let partnerships: [ScorecardPartnership]
    let topPerformances: [ScorecardTopPerf]
}

struct ScorecardBatterEntry: Codable, Identifiable {
    let id: String
    let name: String
    let dismissal: String
    let r: Int
    let b: Int
    let fours: Int
    let sixes: Int
    let sr: Double
    let isAtCrease: Bool
}

struct ScorecardBowlerEntry: Codable, Identifiable {
    let id: String
    let name: String
    let o: String
    let m: Int
    let r: Int
    let w: Int
    let er: Double
}

struct ScorecardExtras: Codable {
    let total: Int
    let chips: [String]
}

struct ScorecardFOW: Codable, Identifiable {
    let id: String
    let player: String
    let score: String
    let over: String
}

struct ScorecardPartnership: Codable, Identifiable {
    let id: String
    let p1Name: String
    let p1Runs: Int
    let p1Balls: Int
    let p2Name: String
    let p2Runs: Int
    let p2Balls: Int
}

struct ScorecardTopPerf: Codable, Identifiable {
    let id: String
    let mainStat: String
    let subStat: String
    let playerName: String
    let category: String  // "Batting" | "Bowling"
}

struct ScorecardOverSnapshot: Codable {
    let over: Double
    let team1Score: String
    let team2Score: String
}

extension ScorecardData {
    static func load(named filename: String) -> ScorecardData? {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(ScorecardData.self, from: data)
        else { return nil }
        return decoded
    }
}
