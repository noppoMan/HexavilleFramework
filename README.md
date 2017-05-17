# HexavilleFramework
This is Application Framework Layer for [Hexaville](https://github.com/noppoMan/Hexaville)

All Hexaville applications should be written in this framework.


### Usage

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

### How to deploy?
See the Hexaville Documentation

### Debug with Builtin Web Server

You can debug your application with the builtin web server with `serve` command

```sh
YourApplication/.build/debug/YourApplication serve
# => Hexaville Builtin Server started at 0.0.0.0:3000
```

## License

HexavilleFramework is released under the MIT license. See LICENSE for details.
