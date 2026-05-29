import AppKit

final class BoardView: NSView {
    private var gameState = GameState()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }

    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        ctx.setFillColor(Palette.panelBackground.cgColor)
        ctx.fill(bounds)

        let cellW = CGFloat(Metrics.cell)
        let cellH = CGFloat(Metrics.cell)

        for row in 0..<Metrics.visibleRows {
            for col in 0..<Metrics.cols {
                let x = CGFloat(col) * cellW
                let y = CGFloat(Metrics.visibleRows - 1 - row) * cellH
                let rect = CGRect(x: x, y: y, width: cellW, height: cellH)

                let cell = gameState.board[col][row + Metrics.bufferRows]
                if cell != "." {
                    ctx.setFillColor(Palette.color(for: Character(cell)).cgColor)
                } else {
                    ctx.setFillColor(Palette.emptyCell.cgColor)
                }
                ctx.fill(rect)

                ctx.setStrokeColor(Palette.gridLine.cgColor)
                ctx.setLineWidth(0.5)
                ctx.stroke(rect)
            }
        }

        ctx.setStrokeColor(Palette.boardBorder.cgColor)
        ctx.setLineWidth(2)
        ctx.stroke(bounds)
    }
}
