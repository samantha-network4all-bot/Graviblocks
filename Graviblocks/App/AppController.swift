import AppKit

final class AppController {
    private let windowController = WindowController()
    private let gameController = GameController()
    private let menuBuilder = MenuBuilder()

    func startup() {
        TestAPIServer.shared.start()
        registerRoutes()
        menuBuilder.build()
        windowController.showWindow()
        DispatchQueue.main.async {
            if let win = self.windowController.windowController?.window {
                let root = RootView(frame: NSRect(origin: .zero, size: Metrics.defaultWindowSize))
                win.contentView = root
            }
        }
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    private func registerRoutes() {
        let router = TestAPIRouter.shared

        router.get(path: "/healthz") { _ in
            .ok(jsonString: "{\"ok\":true}")
        }

        router.post(path: "/shutdown") { _ in
            DispatchQueue.main.async {
                NSApplication.shared.terminate(nil)
            }
            return .ok(jsonString: "{\"ok\":true}")
        }

        router.get(path: "/screenshot") { _ in
            guard let win = NSApplication.shared.keyWindow ?? NSApplication.shared.windows.first else {
                return .internalServerError("no key window")
            }
            let view = win.contentView!
            let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds)!
            view.cacheDisplay(in: view.bounds, to: rep)
            let png = rep.representation(using: .png, properties: [:])!
            return .ok(data: png, contentType: "image/png")
        }
    }
}
