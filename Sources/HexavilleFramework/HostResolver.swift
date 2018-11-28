//
//  HostResolver.swift
//  HexavilleFrameworkPackageDescription
//
//  Created by Yuki Takei on 2017/08/16.
//

import Foundation

public struct HostResolver {
    public static let shared = HostResolver()
    
    public init() {}
    
    public func resolve(forTestEnvironment testEnv: [String: String]? = nil) -> String? {
        let environ = testEnv ?? ProcessInfo.processInfo.environment
        guard let host = environ["X_APIGATEWAY_HOST"] else {
                return nil
        }
        return host
    }
    
    public func resolveBaseURLString(forTestEnvironment testEnv: [String: String]? = nil) -> String? {
        let environ = testEnv ?? ProcessInfo.processInfo.environment
        
        guard let host = environ["X_APIGATEWAY_HOST"],
            let stage = environ["X_APIGATEWAY_STAGE"],
            let apiId = environ["X_APIGATEWAY_API_ID"],
            let region = environ["AWS_REGION"] else {
                return nil
        }
        if host.contains("\(apiId).execute-api.\(region).amazonaws.com") {
            return "https://\(host)/\(stage)"
        }
        return "https://\(host)"
    }
}
