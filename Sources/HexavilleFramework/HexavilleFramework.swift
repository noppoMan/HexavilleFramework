import Foundation
import SwiftCLI
import NIO
@_exported import NIOHTTP1
import PKGConfig

public class HexavilleFramework {
    let config: PKGConfig
    
    var routers: [Router] = []
    
    var middlewares: [Middleware] = []
    
    var catchHandler: (Error) -> Response = { error in
        return Response(status: HTTPResponseStatus.internalServerError, body: "\(error)".data)
    }
    
    var logger: Logger = StandardOutputLogger()
    
    public init(_ config: PKGConfig) {
        self.config = config
    }
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
    
    func dispatch(method: String, path: String, header: String, body: String?) -> Response {
        var headers: HTTPHeaders = HTTPHeaders()
        header.components(separatedBy: "&").forEach {
            if $0.isEmpty { return }
            var splited = $0.components(separatedBy: "=")
            headers.add(name: splited.removeFirst(), value: splited.joined(separator: "="))
        }
        
        let request = Request(
            method: HTTPMethod(rawValue: method),
            url: path == "/" ? URL(string: "aws://api-gateway/")! :  URL(string: "aws://api-gateway/\(path.trimLeft(["/"]))")!,
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
    
    func generateRoutingManifest() throws -> Data {
        var routingManifest: [[String: Any]] = []
        
        let routes: [Route] = routers.flatMap({ $0.routes })
        
        for route in routes {
            let routeManifest = [
                "path": route.apiGatewayStylePath(),
                "method": "\(route.method)"
            ]
            routingManifest.append(routeManifest)
        }
        
        let manifest: [String: Any] = [
            "routing": routingManifest
        ]
        return try JSONSerialization.data(withJSONObject: manifest, options: [.prettyPrinted])
    }
    
    public func run() throws {
        let hexavilleFrameworkCLI = CLI(name: "hexavillefw")
        hexavilleFrameworkCLI.commands = [
            GenerateRoutingManifestCommand(application: self),
            ExecuteCommand(application: self),
            ServeCommand(application: self),
            GeneratePKGConfigJSONCommand(application: self)
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
            
            ctx.writeAndFlush(
                NIOAny(HTTPServerResponsePart.end(nil)),
                promise: nil
            )
        }
        
        var listenPort: Int = 3000
        if let portString = port.value, let p = Int(portString) {
            listenPort = p
        }
        
        try server.start(host: "0.0.0.0", port: listenPort)
        
        print("Hexaville Builtin Server started at 0.0.0.0:\(listenPort)")
        
        RunLoop.main.run()
    }
}

class GenerateRoutingManifestCommand: Command {
    let name = "gen-routing-manif"
    let shortDescription = "Generate routing manifest file"
    let dest = Parameter()
    
    weak var application: HexavilleFramework?
    
    init(application: HexavilleFramework){
        self.application = application
    }
    
    func execute() throws {
        if let manifeset = try application?.generateRoutingManifest() {
            try manifeset.write(to: URL(string: "file://\(dest.value)/.routing-manifest.json")!, options: [])
        }
    }
}

class ExecuteCommand: Command {
    let name = "execute"
    let shortDescription = "Execute the specified resource. ex. execute GET /"
    let method = Parameter()
    let path = Parameter()
    let header = Key<String>("--header", description: "query string formated header string ex. Content-Type=application/json&Accept=application/json")
    let body = Key<String>("--body", description: "body string")
    
    weak var application: HexavilleFramework?
    
    init(application: HexavilleFramework){
        self.application = application
    }
    
    func execute() throws {
        guard let application = self.application else { return }
        let response = application.dispatch(
            method: method.value,
            path: path.value,
            header: header.value ?? "",
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
        
        application.logger.log(level: .info, message: "[\(requestData)] \(method.value.uppercased()) \(path.value) --header \(header.value ?? "") --body \(self.body.value ?? "") \(response.statusCode)")
        
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

class GeneratePKGConfigJSONCommand: Command {
    let name = "gen-pkg-conf"
    let shortDescription = "Genrate PkgConfig JSON file"
    let dest = Parameter()
    
    weak var application: HexavilleFramework?
    
    init(application: HexavilleFramework){
        self.application = application
    }
    
    func execute() throws {
        if let pkgConfig = application?.config {
            try pkgConfig.encodeToJSONUTF8String().write(
                to: URL(string: "file://\(dest.value)/.hexaville.pkgconfig.json")!,
                atomically: true,
                encoding: .utf8
            )
        }
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
