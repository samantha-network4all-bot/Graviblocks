import Foundation

/// Wall-kick data per SRS specification.
/// Each entry is a list of 5 (dx, dy) offsets; dy is up-positive (will be negated for grid).
enum SRS {
    /// Rotation state indices: 0=spawn, 1=R, 2=2, 3=L
    /// Transitions: from→to indexed as (from * 4 + to)

    /// Wall-kick table for J, L, S, T, Z pieces.
    /// Key: (fromRotation * 4 + toRotation) → [(dx, dy)]
    static let jlstzKicks: [Int: [(Int, Int)]] = [
        // 0→R
        1: [(0,0), (-1,0), (-1,1), (0,-2), (-1,-2)],
        // R→0
        4: [(0,0), (1,0), (1,-1), (0,2), (1,2)],
        // R→2
        6: [(0,0), (1,0), (1,-1), (0,2), (1,2)],
        // 2→R
        9: [(0,0), (-1,0), (-1,1), (0,-2), (-1,-2)],
        // 2→L
        11: [(0,0), (1,0), (1,1), (0,-2), (1,-2)],
        // L→2
        13: [(0,0), (-1,0), (-1,-1), (0,2), (-1,2)],
        // L→0
        12: [(0,0), (-1,0), (-1,-1), (0,2), (-1,2)],
        // 0→L
        3: [(0,0), (1,0), (1,1), (0,-2), (1,-2)],
    ]

    /// Wall-kick table for I piece.
    static let iKicks: [Int: [(Int, Int)]] = [
        // 0→R
        1: [(0,0), (-2,0), (1,0), (-2,-1), (1,2)],
        // R→0
        4: [(0,0), (2,0), (-1,0), (2,1), (-1,-2)],
        // R→2
        6: [(0,0), (-1,0), (2,0), (-1,2), (2,-1)],
        // 2→R
        9: [(0,0), (1,0), (-2,0), (1,-2), (-2,1)],
        // 2→L
        11: [(0,0), (2,0), (-1,0), (2,1), (-1,-2)],
        // L→2
        13: [(0,0), (-2,0), (1,0), (-2,-1), (1,2)],
        // L→0
        12: [(0,0), (1,0), (-2,0), (1,-2), (-2,1)],
        // 0→L
        3: [(0,0), (-1,0), (2,0), (-1,2), (2,-1)],
    ]

    /// O never kicks (always returns a single zero offset).
    static let oKicks: [Int: [(Int, Int)]] = [
        1: [(0,0)], 4: [(0,0)], 6: [(0,0)], 9: [(0,0)],
        11: [(0,0)], 13: [(0,0)], 12: [(0,0)], 3: [(0,0)],
    ]

    /// Get kick offsets for a piece transitioning from one rotation to another.
    /// - Parameters:
    ///   - piece: The piece character.
    ///   - from: Current rotation state (0-3).
    ///   - to: Target rotation state (0-3).
    /// - Returns: Array of (dx, dy) kick offsets to try, in order.
    static func kicks(for piece: Character, from: Int, to: Int) -> [(Int, Int)] {
        let key = from * 4 + to
        switch piece {
        case "I":
            return iKicks[key] ?? [(0,0)]
        case "O":
            return oKicks[key] ?? [(0,0)]
        default:
            return jlstzKicks[key] ?? [(0,0)]
        }
    }
}
