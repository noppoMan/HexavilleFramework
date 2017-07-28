//
//  Router.swift
//  Hexaville
//
//  Created by Yuki Takei on 2017/05/11.
//
//

import Foundation

public typealias Respond = (Request, ApplicationContext) throws -> Response

public protocol Route {
    var path: String { get }
    var regexp: NSRegularExpression? { get }
    var paramKeys: [String] { get }
    var method: Request.Method { get }
    var handler: Respond { get }
    var middlewares: [Middleware] { get }
    
    func respond(_ request: Request, _ context: ApplicationContext) throws -> Response
}

extension Route {
    func apiGatewayStylePath() -> String {
        var components = path.components(separatedBy: "/")
        for (offset, element) in components.enumerated() {
            if element.isEmpty { continue }
            let headChar = element.substring(with: element.startIndex..<element.index(element.startIndex, offsetBy: 1))
            if headChar == ":" {
                let paramKey = element.substring(with: element.index(element.startIndex, offsetBy: 1)..<element.endIndex)
                components[offset] = "{\(paramKey)}"
            }
        }
        return components.joined(separator: "/")
    }
    
    func match(with requestedPath: String) -> (Bool, [String: String]?) {
        guard let regexp = self.regexp else {
            return (self.path == requestedPath, nil)
        }
        
        let results = regexp.matches(in: requestedPath, options: [], range: NSMakeRange(0, requestedPath.characters.count))
        
        guard let result = results.first else { return (false, nil) }
        
        if paramKeys.count == 0 {
            return (false, nil)
        }
        
        var params: [String: String] = [:]
        
        for (offset, element) in paramKeys.enumerated() {
            if let range = Range<String.Index>(result.rangeAt(offset+1), in: requestedPath) {
                params[element] = requestedPath.substring(with: range)
            }
        }
        
        return (true, params)
    }
}

struct BasicRoute: Route {
    let path: String
    let regexp: NSRegularExpression?
    let method: Request.Method
    let handler: Respond
    let paramKeys: [String]
    let middlewares: [Middleware]
    
    init(method: Request.Method, path: String, middlewares: [Middleware] = [], handler: @escaping Respond){
        
        let (regex, _, strings) = RouteRegex.sharedInstance.buildRegex(fromPattern: path, allowPartialMatch: false)
        self.method = method
        self.path = path
        self.regexp = regex
        self.paramKeys = strings ?? []
        self.middlewares = middlewares
        self.handler = handler
    }
    
    func respond(_ request: Request, _ context: ApplicationContext) throws -> Response {
        switch try middlewares.chain(request, context: context) {
        case .respond(to: let response):
            return response
            
        case .next(let request):
            return try handler(request, context)
        }
    }
}

public class Router {
    var routes: [Route] = []
    
    public init(){}
    
    public func use(_ method: Request.Method, middlewares: [Middleware] = [], _ path: String, _ handler: @escaping Respond) {
        let route = BasicRoute(method: method, path: path, middlewares: middlewares, handler: handler)
        routes.append(route)
    }
    
    func matched(for request: Request) -> (Route, Request)? {
        let path = request.path ?? "/"
        
        for route in routes {
            let (matched, pamras) = route.match(with: path)
            if matched && request.method == route.method {
                var request = request
                request.params = pamras
                return (route, request)
            }
        }
        
        return nil
    }
}

