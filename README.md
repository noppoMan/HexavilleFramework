# HexavilleFramework
This is Application Framework Layer for [Hexaville](https://github.com/noppoMan/Hexaville)

All Hexaville applications should be written in this framework.

## Table of contents

* [Routing](#routing)
* [Middleware](#middleware)
* [ApplicationContext](#applicationcontext)
* [Session](#session)
* [Error Handling](#error-handling)
* [How to Deploy](#how-to-deploy)
* [Builtin Web Server](#builtin-web-server)


## Usage

```swift
import HexavilleFramework

let app = HexavilleFramework()

app.use(RandomNumberGenerateMiddleware())

let router = Router()

router.use(.get, "/") { request, context in
    let htmlString = "<html><head><title>Hexaville</title></head><body>Welcome to Hexaville!</body></html>"
    return Response(headers: ["Content-Type": "text/html"], body: htmlString)
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

router.use(.get, middlewares: [RandomNumberGenerateMiddleware()], "/hello") { response, context in
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
        
        context.memory["JWT"] = jwt
        
        return .next(request)
    }
}

app.use(JWTAuthenticationMiddleware())
```

## ApplicationContext

ApplicationContext is the shared storage for the request. 

#### Available properties

* memory
* responseHeaders
* session

### memory

`memory` property is used for share value between Middlewares and the Router.

```swift
struct FooMiddleware: Middleware {
    func respond(to request: Request, context: ApplicationContext) throws -> Chainer {
        context.memory["Foo"] = "Bar"
        return .next(request)
    }
}

app.use(.get, middlewares: [FooMiddleware()], "/foo") { request, context in
    print(context["Foo"]) // Bar
}
```

### responseHeaders

In the some middlewares, You'll want to preset response headers, sunch as `Set-Cookie`. By preseting HTTP headers into the `responseHeaders` property, the header values are automatically adedd to the actual response on the Framework side.

Here is an example.

```swift
struct CookieSetMiddleware: Middleware {
    func respond(to request: Request, context: ApplicationContext) throws -> Chainer {
        context.responseHeaders["Set-Cookie"] = "vaild cookie value"
        return .next(request)
    }
}

app.use(.get, middlewares: [FooMiddleware()], "/foo") { request, context in
    return Response(body: "OK")
}
```

#### response
```
HTTP/1.1 200

Set-Cookie: vaild cookie value

OK
```

### session

`session` property is used for data persistence that use in the application.
See [Session](#session) for the detail.

## Session

HexavilleFramework provides Session Mechanism by `SessionMiddleware`. You can create your own SessionStore to conform `SessionStoreProvider` protocol.

Bundled Sesssion Store is `MemoryStore`.

#### Available Session Stores

* MemoryStore: Bundled Session Store
* [DynamoDBSessionStore](https://github.com/Hexaville/DynamodbSessionStore)
* [RedisSessionStore](https://github.com/Hexaville/RedisSessionStore)

### Usage

```swift
let session = SessionMiddleware(
    cookieAttribute: CookieAttribute(
        expiration: 3600,
        httpOnly: true,
        secure: false
    ),
    store: MemoryStore()
)

app.use(session)

app.use { request, context in
    // add value to session(memory)
    context.session["user"] = User(name: "Luke", age: 25).serializeToJSONString()
}

var router = Router()

// take value from context.session
router.use(.get, "/") { request, context in
    return Response(body: context.session["user"]!)
}
```

## Error handling

You can catch all of the errors that are throwed in the session with `catch` error handler.
In the catch closure, the best way of the determining error response is pattern matching for the `Error`.

```swift
let app = HexavilleFramework()

app.use(.....)

app.catch { error in
    switch error {
    case FooError.notFound:
        return Response(status: .notFound)
    case JWTAuthenticationMiddleware.authrozationHeaderIsMissing:
        return Response(status: .unauthorized)
    default:
        return Response(status: .internalServerError)
    }
}

try app.run()
```

## How to deploy?
See the Hexaville [Documentation](https://github.com/noppoMan/Hexaville)

## Builtin Web Server

You can debug your application with the builtin web server with `serve` command.

```sh
YourApplication/.build/debug/YourApplication serve
# => Hexaville Builtin Server started at 0.0.0.0:3000
```

## License

HexavilleFramework is released under the MIT license. See LICENSE for details.
