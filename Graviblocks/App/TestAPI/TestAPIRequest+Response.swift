import Foundation

struct TestAPIRequest {
    let method: String
    let path: String
    let body: Data

    var bodyString: String {
        String(data: body, encoding: .utf8) ?? ""
    }
}

struct TestAPIResponse {
    let statusCode: Int
    let statusText: String
    let contentType: String
    let responseBody: Data

    static func ok(json data: Data) -> TestAPIResponse {
        TestAPIResponse(statusCode: 200, statusText: "OK", contentType: "application/json", responseBody: data)
    }

    static func ok(jsonString: String) -> TestAPIResponse {
        ok(json: Data(jsonString.utf8))
    }

    static func ok(data: Data, contentType: String) -> TestAPIResponse {
        TestAPIResponse(statusCode: 200, statusText: "OK", contentType: contentType, responseBody: data)
    }

    static func badRequest(_ msg: String) -> TestAPIResponse {
        let json = "{\"error\":\"\(msg)\"}"
        return TestAPIResponse(statusCode: 400, statusText: "Bad Request", contentType: "application/json", responseBody: Data(json.utf8))
    }

    static func notFound(_ req: TestAPIRequest? = nil) -> TestAPIResponse {
        return TestAPIResponse(statusCode: 404, statusText: "Not Found", contentType: "application/json", responseBody: Data("{\"error\":\"not found\"}".utf8))
    }

    static func internalServerError(_ msg: String) -> TestAPIResponse {
        return TestAPIResponse(statusCode: 500, statusText: "Internal Server Error", contentType: "application/json", responseBody: Data("{\"error\":\"\(msg)\"}".utf8))
    }
}
