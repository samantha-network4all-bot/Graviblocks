import Foundation

enum GamePhase: String, Codable {
    case menu, playing, paused, over, finished
}

enum GameMode: String, Codable {
    case marathon, sprint
}

struct ActivePiece: Codable {
    let type: String
    let rotation: Int
    let cells: [[Int]]
}

struct GameState: Codable {
    var phase: GamePhase = .menu
    var mode: GameMode = .marathon
    var seed: UInt64 = 1
    var tick: Int = 0
    var level: Int = 1
    var lines: Int = 0
    var score: Int = 0
    var combo: Int = 0
    var backToBack: Bool = false
    var elapsedTicks: Int = 0
    var active: ActivePiece? = nil
    var ghostCells: [[Int]] = []
    var hold: String? = nil
    var canHold: Bool = true
    var next: [String] = []
    var lockTimer: Int = 0
    var lockResets: Int = 0
    var topOut: Bool = false
    var audioEvents: [String] = []
    var board: [[String]] = Array(repeating: Array(repeating: ".", count: Metrics.visibleRows + Metrics.bufferRows), count: Metrics.cols)
}
