//
//  HexavilleFrameworkTests.swift
//  HexavilleFrameworkPackageDescription
//
//  Created by Oliver ONeill on 15/9/18.
//

import Foundation
import XCTest
@testable import HexavilleFramework

class HexavilleFrameworkTests: XCTestCase {
    func testDispatchPercentEncodedRequests() {
        // Test path with invalid URL characters { and }
        let path = "/?test={encoded}"
        let app = HexavilleFramework()
        var router = Router()
        // Handles / path
        router.use(.get, "/") { request, context in
            XCTAssertEqual("/", request.path)
            // The query items are intact
            XCTAssertEqual(
                [URLQueryItem(name: "test", value: "{encoded}")],
                request.queryItems
            )
            return Response(body: "")
        }
        app.use(router)
        // Dispatch with path
        _ = app.dispatch(
            method: "GET",
            path: path,
            header: "",
            body: nil
        )
    }

    static var allTests = [
        ("testDispatchPercentEncodedRequests", testDispatchPercentEncodedRequests),
    ]
}
