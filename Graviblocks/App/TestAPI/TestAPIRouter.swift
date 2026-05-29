import Foundation

protocol TestAPIControllerRoutes: AnyObject {
    static var routePrefix: String { get }
    func registerRoutes(on router: TestAPIRouter)
}

final class TestAPIRouter {
    static let shared = TestAPIRouter()
    private var handlers: [String: (TestAPIRequest) -> TestAPIResponse] = [:]
    private init() {}

    func register<C: TestAPIControllerRoutes>(controller: C) {
        controller.registerRoutes(on: self)
    }

    func get(prefix: String, path: String, _ h: @escaping (TestAPIRequest) -> TestAPIResponse) {
        handlers["GET /\(prefix)\(path)"] = h
    }

    func post(prefix: String, path: String, _ h: @escaping (TestAPIRequest) -> TestAPIResponse) {
        handlers["POST /\(prefix)\(path)"] = h
    }

    // For top-level routes (no prefix)
    func get(path: String, _ h: @escaping (TestAPIRequest) -> TestAPIResponse) {
        handlers["GET \(path)"] = h
    }

    func post(path: String, _ h: @escaping (TestAPIRequest) -> TestAPIResponse) {
        handlers["POST \(path)"] = h
    }

    func dispatch(_ req: TestAPIRequest) -> TestAPIResponse {
        if let h = handlers["\(req.method) \(req.path)"] {
            return h(req)
        }
        if let h = handlers["\(req.method) \(req.path)/"] {
            return h(req)
        }
        return .notFound(req)
    }
}
