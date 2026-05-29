import Foundation

final class Engine {
    var state: GameState
    private var bag: Bag!

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
        for cell in cells {
            if cell.x >= 0 && cell.x < Metrics.cols && cell.y >= 0 && cell.y < Metrics.visibleRows + Metrics.bufferRows {
                if state.board[cell.x][cell.y] != "." {
                    state.phase = .over
                    state.topOut = true
                    return
                }
            }
        }

        state.active = ActivePiece(type: String(pieceChar), rotation: 0, cells: cells.map { [$0.x, $0.y] })
        state.canHold = true
    }

    func apply(action: InputAction) {
        // Stub for now - movement/rotation comes in later slices
    }

    func tick(n: Int = 1) {
        state.tick += n
        state.elapsedTicks += n
        // Gravity stub - comes in S3
    }
}

enum InputAction: String, Codable {
    case left, right, rotateCW, rotateCCW, softDrop, hardDrop, hold
}
