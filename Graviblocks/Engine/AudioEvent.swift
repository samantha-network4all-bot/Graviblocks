import Foundation

enum AudioEvent: String, Codable {
    case move, rotate, softDrop, hardDrop, lock, hold
    case lineClear, levelUp, topOut, musicStart, musicStop
}
