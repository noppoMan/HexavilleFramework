//
//  SessionMemoryStore.swift
//  HexavilleFramework
//
//  Created by Yuki Takei on 2017/06/01.
//
//

import Foundation

private var sharedMemoryStore: [String: [String: Any]] = [:]

public class SessionMemoryStore: SessionStoreProvider {
    
    public init(){}
    
    public func write(value: [String: Any], forKey: String, ttl: Int? = nil) throws {
        sharedMemoryStore[forKey] = value
    }
    
    public func read(forKey: String) throws -> [String : Any]? {
        return sharedMemoryStore[forKey]
    }
    
    public func delete(forKey: String) throws {
        sharedMemoryStore.removeValue(forKey: forKey)
    }
    
    public func flush() throws {
        sharedMemoryStore.removeAll()
    }
}
