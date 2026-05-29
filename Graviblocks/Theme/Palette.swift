import AppKit

enum Palette {
    static let emptyCell = NSColor(red: 0x10/255.0, green: 0x18/255.0, blue: 0x30/255.0, alpha: 1.0)
    static let boardBorder = NSColor(red: 0x30/255.0, green: 0x50/255.0, blue: 0xA0/255.0, alpha: 1.0)
    static let gridLine = NSColor(red: 0x1A/255.0, green: 0x20/255.0, blue: 0x40/255.0, alpha: 1.0)
    static let panelBackground = NSColor(red: 0x08/255.0, green: 0x0C/255.0, blue: 0x18/255.0, alpha: 1.0)
    static let panelBevelLight = NSColor(red: 0x30/255.0, green: 0x50/255.0, blue: 0xA0/255.0, alpha: 1.0)
    static let panelBevelDark = NSColor(red: 0x04/255.0, green: 0x06/255.0, blue: 0x0C/255.0, alpha: 1.0)
    static let uiText = NSColor(red: 0xE0/255.0, green: 0xE0/255.0, blue: 0xF0/255.0, alpha: 1.0)

    static let pieceColors: [Character: NSColor] = [
        "I": NSColor(red: 0x00/255.0, green: 0xE0/255.0, blue: 0xE0/255.0, alpha: 1.0),
        "O": NSColor(red: 0xE0/255.0, green: 0xE0/255.0, blue: 0x00/255.0, alpha: 1.0),
        "T": NSColor(red: 0xA0/255.0, green: 0x00/255.0, blue: 0xE0/255.0, alpha: 1.0),
        "S": NSColor(red: 0x00/255.0, green: 0xE0/255.0, blue: 0x00/255.0, alpha: 1.0),
        "Z": NSColor(red: 0xE0/255.0, green: 0x00/255.0, blue: 0x00/255.0, alpha: 1.0),
        "J": NSColor(red: 0x00/255.0, green: 0x40/255.0, blue: 0xE0/255.0, alpha: 1.0),
        "L": NSColor(red: 0xE0/255.0, green: 0x80/255.0, blue: 0x00/255.0, alpha: 1.0),
    ]

    static func color(for piece: Character) -> NSColor {
        return pieceColors[piece] ?? Palette.uiText
    }
}
