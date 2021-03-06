import Foundation
import SwiftCLI
import NIO
@_exported import NIOHTTP1

public class HexavilleFramework {
    var routers: [Router] = []
    
    var middlewares: [Middleware] = []
    
    var catchHandler: (Error) -> Response = { error in
        return Response(status: HTTPResponseStatus.internalServerError, body: "\(error)".data)
    }
    
    var logger: Logger = StandardOutputLogger()
    
    public init() {}
}

extension HexavilleFramework {
    public func use(_ middleware: @escaping (Request, ApplicationContext) throws -> Chainer ) {
        self.middlewares.append(BasicMiddleware(handler: middleware))
    }
    
    public func use(_ middleware: Middleware) {
        self.middlewares.append(middleware)
    }
    
    public func use(_ router: Router) {
        routers.append(router)
    }
    
    public func `catch`(_ handler: @escaping (Error) -> Response) {
        self.catchHandler = handler
    }
    
    func dispatch(method: String, path: String, header: [String: String], body: String?) -> Response {
        var headers: HTTPHeaders = HTTPHeaders()
        header.forEach {
            headers.add(name: $0.key, value: $0.value)
        }

        // Percent encode URL since API Gateway Lambda Proxy Integration decodes
        // the strings and the URL will be considered invalid without encoding
        let encodedPath = path.trimLeft(["/"]).addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed
        )!
        let request = Request(
            method: HTTPMethod(rawValue: method),
            url: path == "/" ? URL(string: "aws://api-gateway/")! :  URL(string: "aws://api-gateway\(encodedPath)")!,
            headers: headers,
            body: .buffer(body?.data ?? Data())
        )
        
        return dispatch(request: request)
    }
    
    func dispatch(request: Request) -> Response {
        do {
            let context = ApplicationContext()
            let chainer = try middlewares.chain(request, context: context)
            switch chainer {
            case .respond(to: let response):
                var response = response
                for (key, value) in context.responseHeaders {
                    response.headers.add(name: key, value: value)
                }
                context.session?.write()
                return response
                
            case .next(let request):
                for router in routers {
                    if let (route, request) = router.matched(for: request) {
                        var response = try route.respond(request, context)
                        for (key, value) in context.responseHeaders {
                            response.headers.add(name: key, value: value)
                        }
                        context.session?.write()
                        return response
                    }
                }
            }
        } catch {
            return self.catchHandler(error)
        }
        
        return Response(status: .notFound, body: "\(request.path ?? "/") is not found")
    }
    
    public func run() throws {
        let hexavilleFrameworkCLI = CLI(name: "hexavillefw")
        hexavilleFrameworkCLI.commands = [
            ExecuteCommand(application: self),
            ServeCommand(application: self)
        ]
        _ = hexavilleFrameworkCLI.go()
    }
}

class ServeCommand: Command {
    let name = "serve"
    let shortDescription = "Start Hexaville Builtin Server"
    let port = Key<String>("-p", "--port", description: "Port")
    let backlog = Key<String>("-b", "--backlog", description: "Number of backlog")
    
    weak var application: HexavilleFramework?
    
    init(application: HexavilleFramework){
        self.application = application
    }
    
    func execute() throws {
        guard let application = self.application else { return }
        let server = HTTPServer { request, bodyData, ctx in
            let hfRequest = Request(
                method: request.method,
                url: URL(string: request.uri)!,
                headers: request.headers,
                body: bodyData != nil ? .buffer(bodyData!) : .empty
            )
            
            let response = application.dispatch(request: hfRequest)
            
            let headerData = NIOAny(
                HTTPServerResponsePart.head(
                    httpResponseHead(
                        request: request,
                        status: response.status,headers:
                        response.headers
                    )
                )
            )
            
            ctx.write(headerData, promise: nil)
            
            let body = NIOAny(
                HTTPServerResponsePart.body(.byteBuffer(response.body.asByteBuffer()))
            )
            ctx.write(body, promise: nil)
        }
        
        var listenPort: Int = 3000
        if let portString = port.value, let p = Int(portString) {
            listenPort = p
        }
        
        try server.start(port: listenPort)
    }
}

class ExecuteCommand: Command {
    let name = "execute"
    let shortDescription = "Execute the specified resource. ex. execute GET /"
    let method = Parameter()
    let path = Parameter()
    let header = Key<String>("--header", description: "base64 encoded query string formated header string e.g.  base64(Content-Type=application/json&Accept=application/json)")
    let body = Key<String>("--body", description: "body string")
    
    weak var application: HexavilleFramework?
    
    init(application: HexavilleFramework){
        self.application = application
    }
    
    func execute() throws {
        guard let application = self.application else { return }
        let decodedHeader = String(data: Data(base64Encoded: header.value ?? "") ?? Data(), encoding: .utf8) ?? ""
        
        var header = [String: String]()
        
        decodedHeader.split(separator: "&").forEach {
            let components = $0.split(separator: "=")
            if let key = components.first, let value = components.last {
                header[String(key)] = String(value)
            }
        }

        let response = application.dispatch(
            method: method.value,
            path: path.value,
            header: header,
            body: self.body.value
        )
        
        var headerDictionary: [String: String] = [:]
        response.headers.forEach { name, value in
            headerDictionary[name] = value
        }
        
        var output: [String: Any] = [
            "statusCode": response.status.code,
            "headers": headerDictionary,
            "body": String(data: response.body.asData(), encoding: .utf8) ?? ""
        ]
        
        if let contentType = response.contentType {
            switch (contentType.type, contentType.subtype) {
            case ("image", _), ("application", "x-protobuf"), ("application", "x-google-protobuf"), ("application", "octet-stream"):
                output["isBase64Encoded"] = true
            default:
                break
            }
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
        let requestData = formatter.string(from: Date())
        
        application.logger.log(level: .info, message: "[\(requestData)] \(method.value.uppercased()) \(path.value) --header \(decodedHeader) --body \(self.body.value ?? "") \(response.statusCode)")
        
        print("hexaville response format/json")
        print("\t")
        do {
            let data = try JSONSerialization.data(withJSONObject: output, options: [.prettyPrinted])
            print(String(data: data, encoding: .utf8) ?? "")
        } catch {
            print("{\"statusCode: 500, \"headers\": {\"Content-Type\": \"text/plain\"}, body: \"\(error)\"")
        }
        print("\t")
        print("\t")
    }
}

private func httpResponseHead(request: HTTPRequestHead, status: HTTPResponseStatus, headers: HTTPHeaders = HTTPHeaders()) -> HTTPResponseHead {
    var head = HTTPResponseHead(version: request.version, status: status, headers: headers)
    let connectionHeaders: [String] = head.headers[canonicalForm: "connection"].map { $0.lowercased() }
    
    if !connectionHeaders.contains("keep-alive") && !connectionHeaders.contains("close") {
        // the user hasn't pre-set either 'keep-alive' or 'close', so we might need to add headers
        switch (request.isKeepAlive, request.version.major, request.version.minor) {
        case (true, 1, 0):
            // HTTP/1.0 and the request has 'Connection: keep-alive', we should mirror that
            head.headers.add(name: "Connection", value: "keep-alive")
        case (false, 1, let n) where n >= 1:
            // HTTP/1.1 (or treated as such) and the request has 'Connection: close', we should mirror that
            head.headers.add(name: "Connection", value: "close")
        default:
            // we should match the default or are dealing with some HTTP that we don't support, let's leave as is
            ()
        }
    }
    return head
}
