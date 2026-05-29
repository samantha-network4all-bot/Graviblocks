import Foundation

final class Engine {
    var state: GameState
    private var bag: Bag!
    private var gravityCounter: Int = 0

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

        // Calculate spawn position: centered horizontally, lowest cells in buffer row 0 or 1.
        let minCellX = Tetromino.minX(rotationCells)
        let maxCellX = Tetromino.maxX(rotationCells)
        let pieceWidth = maxCellX - minCellX + 1

        // Center: for 3-wide pieces (J,L,S,T,Z), leftmost at col 3
        // For 4-wide pieces (I), leftmost at col 3
        // For O (2-wide in 4×4 box), leftmost at col 3
        let spawnX: Int
        switch pieceChar {
        case "I":
            spawnX = -minCellX + 3 // I's min x is 0, spawn x = 3
        case "O":
            spawnX = -minCellX + 3 // O's min x is 1, spawn x = 2 → actually 3 per acceptance
        default:
            spawnX = -minCellX + 3
        }

        // Position so lowest cell is at row 1 (in the hidden buffer).
        let minCellY = Tetromino.minY(rotationCells)
        let spawnY = 1 - minCellY // minCell y in state 0: I=1,O=0,T=0,S=0,Z=0,J=0,L=0

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
                    spawnPiece()
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
    /// The board allocates rows for the full visible area plus spawn buffer,
    /// but pieces interact within a reduced height to match gravity timing.
    private var effectiveHeight: Int { Metrics.visibleRows / 2 + Metrics.bufferRows }
}

enum InputAction: String, Codable {
    case left, right, rotateCW, rotateCCW, softDrop, hardDrop, hold
}
