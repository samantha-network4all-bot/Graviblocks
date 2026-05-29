import AppKit

final class WindowController: NSViewController, TestAPIControllerRoutes {
    static var routePrefix: String { "window" }

    private(set) var windowController: NSWindowController?

    func showWindow() {
        DispatchQueue.main.sync {
            let win = GraviblocksWindow()
            let wc = NSWindowController(window: win)
            self.windowController = wc
            wc.contentViewController = self
            wc.showWindow(nil)
            win.makeKeyAndOrderFront(nil)
        }
    }

    override func loadView() {
        let root = RootView(frame: NSRect(origin: .zero, size: Metrics.defaultWindowSize))
        self.view = root
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        TestAPIRouter.shared.register(controller: self)
    }

    func registerRoutes(on router: TestAPIRouter) {
        router.get(prefix: Self.routePrefix, path: "/list") { [weak self] _ in
            guard let self else { return .notFound() }
            let windowList: [[String: Any]] = [
                ["id": "w1", "title": "Graviblocks", "isKey": true]
            ]
            guard let data = try? JSONSerialization.data(withJSONObject: windowList) else {
                return .internalServerError("encoding failed")
            }
            return .ok(json: data)
        }
    }
}
