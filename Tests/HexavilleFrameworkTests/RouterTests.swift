//
//  RouterTests.swift
//  HexavilleFrameworkTests
//
//  Created by Yuki Takei on 2017/07/29.
//

import Foundation
import XCTest
@testable import HexavilleFramework

class RouterTests: XCTestCase {
    
    func getRouter() -> Router {
        var router = Router()
        
        func testHandler(_ request: Request, _ context: ApplicationContext) throws -> Response {
            return Response()
        }
        
        router.use(.GET, "/test", testHandler)
        router.use(.GET, "/test/:id", testHandler)
        router.use(.GET, "/test/:user/:id/foo", testHandler)
        
        return router
    }
    
    func testMatch() {
        let router = getRouter()
        
        do {
            let matched = router.matched(for: Request(url: URL(string: "http://foo.com/test")!))
            XCTAssertNotNil(matched?.0)
        }
        
        do {
            let matched = router.matched(for: Request(url: URL(string: "http://foo.com/test/1")!))
            XCTAssertNotNil(matched?.0)
            XCTAssertEqual(matched?.1.params?["id"] as? String, "1")
        }
        
        do {
            let matched = router.matched(for: Request(url: URL(string: "http://foo.com/test/jack/1/foo")!))
            XCTAssertNotNil(matched?.0)
            XCTAssertEqual(matched?.1.params?["user"] as? String, "jack")
            XCTAssertEqual(matched?.1.params?["id"] as? String, "1")
        }
        
        do {
            let matched = router.matched(for: Request(url: URL(string: "http://foo.com/foobar")!))
            XCTAssertNil(matched?.0)
        }
    }
    
    func testApiGatewayStylePath() {
        let router = getRouter()
        let paths = router.routes.map({ $0.apiGatewayStylePath() })
        XCTAssertEqual(paths, ["/test", "/test/{id}", "/test/{user}/{id}/foo"])
    }
    
    static var allTests = [
        ("testMatch", testMatch),
        ("testApiGatewayStylePath", testApiGatewayStylePath)
    ]
}
