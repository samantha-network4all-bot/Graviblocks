import Foundation

final class Engine {
    var state: GameState

    init() {
        self.state = GameState()
    }

    func newGame(mode: GameMode, seed: UInt64) {
        state = GameState()
        state.mode = mode
        state.seed = seed
        state.phase = .playing
    }

    func apply(action: InputAction) {
        // stub
    }

    func tick(n: Int = 1) {
        state.tick += n
        state.elapsedTicks += n
    }
}

enum InputAction: String, Codable {
    case left, right, rotateCW, rotateCCW, softDrop, hardDrop, hold
}
