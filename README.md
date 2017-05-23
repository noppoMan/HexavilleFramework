# HexavilleFramework
This is Application Framework Layer for [Hexaville](https://github.com/noppoMan/Hexaville)

All Hexaville applications should be written in this framework.


## Usage

```swift
import HexavilleFramework

let app = HexavilleFramework()

app.use(RandomNumberGenerateMiddleware())

let router = Router()

router.use(.get, "/") { request, context in
    let str = "<html><head><title>Hexaville</title></head><body>Welcome to Hexaville!</body></html>"
    return Response(headers: ["Content-Type": "text/html"], body: .buffer(str.data))
}

app.use(router)

try app.run()
```

## Routing

### Basic Routing

```swift
let app = HexavilleFramework()

let router = Router()

router.use(.get, "/hello") { response, context in
    return Response(body: "Hello")
}

app.use(router)
```

### Routing with Middleware

```swift
let app = HexavilleFramework()

let router = Router()

router.use(.get, [RandomNumberGenerateMiddleware()], "/hello") { response, context in
    return Response(body: "Random number is \(context["randomNumber"])")
}

app.use(router)
```

## Middleware

You can create your own Middlewares to confirm `Middleware` protocol.

```swift
enum JWTAuthenticationMiddleware {
    case authrozationHeaderIsMissing
}

struct JWTAuthenticationMiddleware: Middleware {
    func respond(to request: Request, context: ApplicationContext) throws -> Chainer {
        guard let jwtString = request.headers["Authorization"] else {
            throw JWTAuthenticationMiddleware.authrozationHeaderIsMissing
        }
        
        let jwt = try JWT.decode(jwtString)
        
        context.storage["JWT"] = jwt
        
        return .next(request)
    }
}

app.use(JWTAuthenticationMiddleware())
```


## How to deploy?
See the Hexaville [Documentation](https://github.com/noppoMan/Hexaville)

## Debug with Builtin Web Server

You can debug your application with the builtin web server with `serve` command

```sh
YourApplication/.build/debug/YourApplication serve
# => Hexaville Builtin Server started at 0.0.0.0:3000
```

## License

HexavilleFramework is released under the MIT license. See LICENSE for details.
