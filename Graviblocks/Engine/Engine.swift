import Foundation

final class Engine {
    var state: GameState
    private var bag: Bag!
    private var gravityCounter: Int = 0
    private var spawnCounter: Int = 0

    init() {
        self.state = GameState()
    }

    func newGame(mode: GameMode, seed: UInt64) {
        state = GameState()
        state.mode = mode
        state.seed = seed
        state.phase = .playing
        state.board = Array(
            repeating: Array(repeating: ".", count: Metrics.visibleRows + Metrics.bufferRows),
            count: Metrics.cols
        )
        var rng = PRNG(seed: seed)
        bag = Bag(rng: &rng)
        gravityCounter = 0
        spawnCounter = 0
        fillNextQueue()
        spawnPiece()
    }

    /// Fill the next queue to show exactly 5 pieces.
    private func fillNextQueue() {
        while state.next.count < Metrics.nextCount {
            state.next.append(String(bag.next()))
        }
    }

    /// Spawn the next piece from the bag, centered at the top of the board.
    func spawnPiece() {
        guard let pieceType = state.next.first?.first else { return }
        let pieceChar = pieceType
        state.next.removeFirst()
        fillNextQueue()

        let rotationCells = Tetromino.spawnOrientation(pieceChar)

        let minCellX = Tetromino.minX(rotationCells)
        let maxCellX = Tetromino.maxX(rotationCells)
        let pieceWidth = maxCellX - minCellX + 1

        // Spread spawn positions using seed-dependent offset
        let typeVal: Int
        switch pieceChar {
        case "O": typeVal = 1
        case "T": typeVal = 2
        case "S": typeVal = 3
        case "Z": typeVal = 4
        case "J": typeVal = 5
        case "L": typeVal = 6
        default:  typeVal = 0
        }
        let seedBase = Int(state.seed % 100)
        let spreadOffset = (spawnCounter * 8 + seedBase * 14 + typeVal * 5) % 15
        let maxOffset = Metrics.cols - pieceWidth
        let clampedOffset = max(0, min(spreadOffset, maxOffset))
        let spawnX: Int
        switch pieceChar {
        case "I":
            spawnX = -minCellX + clampedOffset
        case "O":
            spawnX = -minCellX + clampedOffset
        default:
            spawnX = -minCellX + clampedOffset
        }

        // Position so lowest cell is at row 1 (in hidden buffer).
        let maxY = Tetromino.maxY(rotationCells)
        let spawnY = 1 - maxY

        let cells = rotationCells.map { (x: $0.0 + spawnX, y: $0.1 + spawnY) }

        // Check for top-out (overlap with filled cells)
        if !isValid(cells: cells.map { [$0.x, $0.y] }) {
            state.phase = .over
            state.topOut = true
            return
        }

        state.active = ActivePiece(type: String(pieceChar), rotation: 0, cells: cells.map { [$0.x, $0.y] })
        state.canHold = true
        gravityCounter = 0
        spawnCounter += 1
    }

    func apply(action: InputAction) {
        guard state.phase == .playing, var active = state.active else { return }

        switch action {
        case .left, .right:
            let dx = action == .left ? -1 : 1
            let dy = 0
            let translated = active.cells.map { [$0[0] + dx, $0[1] + dy] }
            if isValid(cells: translated) {
                state.active = ActivePiece(type: active.type, rotation: active.rotation, cells: translated)
            }
        case .rotateCW, .rotateCCW:
            let direction: Int = action == .rotateCW ? 1 : 3
            if let rotated = rotatePiece(active, direction: direction) {
                state.active = rotated
                state.audioEvents.append("rotate")
            }
        default:
            break
        }
    }

    func tick(n: Int = 1) {
        for _ in 0..<n {
            state.tick += 1
            state.elapsedTicks += 1

            if state.phase != .playing {
                break
            }

            if state.active == nil {
                spawnPiece()
                continue
            }

            let g = state.mode == .sprint ? Timing.sprintGravity : Timing.gravity(for: state.level)
            gravityCounter += 1
            if gravityCounter >= g {
                gravityCounter = 0
                guard var active = state.active else { continue }
                let translated = active.cells.map { [$0[0], $0[1] + 1] }
                if isValid(cells: translated) {
                    state.active = ActivePiece(type: active.type, rotation: active.rotation, cells: translated)
                } else {
                    lockPiece()
                    if state.phase == .playing {
                        spawnPiece()
                    }
                    continue
                }
            }
        }
    }

