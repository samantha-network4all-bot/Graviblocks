import AppKit

final class SidePanelView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = Palette.panelBackground.cgColor
    }

    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        ctx.setFillColor(Palette.panelBackground.cgColor)
        ctx.fill(bounds)

        ctx.setStrokeColor(Palette.panelBevelLight.cgColor)
        ctx.setLineWidth(1)
        let border = bounds.insetBy(dx: 0.5, dy: 0.5)
        ctx.stroke(border)
    }
}
