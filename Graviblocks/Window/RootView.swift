import AppKit

final class RootView: NSView {
    let holdPanel = SidePanelView()
    let boardView = BoardView()
    let nextPanel = SidePanelView()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        wantsLayer = true
        layer?.backgroundColor = Palette.panelBackground.cgColor

        let leftContainer = NSView()
        let rightContainer = NSView()

        addSubview(leftContainer)
        addSubview(boardView)
        addSubview(rightContainer)

        leftContainer.addSubview(holdPanel)
        rightContainer.addSubview(nextPanel)

        leftContainer.translatesAutoresizingMaskIntoConstraints = false
        rightContainer.translatesAutoresizingMaskIntoConstraints = false
        boardView.translatesAutoresizingMaskIntoConstraints = false
        holdPanel.translatesAutoresizingMaskIntoConstraints = false
        nextPanel.translatesAutoresizingMaskIntoConstraints = false

        let boardW = CGFloat(Metrics.cell) * CGFloat(Metrics.cols)
        let boardH = CGFloat(Metrics.cell) * CGFloat(Metrics.visibleRows)

        NSLayoutConstraint.activate([
            leftContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            leftContainer.topAnchor.constraint(equalTo: topAnchor),
            leftContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
            leftContainer.widthAnchor.constraint(equalToConstant: Metrics.panelWidth),

            rightContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            rightContainer.topAnchor.constraint(equalTo: topAnchor),
            rightContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
            rightContainer.widthAnchor.constraint(equalToConstant: Metrics.panelWidth),

            boardView.centerXAnchor.constraint(equalTo: centerXAnchor),
            boardView.centerYAnchor.constraint(equalTo: centerYAnchor),
            boardView.widthAnchor.constraint(equalToConstant: boardW),
            boardView.heightAnchor.constraint(equalToConstant: boardH),

            holdPanel.centerXAnchor.constraint(equalTo: leftContainer.centerXAnchor),
            holdPanel.centerYAnchor.constraint(equalTo: leftContainer.centerYAnchor),
            holdPanel.widthAnchor.constraint(equalToConstant: Metrics.panelWidth),
            holdPanel.heightAnchor.constraint(equalToConstant: 200),

            nextPanel.centerXAnchor.constraint(equalTo: rightContainer.centerXAnchor),
            nextPanel.centerYAnchor.constraint(equalTo: rightContainer.centerYAnchor),
            nextPanel.widthAnchor.constraint(equalToConstant: Metrics.panelWidth),
            nextPanel.heightAnchor.constraint(equalToConstant: 400),
        ])
    }
}
