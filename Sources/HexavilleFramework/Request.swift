//
//  Request.swift
//  HexavilleFramework
//
//  Created by Yuki Takei on 2017/05/17.
//
//

import Foundation

extension Request.Method {
    init(rawValue: String){
        switch rawValue.lowercased() {
        case "delete":
            self = .delete
        case "get":
            self = .get
        case "head":
            self = .head
        case "post":
            self = .post
        case "put":
            self = .put
        case "connect":
            self = .connect
        case "options":
            self = .options
        case "trace":
            self = .trace
        case "patch":
            self = .patch
        default:
            self = .other(method: rawValue)
        }
    }
}

extension Request {
    public var params: [String: Any]? {
        get {
            return self.storage["params"] as? [String: Any]
        }
        
        set {
            self.storage["params"] = newValue
        }
    }
}

public func ==(lhs: Request.Method, rhs: Request.Method) -> Bool {
    return "\(lhs)" == "\(rhs)"
}
