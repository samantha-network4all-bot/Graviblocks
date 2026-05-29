import Foundation
import Network

final class TestAPIServer {
    static let shared = TestAPIServer()
    private var listener: NWListener?
    private var connections: [NWConnection] = []
    private init() {}

    func start() {
        guard ProcessInfo.processInfo.environment["GRAVIBLOCKS_TEST_API"] == "1" else { return }

        do {
            listener = try NWListener(using: .tcp, on: .any)
        } catch {
            return
        }

        listener?.newConnectionHandler = { [weak self] conn in
            self?.handleConnection(conn)
        }

        listener?.start(queue: DispatchQueue(label: "test-api"))

        // Write port to support file
        if let port = listener?.port {
            writePortFile(port: port)
        }
    }

    private func writePortFile(port: NWEndpoint.Port) {
        let portStr = "\(port.rawValue)\n"
        let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Graviblocks")
        try? FileManager.default.createDirectory(at: supportDir, withIntermediateDirectories: true)
        let portFile = supportDir.appendingPathComponent("test-api.port")
        try? portStr.write(to: portFile, atomically: true, encoding: .utf8)
    }

    private func handleConnection(_ conn: NWConnection) {
        connections.append(conn)
        conn.start(queue: DispatchQueue(label: "test-api-conn"))
        receiveHTTP(conn)
    }

    private func receiveHTTP(_ conn: NWConnection) {
        conn.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self, let data, !data.isEmpty, error == nil else {
                self?.closeConnection(conn)
                return
            }
            let response = self.parseAndDispatch(data: data)
            self.sendResponse(response, on: conn)

            if !isComplete {
                self.receiveHTTP(conn)
            } else {
                self.closeConnection(conn)
            }
        }
    }

    private func parseAndDispatch(data: Data) -> TestAPIResponse {
        guard let raw = String(data: data, encoding: .utf8) else {
            return .badRequest("invalid encoding")
        }

        let lines = raw.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else {
            return .badRequest("empty request")
        }

        let parts = requestLine.components(separatedBy: " ")
        guard parts.count >= 2 else {
            return .badRequest("malformed request line")
        }

        let method = parts[0]
        let path = parts[1]

        // Find body after blank line
        var body = Data()
        if let blankIdx = lines.firstIndex(of: "") {
            let bodyLines = lines[(blankIdx + 1)...]
            body = bodyLines.joined(separator: "\r\n").data(using: .utf8) ?? Data()
        }

        let req = TestAPIRequest(method: method, path: path, body: body)
        return TestAPIRouter.shared.dispatch(req)
    }

    private func sendResponse(_ response: TestAPIResponse, on conn: NWConnection) {
        let header = "HTTP/1.1 \(response.statusCode) \(response.statusText)\r\nContent-Type: \(response.contentType)\r\nContent-Length: \(response.responseBody.count)\r\nConnection: close\r\n\r\n"
        var data = header.data(using: .utf8)!
        data.append(response.responseBody)

        conn.send(content: data, completion: .contentProcessed { [weak self] _ in
            self?.closeConnection(conn)
        })
    }

    private func closeConnection(_ conn: NWConnection) {
        conn.cancel()
        connections.removeAll { $0 === conn }
    }

    func stop() {
        listener?.cancel()
        connections.forEach { $0.cancel() }
        connections.removeAll()
    }
}
