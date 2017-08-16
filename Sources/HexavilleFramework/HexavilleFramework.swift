//
//  CallbackURL.swift
//  HexavilleAuth
//
//  Created by Yuki Takei on 2017/05/31.
//
//

import Foundation
import HexavilleFramework

public struct HostResolver {
    public static var shared = HostResolver()
    
    public func resolve() -> String {
        guard let host = ProcessInfo.processInfo.environment["X_APIGATEWAY_HOST"] else {
            fatalError("X_APIGATEWAY_HOST must not empty")
        }
        
        guard let stage = ProcessInfo.processInfo.environment["X_APIGATEWAY_STAGE"],
            let apiId = ProcessInfo.processInfo.environment["X_APIGATEWAY_API_ID"],
            let region = ProcessInfo.processInfo.environment["AWS_REGION"] else {
                return "https://\(host)"
        }
        
        if host.contains(substring: "\(apiId).execute-api.\(region).amazonaws.com") {
            return "https://\(host)/\(stage)"
        }
        
        return "https://\(host)"
    }
}

public struct CallbackURL {
    public enum BaseURLType: CustomStringConvertible {
        case string(String)
        case autoResolving(HostResolver)
        
        public var description: String {
            switch self {
            case .autoResolving(let resolver):
                return resolver.resolve()
                
            case .string(let urlString):
                return urlString
            }
        }
    }
    
    public let baseURL: BaseURLType
    public let path: String
    
    
    public static func autoResolveHost(withPath path: String) -> CallbackURL {
        return CallbackURL(path: path)
    }
    
    private init(path: String) {
        self.baseURL = .autoResolving(HostResolver.shared)
        self.path = path
    }
    
    public init(block: () -> CallbackURL) {
        let callbackURL = block()
        self.baseURL = callbackURL.baseURL
        self.path = callbackURL.path
    }
    
    public init(baseURL: String, path: String){
        self.baseURL = .string(baseURL)
        self.path = path
    }
    
    public func absoluteURL() -> URL? {
        return URL(string: "\(baseURL)\(path)")
    }
    
    public func absoluteURL(withQueryItems queryItems: [URLQueryItem]) -> URL? {
        guard let url = absoluteURL() else { return nil }
        if queryItems.count > 0 {
            let additionalQuery = queryItems.filter({ $0.value != nil }).map({ "\($0.name)=\($0.value!)" }).joined(separator: "&")
            let separator = url.queryItems.count == 0 ? "?" : "&"
            return URL(string: url.absoluteString+separator+additionalQuery)
        }
        
        return url
    }
}
