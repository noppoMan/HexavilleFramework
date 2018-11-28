public protocol Message {
    var version: HTTPVersion { get set }
    var headers: HTTPHeaders { get set }
    var body: Body { get set }
    var storage: [String: Any] { get set }
}

extension Message {
    public var contentType: MediaType? {
        get {
            return headers.value(forKey: "Content-Type").flatMap({try? MediaType(string: $0)})
        }
        
        set(contentType) {
            if let value = contentType?.description {
                headers.add(name: "Content-Type", value: value)
            }
        }
    }
    
    public var contentLength: Int? {
        get {
            return headers.value(forKey: "Content-Type").flatMap({Int($0)})
        }
        
        set(contentLength) {
            if let value = contentLength?.description {
                headers.add(name: "Content-Length", value: value)
            }
        }
    }
    
    public var transferEncoding: String? {
        get {
            return headers.value(forKey: "Transfer-Encoding")
        }
        
        set(transferEncoding) {
            if let transferEncoding = transferEncoding {
                headers.add(name: "Transfer-Encoding", value: transferEncoding)
            }
        }
    }
    
    public var isChunkEncoded: Bool {
        return transferEncoding == "chunked"
    }
    
    public var connection: String? {
        get {
            return headers.value(forKey: "Connection")
        }
        
        set(connection) {
            if let connection = connection {
                headers.add(name: "Connection", value: connection)
            }
        }
    }
    
    public var isKeepAlive: Bool {
        if version.minor == 0 {
            return connection?.lowercased() == "keep-alive"
        }
        
        return connection?.lowercased() != "close"
    }
    
    public var isUpgrade: Bool {
        return connection?.lowercased() == "upgrade"
    }
    
    public var upgrade: String? {
        get {
            return headers.value(forKey: "Upgrade")
        }
        
        set(upgrade) {
            if let upgrade = upgrade {
                headers.add(name: "Upgrade", value: upgrade)
            }
        }
    }
}

extension Message {
    public var storageDescription: String {
        var string = "Storage:\n"
        
        if storage.isEmpty {
            string += "-"
        }
        
        for (key, value) in storage {
            string += "\(key): \(value)\n"
        }
        
        return string
    }
}
