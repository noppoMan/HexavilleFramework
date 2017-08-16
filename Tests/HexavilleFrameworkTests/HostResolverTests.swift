//
//  HostResolverTests.swift
//  HexavilleFrameworkPackageDescription
//
//  Created by Yuki Takei on 2017/08/16.
//

import Foundation
import XCTest
@testable import HexavilleFramework

class HostResolverTests: XCTestCase {
    
    func testResolve() {
        let resolver = HostResolver()
        var environ = ProcessInfo.processInfo.environment
        environ["X_APIGATEWAY_HOST"] = "foobar.execute-api.ap-northeast-1.amazonaws.com"
        
        guard let host = resolver.resolve(forTestEnvironment: environ) else {
            XCTFail("Never reached")
            return
        }
        XCTAssertEqual(environ["X_APIGATEWAY_HOST"], host)
    }
    
    func testResolveBaseURLString() {
        let resolver = HostResolver()
        var environ = ProcessInfo.processInfo.environment
        environ["X_APIGATEWAY_STAGE"] = "staging"
        environ["X_APIGATEWAY_API_ID"] = "foobar"
        environ["AWS_REGION"] = "ap-northeast-1"
        
        do {
            environ["X_APIGATEWAY_HOST"] = "foobar.execute-api.ap-northeast-1.amazonaws.com"
            guard let baseURL = resolver.resolveBaseURLString(forTestEnvironment: environ) else {
                XCTFail("Never reached")
                return
            }
            
            XCTAssertEqual(baseURL, "https://foobar.execute-api.ap-northeast-1.amazonaws.com/staging")
        }
        
        do {
            environ["X_APIGATEWAY_HOST"] = "example.com"
            guard let baseURL = resolver.resolveBaseURLString(forTestEnvironment: environ) else {
                XCTFail("Never reached")
                return
            }
            XCTAssertEqual(baseURL, "https://example.com")
        }
    }
    
    static var allTests = [
        ("testResolve", testResolve),
        ("testResolveBaseURLString", testResolveBaseURLString),
    ]
}

