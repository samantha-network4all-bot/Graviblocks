import AppKit

final class GraviblocksWindow: NSWindow {
    convenience init() {
        self.init(
            contentRect: NSRect(origin: .zero, size: Metrics.defaultWindowSize),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        self.title = "Graviblocks"
        self.isReleasedWhenClosed = false
    }
}
