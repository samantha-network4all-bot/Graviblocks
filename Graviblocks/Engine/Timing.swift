import Foundation

enum Timing {
    static let sprintGravity = 2

    static func gravity(for level: Int) -> Int {
        switch level {
        case 1:  return 2
        case 2:  return 2
        case 3:  return 2
        case 4:  return 2
        case 5:  return 2
        case 6:  return 2
        case 7:  return 2
        case 8:  return 2
        case 9:  return 2
        case 10: return 2
        case 11: return 2
        case 12: return 1
        default: return 1
        }
    }
}
