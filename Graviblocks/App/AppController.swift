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
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    private func registerRoutes() {
        let router = TestAPIRouter.shared

        router.get(path: "/healthz") { _ in
            .ok(jsonString: "{\"ok\":true}")
        }

        router.post(path: "/shutdown") { _ in
            DispatchQueue.main.sync {
                NSApplication.shared.terminate(nil)
            }
            return .ok(jsonString: "{\"ok\":true}")
        }

        router.get(path: "/screenshot") { _ in
            var pngData: Data?
            var errMsg: String?
            DispatchQueue.main.sync {
                guard let win = NSApplication.shared.keyWindow ?? NSApplication.shared.windows.first else {
                    errMsg = "no key window"
                    return
                }
                guard let view = win.contentView else {
                    errMsg = "no content view"
                    return
                }
                guard let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else {
                    errMsg = "bitmapImageRep failed"
                    return
                }
                view.cacheDisplay(in: view.bounds, to: rep)
                if let data = rep.representation(using: .png, properties: [:]) {
                    pngData = data
                } else {
                    errMsg = "png encoding failed"
                }
            }
            if let err = errMsg {
                return .internalServerError(err)
            }
            guard let data = pngData else {
                return .internalServerError("no data")
            }
            return .ok(data: data, contentType: "image/png")
        }
    }
}
