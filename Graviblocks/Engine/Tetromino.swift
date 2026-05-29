import Foundation

/// Cell offsets for one rotation state of a piece.
typealias RotationState = [(Int, Int)]

/// The 7 tetrominoes with their 4 rotation states (0, R, 2, L).
/// I and O use a 4×4 bounding box; J, L, S, T, Z use a 3×3 bounding box.
/// Coordinates are (x, y) with y increasing downward.
enum Tetromino {
    static let all: [Character] = ["I", "O", "T", "S", "Z", "J", "L"]

    /// All rotation states for each piece, indexed by rotation (0, 1, 2, 3).
    static let states: [Character: [RotationState]] = [
        "I": [
            [(0,1),(1,1),(2,1),(3,1)],  // 0
            [(2,0),(2,1),(2,2),(2,3)],  // R
            [(0,2),(1,2),(2,2),(3,2)],  // 2
            [(1,0),(1,1),(1,2),(1,3)],  // L
        ],
        "O": [
            [(1,0),(2,0),(1,1),(2,1)],  // 0
            [(1,0),(2,0),(1,1),(2,1)],  // R
            [(1,0),(2,0),(1,1),(2,1)],  // 2
            [(1,0),(2,0),(1,1),(2,1)],  // L
        ],
        "T": [
            [(1,0),(0,1),(1,1),(2,1)],  // 0
            [(1,0),(2,0),(2,1),(1,1)],  // R
            [(0,1),(1,1),(2,1),(1,2)],  // 2
            [(1,0),(0,1),(1,1),(1,2)],  // L
        ],
        "S": [
            [(1,0),(2,0),(0,1),(1,1)],  // 0
            [(1,0),(1,1),(2,1),(2,2)],  // R
            [(1,1),(2,1),(0,2),(1,2)],  // 2
            [(0,0),(0,1),(1,1),(1,2)],  // L
        ],
        "Z": [
            [(0,0),(1,0),(1,1),(2,1)],  // 0
            [(2,0),(1,1),(2,1),(1,2)],  // R
            [(0,1),(1,1),(1,2),(2,2)],  // 2
            [(1,0),(0,1),(1,1),(0,2)],  // L
        ],
        "J": [
            [(0,0),(0,1),(1,1),(2,1)],  // 0
            [(1,0),(2,0),(1,1),(1,2)],  // R
            [(0,1),(1,1),(2,1),(2,2)],  // 2
            [(1,0),(1,1),(0,2),(1,2)],  // L
        ],
        "L": [
            [(2,0),(0,1),(1,1),(2,1)],  // 0
            [(1,0),(1,1),(1,2),(2,2)],  // R
            [(0,1),(1,1),(2,1),(0,2)],  // 2
            [(0,0),(1,0),(1,1),(1,2)],  // L
        ],
    ]

    /// Returns the spawn orientation (rotation state 0) cell coordinates for a piece.
    static func spawnOrientation(_ piece: Character) -> RotationState {
        return states[piece]?[0] ?? [(0,0)]
    }

    /// Returns the minimum x offset in a rotation state.
    static func minX(_ cells: RotationState) -> Int {
        cells.map { $0.0 }.min() ?? 0
    }

    /// Returns the maximum x offset in a rotation state.
    static func maxX(_ cells: RotationState) -> Int {
        cells.map { $0.0 }.max() ?? 0
    }

    /// Returns the minimum y offset in a rotation state.
    static func minY(_ cells: RotationState) -> Int {
        cells.map { $0.1 }.min() ?? 0
    }

    /// Returns the maximum y offset in a rotation state.
    static func maxY(_ cells: RotationState) -> Int {
        cells.map { $0.1 }.max() ?? 0
    }
}
