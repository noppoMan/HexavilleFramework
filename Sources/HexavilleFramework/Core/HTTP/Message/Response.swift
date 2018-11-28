import Foundation

public struct Response : Message {
    public var version: HTTPVersion
    public var status: HTTPResponseStatus
    public var headers: HTTPHeaders
    public var cookieHeaders: Set<String>
    public var body: Body
    public var storage: [String: Any] = [:]
    
    public init(version: HTTPVersion, status: HTTPResponseStatus, headers: HTTPHeaders, cookieHeaders: Set<String>, body: Body) {
        self.version = version
        self.status = status
        self.headers = headers
        self.cookieHeaders = cookieHeaders
        self.body = body
    }
}

public protocol ResponseInitializable {
    init(response: Response)
}

public protocol ResponseRepresentable {
    var response: Response { get }
}

public protocol ResponseConvertible : ResponseInitializable, ResponseRepresentable {}

extension Response : ResponseConvertible {
    public init(response: Response) {
        self = response
    }
    
    public var response: Response {
        return self
    }
}

extension Response {
    public init(status: HTTPResponseStatus = .ok, headers: HTTPHeaders = HTTPHeaders(), body: Body) {
        self.init(
            version: HTTPVersion(major: 1, minor: 1),
            status: status,
            headers: headers,
            cookieHeaders: [],
            body: body
        )
        
        switch body {
        case let .buffer(body):
            self.headers.add(name: "Content-Length", value: body.count.description)
        default:
            self.headers.add(name: "Transfer-Encoding", value: "chunked")
        }
    }
}

extension Response {
    public var statusCode: Int {
        return Int(status.code)
    }
    
    public var reasonPhrase: String {
        return status.reasonPhrase
    }
}

extension Response {
    public var cookies: Set<AttributedCookie> {
        get {
            var cookies = Set<AttributedCookie>()
            
            for header in cookieHeaders {
                if let cookie = AttributedCookie(header) {
                    cookies.insert(cookie)
                }
            }
            
            return cookies
        }
        
        set(cookies) {
            var headers = Set<String>()
            
            for cookie in cookies {
                let header = String(describing: cookie)
                headers.insert(header)
            }
            
            cookieHeaders = headers
        }
    }
}


extension Response : CustomStringConvertible {
    public var statusLineDescription: String {
        return "HTTP/" + String(version.major) + "." + String(version.minor) + " " + String(statusCode) + " " + reasonPhrase + "\n"
    }
    
    public var description: String {
        return statusLineDescription +
            headers.description
    }
}

extension Response : CustomDebugStringConvertible {
    public var debugDescription: String {
        return description + "\n" + storageDescription
    }
}

extension Response {
    public init(status: HTTPResponseStatus = .ok, headers: HTTPHeaders = HTTPHeaders(), body: String){
        self.init(status: status, headers: headers, body: .buffer(body.data))
    }
    
    public init(status: HTTPResponseStatus = .ok, headers: HTTPHeaders = HTTPHeaders(), body: Data){
        self.init(status: status, headers: headers, body: .buffer(body))
    }
}
