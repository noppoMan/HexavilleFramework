//
//  HTTPServer.swift
//  CNIOAtomics
//
//  Created by Yuki Takei on 2018/11/27.
//

import Foundation
import NIO
import NIOHTTP1

public typealias HTTPRequestEvent = (HTTPRequestHead, Data?, ChannelHandlerContext) -> Void

private final class HTTPHandler: ChannelInboundHandler {
    public typealias InboundIn = HTTPServerRequestPart
    public typealias OutboundOut = HTTPServerResponsePart

    private enum State {
        case idle
        case waitingForRequestBody
        case sendingResponse

        mutating func requestReceived() {
            precondition(self == .idle, "Invalid state for request received: \(self)")
            self = .waitingForRequestBody
        }

        mutating func requestComplete() {
            precondition(self == .waitingForRequestBody, "Invalid state for request complete: \(self)")
            self = .sendingResponse
        }

        mutating func responseComplete() {
            precondition(self == .sendingResponse, "Invalid state for response complete: \(self)")
            self = .idle
        }
    }

    private var bodyBuffer: ByteBuffer! = nil
    private var keepAlive = false
    private var state = State.idle
    // private let htdocsPath: String

    private var infoSavedRequestHead: HTTPRequestHead?
    private var infoSavedBodyBytes: Int = 0

    private var continuousCount: Int = 0

    private var handler: ((ChannelHandlerContext, HTTPServerRequestPart) -> Void)?
    private var handlerFuture: EventLoopFuture<Void>?
    // private let fileIO: NonBlockingFileIO
    private let defaultResponse = "Hello World\r\n"
    
    private var requestHandler: HTTPRequestEvent
    
    init(handler: @escaping HTTPRequestEvent) {
        self.requestHandler = handler
    }

    private func completeResponse(_ context: ChannelHandlerContext, trailers: HTTPHeaders?, promise: EventLoopPromise<Void>?) {
        self.state.responseComplete()

        let promise = self.keepAlive ? promise : (promise ?? context.eventLoop.makePromise())
        if !self.keepAlive {
            promise!.futureResult.whenComplete { (_: Result<Void, Error>) in context.close(promise: nil) }
        }
        self.handler = nil

        context.writeAndFlush(self.wrapOutboundOut(.end(trailers)), promise: promise)
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let reqPart = self.unwrapInboundIn(data)
        switch reqPart {
        case .head(let request):
            self.infoSavedRequestHead = request
            self.infoSavedBodyBytes = 0
            self.state.requestReceived()
        case .body(var body):
            infoSavedBodyBytes += body.readableBytes
            bodyBuffer.writeBuffer(&body)
        case .end:
            self.state.requestComplete()
            let body = bodyBuffer.getData(at: 0, length: infoSavedBodyBytes)
            self.requestHandler(self.infoSavedRequestHead!, body, context)
            self.completeResponse(context, trailers: nil, promise: nil)
        }
    }

    func channelReadComplete(context: ChannelHandlerContext) {
        context.flush()
    }

    func handlerAdded(context: ChannelHandlerContext) {
        self.bodyBuffer = context.channel.allocator.buffer(capacity: 0)
    }
}

final class HTTPServer {
    public var threadPoolCount = 6

    public var backlog: Int32 = 256

    var requestHandler: HTTPRequestEvent

    init(handler: @escaping HTTPRequestEvent) {
        requestHandler = handler
    }

    func start(host: String = "127.0.0.1", port: Int = 3000) throws {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        let bootstrap = ServerBootstrap(group: group)
            // Specify backlog and enable SO_REUSEADDR for the server itself
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)

            // Set the handlers that are applied to the accepted Channels
            .childChannelInitializer { [unowned self] channel in
                channel.pipeline.configureHTTPServerPipeline(withErrorHandling: true).flatMap {
                    channel.pipeline.addHandler(HTTPHandler(handler: self.requestHandler))
                }
            }

            // Enable SO_REUSEADDR for the accepted Channels
            .childChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 1)
            .childChannelOption(ChannelOptions.allowRemoteHalfClosure, value: true)

        defer {
            try! group.syncShutdownGracefully()
        }

        let channel = try bootstrap.bind(host: host, port: port).wait()

        guard let localAddress = channel.localAddress else {
            fatalError("Address was unable to bind. Please check that the socket was not closed or that the address family was understood.")
        }
        
        print("Hexaville Builtin Server started at \(localAddress)")

        // This will never unblock as we don't close the ServerChannel
        try channel.closeFuture.wait()

        print("Server closed")
    }
}
