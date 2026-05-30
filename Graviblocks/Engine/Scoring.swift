import Foundation

enum Scoring {
    static func cleared(_ count: Int, level: Int, combo: Int) -> Int {
        let base: Int
        switch count {
        case 1: base = 100
        case 2: base = 300
        case 3: base = 500
        case 4: base = 800
        default: base = 0
        }
        return (base * level) + (50 * combo * level)
    }
}
