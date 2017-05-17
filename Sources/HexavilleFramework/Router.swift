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
    var regexp: Regex { get }
    var paramKeys: [String] { get }
    var method: Request.Method { get }
    var handler: Respond { get }
    var middlewares: [Middleware] { get }
    
    func respond(_ request: Request, _ context: ApplicationContext) throws -> Response
}

extension Route {
    public func params(_ request: Request) -> [String: String] {
        guard let path = request.path else {
            return [:]
        }
        
        var parameters: [String: String] = [:]
        
        let values = regexp.groups(path)
        
        for (index, key) in paramKeys.enumerated() {
            parameters[key] = values[index]
        }
        
        return parameters
    }
}

struct BasicRoute: Route {
    let path: String
    let regexp: Regex
    let method: Request.Method
    let handler: Respond
    let paramKeys: [String]
    let middlewares: [Middleware]
    
    init(method: Request.Method, path: String, middlewares: [Middleware] = [], handler: @escaping Respond){
        let parameterRegularExpression = try! Regex(pattern: "\\{([[:alnum:]_]+)\\}")
        let pattern = parameterRegularExpression.replace(path, withTemplate: "([[:alnum:]_-]+)")
        
        self.method = method
        self.path = path
        self.regexp = try! Regex(pattern: "^" + pattern + "$")
        self.paramKeys = parameterRegularExpression.groups(path)
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
            if route.regexp.matches(path) && request.method == route.method {
                var request = request
                request.params = route.params(request)
                return (route, request)
            }
        }
        
        return nil
    }
}
