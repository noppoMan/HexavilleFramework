//
//  HTTPHeaders.swift
//
//  Created by Yuki Takei on 2018/11/28.
//

import Foundation

extension HTTPHeaders {
    public func value(forKey key: String) -> String? {
        for (name, value) in self {
            if key.lowercased() == name.lowercased() {
                return value
            }
        }
        return nil
    }
    
    init(dictionary: [String: String]) {
        self.init()
        for (name, value) in dictionary {
            self.add(name: name, value: value)
        }
    }
}

extension HTTPHeaders:  ExpressibleByDictionaryLiteral {
    public typealias Key = String
    public typealias Value = String
    
    public init(dictionaryLiteral elements: (String, String)...) {
        self.init()
        for (name, value) in elements {
            self.add(name: name, value: value)
        }
    }
}
