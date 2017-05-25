import Foundation
import SwiftCLI
@_exported import Prorsum

public class HexavilleFramework {
    var routers: [Router] = []
    
    var middlewares: [Middleware] = []
    
    var catchHandler: (Error) -> Response = { error in
        return Response(status: .internalServerError, body: "\(error)".data)
    }
    
    var logger: Logger = StandardOutputLogger()

    public init() {}
}

extension HexavilleFramework {
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
        var headers: Headers = [:]
        header.components(separatedBy: "&").forEach {
            if $0.isEmpty { return }
            let splited = $0.components(separatedBy: "=")
            headers[splited[0]] = splited[1]
        }
        
        let request = Request(
            method: Request.Method(rawValue: method),
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
                return response
                
            case .next(let request):
                for router in routers {
                    if let (route, request) = router.matched(for: request) {
                        return try route.respond(request, context)
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
                "path": route.path,
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
        CLI.setup(name: "hexavillefw")
        CLI.register(commands: [
            GenerateRoutingManifestCommand(application: self),
            ExecuteCommand(application: self),
            ServeCommand(application: self)
        ])
        _ = CLI.go()
    }
}

class ServeCommand: Command {
    let name = "serve"
    let shortDescription = "Start Hexaville Builtin Server"
    let port = Key<String>("-p", "--port", usage: "Port")
    let backlog = Key<String>("-b", "--backlog", usage: "Number of backlog")
    
    weak var application: HexavilleFramework?
    
    init(application: HexavilleFramework){
        self.application = application
    }
    
    func execute() throws {
        guard let application = self.application else { return }
        let server = try HTTPServer { req, writer in
            do {
                let res = application.dispatch(request: req)
                try writer.serialize(res)
                print("\(req.method)".uppercased() + " \(req.path ?? "/") \(res.statusCode)")
            } catch {
                fatalError("\(error)")
            }
        }
        
        var listenPort: UInt = 3000
        if let portString = port.value, let p = UInt(portString) {
            listenPort = p
        }
        
        var backlogNum: Int = 1024
        if let backlog = backlog.value, let b = Int(backlog) {
            backlogNum = b
        }
        
        try server.bind(host: "0.0.0.0", port: listenPort)
        try server.listen(backlog: backlogNum)
        
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
    let header = Key<String>("--header", usage: "query string formated header string ex. Content-Type=application/json&Accept=application/json")
    let body = Key<String>("--body", usage: "body string")
    
    
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
        response.headers.forEach {
            headerDictionary[$0.key.description] = $0.value
        }
        
        var output: [String: Any] = [
            "statusCode": response.status.statusCode,
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
