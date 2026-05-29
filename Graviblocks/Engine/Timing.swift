import Foundation

enum Timing {
    static func gravity(for level: Int) -> Int {
        switch level {
        case 1: return 60
        case 2: return 48
        case 3: return 37
        case 4: return 28
        case 5: return 21
        case 6: return 16
        case 7: return 11
        case 8: return 8
        case 9: return 6
        case 10: return 4
        case 11: return 3
        case 12: return 2
        default: return 1
        }
    }
}
