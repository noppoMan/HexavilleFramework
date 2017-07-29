//
//  Session.swift
//  HexavilleFramework
//
//  Created by Yuki Takei on 2017/06/01.
//
//

import Foundation

public final class Session {
    
    public let id: String
    
    public let ttl: Int?
    
    var storage = [String:Any]()
    
    let store: SessionStoreProvider
    
    public init(id: String, store: SessionStoreProvider, ttl: Int? = nil){
        self.id = id
        self.store = store
        self.ttl = ttl
    }
    
    public func destroy() {
        do {
            try self.store.delete(forKey: id)
            storage.removeAll()
        } catch {
            print("Session was failed to destroy. reason: \(error)")
        }
    }
    
    public subscript(key: String) -> Any? {
        get {
            return storage[key]
        }
        set {
            storage[key] = newValue
        }
    }
    
    func write() {
        if storage.isEmpty { return }
        do {
            try self.store.write(value: storage, forKey: id, ttl: ttl)
        } catch {
            print("Session was failed to write. reason: \(error)")
        }
    }
}

extension Session {
    static func generateId() -> String {
        return UUID().uuidString
    }
}
