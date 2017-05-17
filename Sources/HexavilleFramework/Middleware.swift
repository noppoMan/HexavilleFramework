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
    public init() {}
}

public enum Chainer {
    case respond(to: Response)
    case next(Request)
}

public protocol Middleware {
    func respond(to request: Request, context: ApplicationContext) throws -> Chainer
}

extension Collection where Self.Iterator.Element == Middleware {
    public func chain(_ request: Request, context: ApplicationContext) throws -> Chainer {
        var request = request
        
        for middleware in self.reversed() {
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
