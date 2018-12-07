//
//  Request.swift
//  HexavilleFramework
//
//  Created by Yuki Takei on 2017/05/17.
//
//

import NIOHTTP1

extension HTTPMethod {
    init(rawValue: String){
        switch rawValue.lowercased() {
        case "delete":
            self = .DELETE
        case "get":
            self = .GET
        case "head":
            self = .HEAD
        case "post":
            self = .POST
        case "put":
            self = .PUT
        case "connect":
            self = .CONNECT
        case "options":
            self = .OPTIONS
        case "trace":
            self = .TRACE
        case "patch":
            self = .PATCH
        default:
            self = .GET
        }
    }
}
