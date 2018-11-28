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
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart
    
    private var requestHandler: HTTPRequestEvent
    
    private var infoSavedRequestHead: HTTPRequestHead?
    
    private var bodyBuffer: ByteBuffer?
    
    private var infoSavedBodyBytes = 0
    
    init(handler: @escaping HTTPRequestEvent) {
        self.requestHandler = handler
    }
    
    func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        let reqPart = self.unwrapInboundIn(data)
        switch reqPart {
        case .head(let request):
            self.infoSavedRequestHead = request
            self.infoSavedBodyBytes = 0
        case .body(var body):
            if bodyBuffer == nil {
                bodyBuffer = body
            } else {
                bodyBuffer?.write(buffer: &body)
            }
            infoSavedBodyBytes += body.readableBytes
        case .end:
            let body: Data?
            if let bodyBuffer = bodyBuffer {
                 body = bodyBuffer.getData(at: 0, length: infoSavedBodyBytes)
            } else {
                body = nil
            }
        
            self.requestHandler(self.infoSavedRequestHead!, body, ctx)
        }
    }
    
    func channelReadComplete(ctx: ChannelHandlerContext) {
        ctx.flush()
    }
}

final class HTTPServer {
    public var threadPoolCount = 6
    
    public var backlog: Int32 = 256
    
    var requestHandler: HTTPRequestEvent
    
    init(handler: @escaping HTTPRequestEvent) {
        requestHandler = handler
    }
    
    func start(host: String = "0.0.0.0", port: Int = 3000) throws {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        let threadPool = BlockingIOThreadPool(numberOfThreads: threadPoolCount)
        threadPool.start()
        
        let bootstrap = ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.backlog, value: backlog)
            .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .childChannelInitializer { [unowned self] channel in
                channel.pipeline.configureHTTPServerPipeline(withErrorHandling: true).then { _ in
                    channel.pipeline.add(handler: HTTPHandler(handler: self.requestHandler))
                }
            }
            .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
            .childChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 1)
            .childChannelOption(ChannelOptions.allowRemoteHalfClosure, value: true)
        
        let server = bootstrap.bind(host: host, port: port)
        _ = try server.wait()
    }
}



