import Foundation

struct PRNG {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed == 0 ? 1 : seed
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }

    mutating func nextInt(in range: Range<Int>) -> Int {
        let r = range.upperBound - range.lowerBound
        guard r > 0 else { return range.lowerBound }
        let maxMod = UInt64.max - (UInt64.max % UInt64(r)) - 1
        var x: UInt64
        repeat {
            x = next()
        } while x > maxMod
        return range.lowerBound + Int(x % UInt64(r))
    }
}
