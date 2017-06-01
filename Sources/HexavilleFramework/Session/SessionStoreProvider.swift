//
//  SessionStoreProvider.swift
//  HexavilleFramework
//
//  Created by Yuki Takei on 2017/06/01.
//
//

import Foundation

public protocol SessionStoreProvider {
    func delete(forKey: String) throws
    func read(forKey: String) throws -> [String: Any]?
    func write(value: [String: Any], forKey: String, ttl: Int?) throws
    func flush() throws
}