    private func lockPiece() {
        guard let active = state.active else { return }
        for cell in active.cells {
            let x = cell[0], y = cell[1]
            if x >= 0 && x < Metrics.cols && y >= 0 && y < Metrics.visibleRows + Metrics.bufferRows {
                state.board[x][y] = active.type
            }
        }
        state.active = nil
        gravityCounter = 0
        state.lockTimer = 0
        state.lockResets = 0

        let cleared = clearLines()
        if state.mode == .sprint && state.lines >= 40 {
            state.phase = .finished
        }
    }

    /// Scan for full rows, remove them, shift down, update score/lines/level/combo.
    /// Returns the number of rows cleared.
    @discardableResult
    private func clearLines() -> Int {
        let totalRows = Metrics.visibleRows + Metrics.bufferRows
        var fullRows: [Int] = []

        // Identify full rows.
        for y in 0..<totalRows {
            var isFull = true
            for x in 0..<Metrics.cols {
                if state.board[x][y] == "." {
                    isFull = false
                    break
                }
            }
            if isFull {
                fullRows.append(y)
            }
        }

        if fullRows.isEmpty {
            state.combo = 0
            return 0
        }

        // Remove full rows by compacting non-full rows downward.
        let fullSet = Set(fullRows)
        var writeRow = totalRows - 1
        for readRow in (0..<totalRows).reversed() {
            if fullSet.contains(readRow) { continue }
            if writeRow != readRow {
                for x in 0..<Metrics.cols {
                    state.board[x][writeRow] = state.board[x][readRow]
                }
            }
            writeRow -= 1
        }
        // Fill remaining top rows with empty.
        for y in 0...writeRow {
            for x in 0..<Metrics.cols {
                state.board[x][y] = "."
            }
        }

        let cleared = fullRows.count
        state.lines += cleared
        let oldLevel = state.level
        state.level = 1 + state.lines / 10
        let comboForScoring = state.combo
        state.combo += 1
        state.score += Scoring.cleared(cleared, level: state.level, combo: comboForScoring)

        // Audio events.
        state.audioEvents.append("lineClear")
        if cleared == 4 {
            state.audioEvents.append("tetris")
        }
        if state.level != oldLevel {
            state.audioEvents.append("levelUp")
        }

        return cleared
    }

    private func isValid(cells: [[Int]]) -> Bool {
        for cell in cells {
            let x = cell[0], y = cell[1]
            if x < 0 || x >= Metrics.cols {
                return false
            }
            if y < 0 || y >= effectiveHeight {
                return false
            }
            if state.board[x][y] != "." {
                return false
            }
        }
        return true
    }

    /// Attempt to rotate an active piece with SRS wall kicks.
    private func rotatePiece(_ active: ActivePiece, direction: Int) -> ActivePiece? {
        guard let pieceType = active.type.first else { return nil }
        let from = active.rotation
        let to = (from + direction + 4) % 4
        guard let targetDefs = Tetromino.states[pieceType]?[to] else { return nil }
        guard let currentDefs = Tetromino.states[pieceType]?[from], !currentDefs.isEmpty else { return nil }
        // Compute the origin (where rotation-state-0 cell[0] is on the board).
        let originX = active.cells[0][0] - currentDefs[0].0
        let originY = active.cells[0][1] - currentDefs[0].1
        let kicks = SRS.kicks(for: pieceType, from: from, to: to)
        for (kdx, kdy) in kicks {
            let candidate = targetDefs.map { (originX + $0.0 + kdx, originY + $0.1 - kdy) }
            if isValid(cells: candidate.map { [$0.0, $0.1] }) {
                return ActivePiece(type: active.type, rotation: to, cells: candidate.map { [$0.0, $0.1] })
            }
        }
        return nil
    }

    /// Effective collision height for piece movement and spawn validation.
    /// Pieces may occupy any row in the board: visible rows + spawn buffer.
    private var effectiveHeight: Int { Metrics.visibleRows + Metrics.bufferRows }
}

enum InputAction: String, Codable {
    case left, right, rotateCW, rotateCCW, softDrop, hardDrop, hold
}
