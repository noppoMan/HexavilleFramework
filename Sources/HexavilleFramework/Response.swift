//
//  Response.swift
//  HexavilleFramework
//
//  Created by Yuki Takei on 2017/05/23.
//
//

import Foundation


extension Response {
    public init(status: Status = .ok, headers: Headers = [:], body: String){
        self.init(status: status, headers: headers, body: .buffer(body.data))
    }
    
    public init(status: Status = .ok, headers: Headers = [:], body: Data){
        self.init(status: status, headers: headers, body: .buffer(body))
    }
}
