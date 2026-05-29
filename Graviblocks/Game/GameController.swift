import AppKit

final class GameController: NSViewController, TestAPIControllerRoutes {
    static var routePrefix: String { "game" }

    private let engine = Engine()

    override init(nibName: String?, bundle: Bundle?) {
        super.init(nibName: nibName, bundle: bundle)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func loadView() {
        let board = BoardView()
        board.translatesAutoresizingMaskIntoConstraints = false
        let container = NSView()
        container.addSubview(board)
        NSLayoutConstraint.activate([
            board.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            board.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            board.widthAnchor.constraint(equalToConstant: CGFloat(Metrics.cell) * CGFloat(Metrics.cols)),
            board.heightAnchor.constraint(equalToConstant: CGFloat(Metrics.cell) * CGFloat(Metrics.visibleRows)),
        ])
        self.view = container
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        TestAPIRouter.shared.register(controller: self)
    }

    func registerRoutes(on router: TestAPIRouter) {
        router.post(prefix: Self.routePrefix, path: "/new") { [weak self] req in
            guard let self else { return .notFound() }
            struct Body: Codable {
                let mode: String?
                let seed: UInt64?
            }
            let body: Body
            if !req.body.isEmpty {
                guard let b = try? JSONDecoder().decode(Body.self, from: req.body) else {
                    return .badRequest("body must be {\"mode\":String?, \"seed\":Int?}")
                }
                body = b
            } else {
                body = Body(mode: nil, seed: nil)
            }
            let modeStr = body.mode ?? "marathon"
            let mode: GameMode = modeStr == "sprint" ? .sprint : .marathon
            let seed = body.seed ?? 1
            DispatchQueue.main.sync {
                self.engine.newGame(mode: mode, seed: seed)
            }
            let resp: [String: Any] = ["ok": true, "mode": String(describing: mode), "seed": seed]
            let data = try! JSONSerialization.data(withJSONObject: resp)
            return .ok(json: data)
        }

        router.post(prefix: Self.routePrefix, path: "/input") { [weak self] req in
            guard let self else { return .notFound() }
            struct Body: Codable { let action: String }
            guard let body = try? JSONDecoder().decode(Body.self, from: req.body) else {
                return .badRequest("body must be {\"action\": String}")
            }
            guard let action = InputAction(rawValue: body.action) else {
                return .badRequest("unknown action: \(body.action)")
            }
            DispatchQueue.main.sync {
                self.engine.apply(action: action)
            }
            return .ok(jsonString: "{\"ok\":true}")
        }

        router.post(prefix: Self.routePrefix, path: "/tick") { [weak self] req in
            guard let self else { return .notFound() }
            struct Body: Codable { let n: Int }
            let body = try? JSONDecoder().decode(Body.self, from: req.body)
            let n = body?.n ?? 1
            DispatchQueue.main.sync {
                self.engine.tick(n: n)
            }
            let tick = self.engine.state.tick
            let resp: [String: Any] = ["ok": true, "tick": tick]
            let data = try! JSONSerialization.data(withJSONObject: resp)
            return .ok(json: data)
        }

        router.post(prefix: Self.routePrefix, path: "/autorun") { [weak self] req in
            guard let self else { return .notFound() }
            _ = try? JSONDecoder().decode(CodableBool.self, from: req.body)
            return .ok(jsonString: "{\"ok\":true}")
        }

        router.post(prefix: Self.routePrefix, path: "/pause") { [weak self] req in
            guard let self else { return .notFound() }
            _ = try? JSONDecoder().decode(CodableBool.self, from: req.body)
            DispatchQueue.main.sync {
                let state = self.engine.state
                if state.phase == .playing {
                    self.engine.state.phase = .paused
                } else if state.phase == .paused {
                    self.engine.state.phase = .playing
                }
            }
            return .ok(jsonString: "{\"ok\":true}")
        }

        router.get(prefix: Self.routePrefix, path: "/state") { [weak self] _ in
            guard let self else { return .notFound() }
            let state = self.engine.state
            let resp = StateResponse(
                phase: String(describing: state.phase),
                mode: String(describing: state.mode),
                seed: state.seed, tick: state.tick,
                level: state.level, lines: state.lines, score: state.score,
                combo: state.combo, backToBack: state.backToBack,
                elapsedTicks: state.elapsedTicks,
                active: state.active, ghostCells: state.ghostCells,
                hold: state.hold, canHold: state.canHold, next: state.next,
                lockTimer: state.lockTimer, lockResets: state.lockResets,
                topOut: state.topOut
            )
            guard let data = try? JSONEncoder().encode(resp) else {
                return .internalServerError("encoding failed")
            }
            return .ok(json: data)
        }

        router.get(prefix: Self.routePrefix, path: "/board") { [weak self] _ in
            guard let self else { return .notFound() }
            let state = self.engine.state

            var grid: [String] = []
            for row in 0..<Metrics.visibleRows {
                var line = ""
                for col in 0..<Metrics.cols {
                    let internalRow = row + Metrics.bufferRows
                    let cell = state.board[col][internalRow]
                    line += cell
                }
                grid.append(line)
            }

            let resp: [String: Any] = [
                "width": Metrics.cols,
                "height": Metrics.visibleRows,
                "grid": grid
            ]
            guard let data = try? JSONSerialization.data(withJSONObject: resp) else {
                return .internalServerError("encoding failed")
            }
            return .ok(json: data)
        }
    }
}

private struct CodableBool: Codable {
    let on: Bool
}

private struct StateResponse: Codable {
    let phase: String, mode: String, seed: UInt64, tick: Int
    let level: Int, lines: Int, score: Int, combo: Int, backToBack: Bool
    let elapsedTicks: Int
    let active: ActivePiece?, ghostCells: [[Int]]
    let hold: String?, canHold: Bool, next: [String]
    let lockTimer: Int, lockResets: Int, topOut: Bool
}
