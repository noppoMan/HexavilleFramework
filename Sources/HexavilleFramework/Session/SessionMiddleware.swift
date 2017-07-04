//
//  SessionMiddleware.swift
//  HexavilleFramework
//
//  Created by Yuki Takei on 2017/06/01.
//
//

import Foundation

public struct CookieAttribute {
    
    public let key: String
    
    public let expiration: Int?
    
    public let httpOnly: Bool
    
    public let secure: Bool
    
    public let domain: String?
    
    public let path: String?
    
    public init(key: String = "hexaville.sid", expiration: Int? = nil, httpOnly: Bool = true, secure: Bool = true, domain: String? = nil, path: String? = nil){
        self.key = key
        self.expiration = expiration
        self.httpOnly = httpOnly
        self.secure = secure
        self.domain = domain
        self.path = path
    }
}

public final class SessionMiddleware: Middleware {
    
    public let cookieAttribute: CookieAttribute
    
    public let store: SessionStoreProvider
    
    public init(cookieAttribute: CookieAttribute = CookieAttribute(), store: SessionStoreProvider) {
        self.cookieAttribute = cookieAttribute
        self.store = store
    }
    
    public func respond(to request: Request, context: ApplicationContext) throws -> Chainer {
        var request = request
        
        guard let cookie = request.cookies.filter({ $0.name == cookieAttribute.key }).first else {
            let id = Session.generateId()
            context.responseHeaders["Set-Cookie"] = generateCookie(withSessionId: id).description
            return .next(request)
        }
        
        do {
            let session = Session(id: cookie.value, store: store, ttl: cookieAttribute.expiration)
            context.session = session
            if let values = try store.read(forKey: session.id) {
                session.storage = values
            }
        } catch {
            print("Session was failed to read. reason: \(error)")
        }
        
        return .next(request)
    }
    
    public func generateCookie(withSessionId value: String) -> AttributedCookie {
        var maxAge: AttributedCookie.Expiration?
        if let ttl = cookieAttribute.expiration {
            maxAge = .maxAge(ttl)
        } else {
            maxAge = nil
        }
        
        return AttributedCookie(
            name: cookieAttribute.key,
            value: value,
            expiration: maxAge,
            domain: cookieAttribute.domain,
            path: cookieAttribute.path,
            secure: cookieAttribute.secure,
            httpOnly: cookieAttribute.httpOnly
        )
    }
}
