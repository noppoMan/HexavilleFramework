//
//  Middleware.swift
//  Hexaville
//
//  Created by Yuki Takei on 2017/05/11.
//
//

import Foundation

public class ApplicationContext {
    public var storage: [String: Any] = [:]
    public var storageForResponseHeaders: Headers = [:]
    public init() {}
}

public enum Chainer {
    case respond(to: Response)
    case next(Request)
}

public protocol Middleware {
    func respond(to request: Request, context: ApplicationContext) throws -> Chainer
}

public struct BasicMiddleware: Middleware {
    
    let handler: (Request, ApplicationContext) throws -> Chainer
    
    public init(handler: @escaping (Request, ApplicationContext) throws -> Chainer) {
        self.handler = handler
    }
    
    public func respond(to request: Request, context: ApplicationContext) throws -> Chainer {
        return try self.handler(request, context)
    }
}

extension Collection where Self.Iterator.Element == Middleware {
    public func chain(_ request: Request, context: ApplicationContext) throws -> Chainer {
        var request = request
        
        for middleware in self {
            let chainer = try middleware.respond(to: request, context: context)
            switch chainer {
            case .next(let req):
                request = req
                continue
            default:
                return chainer
            }
        }
        
        return .next(request)
    }
}
