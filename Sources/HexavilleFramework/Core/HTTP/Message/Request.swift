import Foundation
import NIOHTTP1

public struct Request : Message {
    public var method: HTTPMethod
    public var url: URL
    public var version: HTTPVersion
    public var headers: HTTPHeaders
    public var body: Body
    public var storage: [String: Any]
    
    public init(method: HTTPMethod, url: URL, version: HTTPVersion, headers: HTTPHeaders, body: Body) {
        self.method = method
        self.url = url
        self.version = version
        self.headers = headers
        self.body = body
        self.storage = [:]
    }
}

public protocol RequestInitializable {
    init(request: Request)
}

public protocol RequestRepresentable {
    var request: Request { get }
}

public protocol RequestConvertible : RequestInitializable, RequestRepresentable {}

extension Request : RequestConvertible {
    public init(request: Request) {
        self = request
    }
    
    public var request: Request {
        return self
    }
}

extension Request {
    public init(method: HTTPMethod = .GET, url: URL = URL(string: "/")!, headers: HTTPHeaders = HTTPHeaders(), body: Body = .empty) {
        self.init(
            method: method,
            url: url,
            version: HTTPVersion(major: 1, minor: 1),
            headers: headers,
            body: body
        )
        
        switch body {
        case let .buffer(body):
            self.headers.add(name: "Content-Length", value: body.count.description)
        }
    }
}

extension Request {
    public var path: String? {
        return url.path
    }
    
    public var queryItems: [URLQueryItem] {
        return url.queryItems
    }
}

extension Request {
    public var accept: [MediaType] {
        get {
            var acceptedMediaTypes: [MediaType] = []
            if let acceptString = headers.value(forKey: "Accept") {
                let acceptedTypesString = acceptString.split(separator: ",")
                
                for acceptedTypeString in acceptedTypesString {
                    let acceptedTypeTokens = acceptedTypeString.split(separator: ";")
                    
                    if acceptedTypeTokens.count >= 1 {
                        let mediaTypeString = acceptedTypeTokens[0].trim()
                        if let acceptedMediaType = try? MediaType(string: mediaTypeString) {
                            acceptedMediaTypes.append(acceptedMediaType)
                        }
                    }
                }
            }
            
            return acceptedMediaTypes
        }
        
        set(accept) {
            headers.add(
                name: "Accept",
                value: accept.map({$0.type + "/" + $0.subtype}).joined(separator: ", ")
            )
        }
    }
    
    public var cookies: Set<Cookie> {
        get {
            return headers.value(forKey: "Cookie").flatMap({Set<Cookie>(cookieHeader: $0)}) ?? []
        }
        
        set(cookies) {
            headers.add(name: "Cookie", value: cookies.map({$0.description}).joined(separator: ", "))
        }
    }
    
    public var authorization: String? {
        get {
            return headers.value(forKey: "Authorization")
        }
        
        set(authorization) {
            if let authorization = authorization {
                headers.add(name: "Authorization", value: authorization)
            }
        }
    }
    
    public var host: String? {
        get {
            return headers.value(forKey: "Host")
        }
        
        set(host) {
            if let host = host {
                headers.add(name: "Host", value: host)
            }
        }
    }
    
    public var userAgent: String? {
        get {
            return headers.value(forKey: "User-Agent")
        }
        
        set(userAgent) {
            if let userAgent = userAgent {
                headers.add(name: "User-Agent", value: userAgent)
            }
        }
    }
}

extension Request {
    public var pathParameters: [String: String] {
        get {
            return storage["pathParameters"] as? [String: String] ?? [:]
        }
        
        set(pathParameters) {
            storage["pathParameters"] = pathParameters
        }
    }
}

extension Request : CustomStringConvertible {
    public var requestLineDescription: String {
        return String(describing: method) + " " + url.absoluteString + " HTTP/" + String(describing: version.major) + "." + String(describing: version.minor) + "\n"
    }
    
    public var description: String {
        return requestLineDescription +
            headers.description
    }
}

extension Request : CustomDebugStringConvertible {
    public var debugDescription: String {
        return description + "\n" + storageDescription
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

extension URL {
    public var queryItems: [URLQueryItem] {
        #if os(Linux)
        //URLComponents.queryItems crashes on Linux.
        //FIXME: remove that when Foundation will be fixed
        //https://bugs.swift.org/browse/SR-384
        guard let queryPairs = query?.components(separatedBy: "&") else { return [] }
        let items = queryPairs.map { (s) -> URLQueryItem in
            let pair = s.components(separatedBy: "=")
            
            let name = pair[0]
            let value: String? = pair.count > 1 ? pair[1] : nil
            
            return URLQueryItem(name: name, value: value?.removingPercentEncoding)
        }
        
        return items
        
        
        #else
        return URLComponents(url: self, resolvingAgainstBaseURL: false)?.queryItems ?? []
        #endif
    }
}
