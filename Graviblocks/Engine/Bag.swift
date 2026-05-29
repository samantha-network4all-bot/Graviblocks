import Foundation

struct Bag {
    private var pieces: [Character] = []
    private var rng: PRNG

    init(rng: inout PRNG) {
        self.rng = rng
        refill()
    }

    /// Pull the next piece type from the bag; refill when empty.
    @discardableResult
    mutating func next() -> Character {
        if pieces.isEmpty {
            refill()
        }
        return pieces.removeFirst()
    }

    /// Refill and shuffle using the PRNG.
    mutating func refill() {
        var newPieces = Tetromino.all
        shuffle(&newPieces)
        pieces = newPieces
    }

    /// Fisher–Yates shuffle using the stored PRNG.
    private mutating func shuffle(_ array: inout [Character]) {
        for i in stride(from: array.count - 1, through: 1, by: -1) {
            let j = rng.nextInt(in: 0..<(i + 1))
            array.swapAt(i, j)
        }
    }
}
